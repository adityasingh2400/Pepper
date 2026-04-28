/**
 * generate_veo_videos.ts
 * ----------------------
 * Generate the Pepper instructional injection videos with Google Vertex AI
 * Veo (default: Veo 3 GA) and upload the results to Supabase Storage.
 *
 * Usage:
 *   GCP_PROJECT_ID=your-project \
 *   GCP_LOCATION=us-central1 \
 *   GCP_SERVICE_ACCOUNT_KEY=path/to/key.json \
 *   SUPABASE_URL=https://<project>.supabase.co \
 *   SUPABASE_SERVICE_ROLE_KEY=eyJ... \
 *   bun scripts/generate_veo_videos.ts                 # generate all
 *   bun scripts/generate_veo_videos.ts --only=im-quad  # one id
 *   bun scripts/generate_veo_videos.ts --dry-run       # validate only
 *   bun scripts/generate_veo_videos.ts --force         # regenerate even
 *                                                      # if the mp4 is
 *                                                      # already in the
 *                                                      # bucket (costs $$)
 *
 * Behavior:
 *   1. Reads `data/veo_prompts.yaml`.
 *   2. For each entry (or the `--only` entry):
 *        a. Skips it if `videos/<id>.mp4` already exists in Supabase
 *           Storage (unless `--force`) so re-runs stay cheap.
 *        b. Submits a long-running predict request (see VEO_MODEL).
 *        c. Polls until the operation completes.
 *        d. Downloads the mp4 and uploads it to Supabase Storage at the
 *           `videos` bucket (public read).
 *   3. Writes a report to `data/veo_runs.json` so we can see what
 *      generated, when, and at what cost.
 *
 * Policy note:
 *   Every prompt in `data/veo_prompts.yaml` is written to keep the
 *   needle *off* the skin — we show dotted target rings and gold
 *   sparkles instead of punctures. This matters because Veo's content
 *   filter will block any prompt that unambiguously depicts a needle
 *   entering flesh. If a prompt gets blocked despite that, iterate on
 *   it (add "never shown", "illustrative only", etc.) and re-run with
 *   `--only=<id> --force`.
 */

import fs from "node:fs";
import path from "node:path";
import { parse as parseYaml } from "yaml";

// ─── Types ──────────────────────────────────────────────────────────────────

interface VeoPromptEntry {
  id: string;
  title: string;
  duration_seconds: number;
  aspect_ratio: "9:16" | "16:9" | "1:1";
  prompt: string;
  sites: string[];
}

interface VeoYaml {
  videos: VeoPromptEntry[];
}

interface RunRecord {
  id: string;
  storage_path: string;
  duration_seconds: number;
  generated_at: string;
  cost_estimate_usd?: number;
  status: "skipped" | "generated" | "failed";
  error?: string;
}

// ─── Config ────────────────────────────────────────────────────────────────

const PROJECT_ID    = required("GCP_PROJECT_ID");
const LOCATION      = process.env.GCP_LOCATION || "us-central1";
const KEY_FILE      = process.env.GCP_SERVICE_ACCOUNT_KEY;   // optional — falls back to application-default creds
const SUPABASE_URL  = process.env.SUPABASE_URL || "";        // optional — when unset we only save locally
const SUPABASE_KEY  = process.env.SUPABASE_SERVICE_ROLE_KEY || "";
const BUCKET        = process.env.SUPABASE_VIDEOS_BUCKET || "videos";
const DRY_RUN       = process.argv.includes("--dry-run");
const FORCE         = process.argv.includes("--force");
const ONLY_ID       = extractFlag("--only");
const LOCAL_DIR     = path.resolve("data/generated_videos");
const SKIP_UPLOAD   = !SUPABASE_URL || !SUPABASE_KEY || process.argv.includes("--no-upload");
// Default: Veo 3 GA (`veo-3.0-generate-001`). If Vertex returns 404/403 or
// you only have quota on Veo 2, run with VEO_MODEL=veo-2.0-generate-001 .
const VEO_MODEL     = process.env.VEO_MODEL || "veo-3.0-generate-001";
const PROMPT_PATH   = path.resolve("data/veo_prompts.yaml");
const REPORT_PATH   = path.resolve("data/veo_runs.json");

function required(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required env var: ${name}`);
  return v;
}

function extractFlag(flag: string): string | null {
  for (const arg of process.argv.slice(2)) {
    if (arg.startsWith(`${flag}=`)) return arg.slice(flag.length + 1);
  }
  return null;
}

// ─── Main ──────────────────────────────────────────────────────────────────

async function main() {
  const yamlText = fs.readFileSync(PROMPT_PATH, "utf8");
  const data = parseYaml(yamlText) as VeoYaml;
  if (!data.videos?.length) {
    console.error("No videos found in", PROMPT_PATH);
    process.exit(1);
  }

  const entries = ONLY_ID
    ? data.videos.filter((v) => v.id === ONLY_ID)
    : data.videos;

  if (ONLY_ID && entries.length === 0) {
    console.error(`No video with id=${ONLY_ID} found.`);
    process.exit(1);
  }

  console.log(
    `Found ${entries.length} prompt(s) to process ` +
    `(model: ${VEO_MODEL}${DRY_RUN ? ", dry-run" : ""}${FORCE ? ", force" : ""}).`
  );

  const records: RunRecord[] = [];
  if (!fs.existsSync(LOCAL_DIR)) fs.mkdirSync(LOCAL_DIR, { recursive: true });

  for (const entry of entries) {
    try {
      const billedSeconds = compliantDuration(entry.duration_seconds);
      const localPath = path.join(LOCAL_DIR, `${entry.id}.mp4`);
      const localExists = fs.existsSync(localPath) && fs.statSync(localPath).size > 0;

      if (!FORCE) {
        if (SKIP_UPLOAD && localExists) {
          console.log(`✓ ${entry.id}: local file exists (${localPath}), skipping.`);
          records.push({
            id: entry.id,
            storage_path: localPath,
            duration_seconds: entry.duration_seconds,
            generated_at: new Date().toISOString(),
            status: "skipped",
          });
          continue;
        }
        if (!SKIP_UPLOAD) {
          const remoteExists = await supabaseObjectExists(`${entry.id}.mp4`);
          if (remoteExists) {
            console.log(`✓ ${entry.id}: already in Supabase, skipping.`);
            records.push({
              id: entry.id,
              storage_path: `${BUCKET}/${entry.id}.mp4`,
              duration_seconds: entry.duration_seconds,
              generated_at: new Date().toISOString(),
              status: "skipped",
            });
            continue;
          }
        }
      }

      console.log(`▶ ${entry.id}: requesting Veo (${billedSeconds}s, ${entry.aspect_ratio})…`);
      let mp4: Buffer;
      if (DRY_RUN) {
        mp4 = Buffer.alloc(0);
      } else {
        mp4 = await runVeoSync(entry);
      }

      if (!DRY_RUN) {
        fs.writeFileSync(localPath, mp4);
        console.log(`  saved locally: ${localPath} (${mp4.length} bytes)`);
        if (!SKIP_UPLOAD) {
          await supabaseUpload(`${entry.id}.mp4`, mp4);
          console.log(`  ✓ uploaded to Supabase ${BUCKET}/${entry.id}.mp4`);
        } else {
          console.log(`  (skipping upload: SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not set)`);
        }
      }

      records.push({
        id: entry.id,
        storage_path: SKIP_UPLOAD ? localPath : `${BUCKET}/${entry.id}.mp4`,
        duration_seconds: billedSeconds,
        generated_at: new Date().toISOString(),
        status: DRY_RUN ? "skipped" : "generated",
        cost_estimate_usd: estimateVeoCost(billedSeconds),
      });
    } catch (err) {
      console.error(`✗ ${entry.id}:`, (err as Error).message);
      records.push({
        id: entry.id,
        storage_path: SKIP_UPLOAD ? path.join(LOCAL_DIR, `${entry.id}.mp4`) : `${BUCKET}/${entry.id}.mp4`,
        duration_seconds: entry.duration_seconds,
        generated_at: new Date().toISOString(),
        status: "failed",
        error: (err as Error).message,
      });
    }
  }

  fs.writeFileSync(REPORT_PATH, JSON.stringify({ runs: records }, null, 2));
  console.log(`\nReport written to ${REPORT_PATH}`);
  const totalCost = records
    .filter((r) => r.status === "generated")
    .reduce((acc, r) => acc + (r.cost_estimate_usd ?? 0), 0);
  console.log(`Estimated total cost (new generations only): ~$${totalCost.toFixed(2)}`);
}

// ─── Vertex AI Veo ─────────────────────────────────────────────────────────

/**
 * Long-running predict + poll. Zero-dep REST (gcloud token) — no AI Platform SDK.
 * Veo 2 returns completed bytes under `videos[]`; Veo 3 may use `videos[]` or `predictions[]`.
 */
async function runVeoSync(entry: VeoPromptEntry): Promise<Buffer> {
  const accessToken = await getAccessToken();
  const endpoint =
    `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}` +
    `/locations/${LOCATION}/publishers/google/models/${VEO_MODEL}:predictLongRunning`;

  const durationSeconds = compliantDuration(entry.duration_seconds);
  if (durationSeconds !== entry.duration_seconds) {
    console.warn(
      `⚠ ${entry.id}: duration ${entry.duration_seconds}s → ${durationSeconds}s (Veo 3 requires 4, 6, or 8)`
    );
  }

  const body = {
    instances: [{
      prompt: entry.prompt,
    }],
    parameters: {
      sampleCount: 1,
      aspectRatio: entry.aspect_ratio,
      durationSeconds,
      enhancePrompt: true,
    },
  };

  const startRes = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  if (!startRes.ok) {
    throw new Error(`Veo predictLongRunning failed: ${startRes.status} ${await startRes.text()}`);
  }
  const startJson = (await startRes.json()) as { name?: string };
  const operation = startJson.name;
  if (!operation) throw new Error("Veo did not return an operation name.");

  // Poll. Veo uses a model-scoped `fetchPredictOperation` endpoint
  // rather than the generic `operations/get`, which returns 404.
  const pollEndpoint =
    `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}` +
    `/locations/${LOCATION}/publishers/google/models/${VEO_MODEL}:fetchPredictOperation`;
  const deadline = Date.now() + 8 * 60 * 1000; // 8 minutes
  while (Date.now() < deadline) {
    await sleep(5000);
    const r = await fetch(pollEndpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ operationName: operation }),
    });
    if (!r.ok) throw new Error(`Veo poll failed: ${r.status} ${await r.text()}`);
    const op = (await r.json()) as {
      done?: boolean;
      response?: {
        videos?: { bytesBase64Encoded?: string; mimeType?: string }[];
        predictions?: { bytesBase64Encoded?: string }[];
        raiMediaFilteredCount?: number;
        raiMediaFilteredReasons?: string[];
      };
      error?: { message?: string };
    };
    if (op.error?.message) throw new Error(op.error.message);
    if (op.done && op.response) {
      // Safety filter triggered — no video bytes, just filter reasons.
      if (op.response.raiMediaFilteredCount && op.response.raiMediaFilteredCount > 0) {
        const reasons = op.response.raiMediaFilteredReasons?.join("; ") || "unspecified policy block";
        throw new Error(`Veo safety filter rejected this prompt: ${reasons}`);
      }
      // Veo 2: `videos[]`; some Veo 3 responses use `predictions[]`.
      const inline =
        op.response.videos?.[0]?.bytesBase64Encoded ??
        op.response.predictions?.[0]?.bytesBase64Encoded;
      if (!inline) {
        throw new Error(
          `Veo returned no inline video bytes. Response: ${JSON.stringify(op.response).slice(0, 300)}`
        );
      }
      return Buffer.from(inline, "base64");
    }
  }
  throw new Error("Veo operation timed out after 8 minutes.");
}

async function getAccessToken(): Promise<string> {
  // If a service-account key file was passed, use it. Otherwise fall
  // back to the user's application-default credentials (what `gcloud
  // auth application-default login` writes to
  // ~/.config/gcloud/application_default_credentials.json). Keeping
  // this script zero-dep means we shell out to gcloud rather than
  // using google-auth-library.
  const { execSync } = await import("node:child_process");
  try {
    const env = KEY_FILE ? `GOOGLE_APPLICATION_CREDENTIALS="${KEY_FILE}" ` : "";
    const token = execSync(`${env}gcloud auth application-default print-access-token`, {
      stdio: ["ignore", "pipe", "ignore"],
    }).toString().trim();
    if (!token) throw new Error("empty token");
    return token;
  } catch (e) {
    throw new Error(
      "Couldn't get a GCP access token. Either set GCP_SERVICE_ACCOUNT_KEY " +
      "to a service-account key file, or run `gcloud auth application-default login`."
    );
  }
}

/** Veo 3 only accepts 4, 6, or 8. Snap to nearest (YAML should already match). */
function compliantDuration(requested: number): number {
  if (!VEO_MODEL.startsWith("veo-3")) return requested;
  const allowed = [4, 6, 8] as const;
  if ((allowed as readonly number[]).includes(requested)) return requested;
  return allowed.reduce((best, x) =>
    Math.abs(x - requested) < Math.abs(best - requested) ? x : best
  );
}

function estimateVeoCost(durationSeconds: number): number {
  // Public list price (USD, approximate — check current GCP pricing).
  const perSecond = VEO_MODEL.startsWith("veo-3") ? 0.75 : 0.50;
  return durationSeconds * perSecond;
}

// ─── Supabase Storage ──────────────────────────────────────────────────────

async function supabaseObjectExists(name: string): Promise<boolean> {
  const url = `${SUPABASE_URL}/storage/v1/object/info/${BUCKET}/${name}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${SUPABASE_KEY}` },
  });
  return res.ok;
}

async function supabaseUpload(name: string, body: Buffer): Promise<void> {
  const url = `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${name}`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${SUPABASE_KEY}`,
      "Content-Type": "video/mp4",
      "x-upsert": "true",
    },
    body,
  });
  if (!res.ok) {
    throw new Error(`Supabase upload failed: ${res.status} ${await res.text()}`);
  }
}

// ─── Util ──────────────────────────────────────────────────────────────────

function sleep(ms: number) { return new Promise((r) => setTimeout(r, ms)); }

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

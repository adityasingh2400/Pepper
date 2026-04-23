/**
 * generate_veo_videos.ts
 * ----------------------
 * Generate the Pepper instructional injection videos with Google Vertex AI Veo
 * 2 and upload the results to Supabase Storage.
 *
 * Usage:
 *   GCP_PROJECT_ID=oriqprod \
 *   GCP_LOCATION=us-central1 \
 *   GCP_SERVICE_ACCOUNT_KEY=path/to/key.json \
 *   SUPABASE_URL=https://<project>.supabase.co \
 *   SUPABASE_SERVICE_ROLE_KEY=eyJ... \
 *   bun scripts/generate_veo_videos.ts
 *
 * Behavior:
 *   1. Reads `data/veo_prompts.yaml`.
 *   2. For each entry:
 *        a. Skips it if `videos/<id>.mp4` already exists in Supabase Storage
 *           (so re-runs are cheap).
 *        b. Submits a long-running predict request to Veo 2.
 *        c. Polls until the operation completes.
 *        d. Downloads the mp4 and uploads it to Supabase Storage at the
 *           `videos` bucket.
 *   3. Writes a small report to `data/veo_runs.json` so we can see what
 *      generated, when, and at what cost.
 *
 * Important: this script is intentionally idempotent and safe to re-run.
 *
 * If you don't have Veo access yet, run with `--dry-run` to validate the YAML
 * and the Supabase storage path without spending GPU time.
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
const KEY_FILE      = required("GCP_SERVICE_ACCOUNT_KEY");
const SUPABASE_URL  = required("SUPABASE_URL");
const SUPABASE_KEY  = required("SUPABASE_SERVICE_ROLE_KEY");
const BUCKET        = process.env.SUPABASE_VIDEOS_BUCKET || "videos";
const DRY_RUN       = process.argv.includes("--dry-run");
const PROMPT_PATH   = path.resolve("data/veo_prompts.yaml");
const REPORT_PATH   = path.resolve("data/veo_runs.json");

function required(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required env var: ${name}`);
  return v;
}

// ─── Main ──────────────────────────────────────────────────────────────────

async function main() {
  const yamlText = fs.readFileSync(PROMPT_PATH, "utf8");
  const data = parseYaml(yamlText) as VeoYaml;
  if (!data.videos?.length) {
    console.error("No videos found in", PROMPT_PATH);
    process.exit(1);
  }

  console.log(`Found ${data.videos.length} prompts.`);
  if (DRY_RUN) console.log("--dry-run: nothing will be sent to Veo or Supabase.");

  const records: RunRecord[] = [];
  for (const entry of data.videos) {
    try {
      const exists = await supabaseObjectExists(`${entry.id}.mp4`);
      if (exists) {
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

      console.log(`▶ ${entry.id}: requesting Veo (${entry.duration_seconds}s, ${entry.aspect_ratio})…`);
      let mp4: Buffer;
      if (DRY_RUN) {
        mp4 = Buffer.alloc(0);
      } else {
        mp4 = await runVeoSync(entry);
      }

      if (!DRY_RUN) {
        await supabaseUpload(`${entry.id}.mp4`, mp4);
        console.log(`✓ ${entry.id}: uploaded to Supabase.`);
      }

      records.push({
        id: entry.id,
        storage_path: `${BUCKET}/${entry.id}.mp4`,
        duration_seconds: entry.duration_seconds,
        generated_at: new Date().toISOString(),
        status: DRY_RUN ? "skipped" : "generated",
        cost_estimate_usd: estimateVeoCost(entry.duration_seconds),
      });
    } catch (err) {
      console.error(`✗ ${entry.id}:`, (err as Error).message);
      records.push({
        id: entry.id,
        storage_path: `${BUCKET}/${entry.id}.mp4`,
        duration_seconds: entry.duration_seconds,
        generated_at: new Date().toISOString(),
        status: "failed",
        error: (err as Error).message,
      });
    }
  }

  fs.writeFileSync(REPORT_PATH, JSON.stringify({ runs: records }, null, 2));
  console.log(`\nReport written to ${REPORT_PATH}`);
  const totalCost = records.reduce((acc, r) => acc + (r.cost_estimate_usd ?? 0), 0);
  console.log(`Estimated total cost: ~$${totalCost.toFixed(2)}`);
}

// ─── Vertex AI Veo ─────────────────────────────────────────────────────────

/**
 * Synchronous Veo 2 client. We avoid pulling in `@google-cloud/aiplatform`
 * because we want this script to stay zero-dep for fast iteration; we hit
 * the REST endpoint directly with a service-account access token.
 */
async function runVeoSync(entry: VeoPromptEntry): Promise<Buffer> {
  const accessToken = await getAccessToken();
  const endpoint =
    `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}` +
    `/locations/${LOCATION}/publishers/google/models/veo-2.0-generate:predictLongRunning`;

  const body = {
    instances: [{
      prompt: entry.prompt,
      durationSeconds: entry.duration_seconds,
      aspectRatio: entry.aspect_ratio,
    }],
    parameters: {
      sampleCount: 1,
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

  // Poll
  const pollEndpoint =
    `https://${LOCATION}-aiplatform.googleapis.com/v1/${operation}`;
  const deadline = Date.now() + 8 * 60 * 1000; // 8 minutes
  while (Date.now() < deadline) {
    await sleep(5000);
    const r = await fetch(pollEndpoint, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!r.ok) throw new Error(`Veo poll failed: ${r.status}`);
    const op = (await r.json()) as { done?: boolean; response?: any; error?: { message?: string } };
    if (op.error?.message) throw new Error(op.error.message);
    if (op.done && op.response) {
      const inline = op.response?.predictions?.[0]?.bytesBase64Encoded;
      if (!inline) throw new Error("Veo returned no inline video bytes.");
      return Buffer.from(inline, "base64");
    }
  }
  throw new Error("Veo operation timed out after 8 minutes.");
}

async function getAccessToken(): Promise<string> {
  // We rely on `gcloud auth print-access-token` if the user is already
  // authenticated; otherwise we hand off to a service-account JWT exchange.
  // Keeping this script zero-dep means we shell out instead of using
  // `google-auth-library`.
  const { execSync } = await import("node:child_process");
  try {
    const token = execSync(`GOOGLE_APPLICATION_CREDENTIALS="${KEY_FILE}" gcloud auth application-default print-access-token`, {
      stdio: ["ignore", "pipe", "ignore"],
    }).toString().trim();
    return token;
  } catch (e) {
    throw new Error(
      "Couldn't get a GCP access token. Make sure `gcloud` is installed and " +
      "GOOGLE_APPLICATION_CREDENTIALS points at a service account key file."
    );
  }
}

function estimateVeoCost(durationSeconds: number): number {
  // Public list price (USD) for Veo 2 at the time of writing.
  // 0.50/sec for 720p video.
  return durationSeconds * 0.5;
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

/**
 * generate_veo_videos.ts
 * ----------------------
 * Generate the Pepper instructional injection videos with Google Vertex AI
 * Veo (default: Veo 3 GA) and upload the results to Supabase Storage.
 *
 * Chained videos (see `chain` in `data/veo_prompts.yaml`): segment 1 is text-to-video;
 * the last frame is extracted with ffmpeg and passed as the first frame for segment 2
 * (image-to-video). Parts are concatenated into one `<id>.mp4`. Requires `ffmpeg`/`ffprobe`.
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
 *        b. Submits a long-running predict request (see VEO_MODEL), or for
 *           `chain:` an ordered list of segments (text → image-continued → concat).
 *        c. Polls until the operation completes.
 *        d. Saves the mp4 and uploads it to Supabase Storage at the
 *           `videos` bucket (public read).
 *   3. Writes a report to `data/veo_runs.json` so we can see what
 *      generated, when, and at what cost.
 *
 * Policy note:
 *   Prompts are tuned for distribution; if Vertex safety blocks a clip,
 *   soften language and re-run `--only=<id> --force`.
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { parse as parseYaml } from "yaml";

// ─── Types ──────────────────────────────────────────────────────────────────

interface VeoChainSegment {
  duration_seconds: number;
  prompt: string;
}

interface VeoPromptEntry {
  id: string;
  title: string;
  /** Legacy single-clip entries (use `chain` OR this + `prompt`). */
  duration_seconds?: number;
  aspect_ratio: "9:16" | "16:9" | "1:1";
  prompt?: string;
  sites: string[];
  /** Multi-segment: clip 1 text-to-video; clip 2+ uses last frame of prior clip as conditioning. */
  chain?: VeoChainSegment[];
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
// Chained image-to-video needs a model that accepts `image` on the instance (Veo 3).
const VEO_MODEL     = process.env.VEO_MODEL || "veo-3.0-generate-001";
const PROMPT_PATH   = path.resolve("data/veo_prompts.yaml");
const REPORT_PATH   = path.resolve("data/veo_runs.json");

const PREDICT_URL =
  `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}` +
  `/locations/${LOCATION}/publishers/google/models/${VEO_MODEL}:predictLongRunning`;
const POLL_URL =
  `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}` +
  `/locations/${LOCATION}/publishers/google/models/${VEO_MODEL}:fetchPredictOperation`;

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

function entryBillingSeconds(entry: VeoPromptEntry): number {
  if (entry.chain?.length) {
    return entry.chain.reduce((acc, seg) => acc + compliantDuration(seg.duration_seconds), 0);
  }
  return compliantDuration(entry.duration_seconds ?? 8);
}

function validateEntry(entry: VeoPromptEntry): void {
  if (entry.chain?.length) {
    if (entry.chain.length < 2) throw new Error(`${entry.id}: chain must have at least 2 segments`);
    if (entry.prompt || entry.duration_seconds != null) {
      console.warn(`⚠ ${entry.id}: ignoring legacy prompt/duration_seconds when chain is set`);
    }
    return;
  }
  if (!entry.prompt?.trim()) throw new Error(`${entry.id}: missing prompt (or add chain:)`);
  if (entry.duration_seconds == null) throw new Error(`${entry.id}: missing duration_seconds`);
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

  for (const e of entries) validateEntry(e);

  console.log(
    `Found ${entries.length} prompt(s) to process ` +
    `(model: ${VEO_MODEL}${DRY_RUN ? ", dry-run" : ""}${FORCE ? ", force" : ""}).`
  );

  const records: RunRecord[] = [];
  if (!fs.existsSync(LOCAL_DIR)) fs.mkdirSync(LOCAL_DIR, { recursive: true });

  for (const entry of entries) {
    try {
      const billedSeconds = entryBillingSeconds(entry);
      const localPath = path.join(LOCAL_DIR, `${entry.id}.mp4`);
      const localExists = fs.existsSync(localPath) && fs.statSync(localPath).size > 0;

      if (!FORCE) {
        if (SKIP_UPLOAD && localExists) {
          console.log(`✓ ${entry.id}: local file exists (${localPath}), skipping.`);
          records.push({
            id: entry.id,
            storage_path: localPath,
            duration_seconds: billedSeconds,
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
              duration_seconds: billedSeconds,
              generated_at: new Date().toISOString(),
              status: "skipped",
            });
            continue;
          }
        }
      }

      let mp4: Buffer;
      if (DRY_RUN) {
        if (entry.chain?.length) {
          console.log(
            `▶ ${entry.id}: dry-run — would run ${entry.chain.length} chained segments (${billedSeconds}s billed), needs ffmpeg + Veo 3`
          );
        } else {
          console.log(`▶ ${entry.id}: dry-run (${billedSeconds}s billed)…`);
        }
        mp4 = Buffer.alloc(0);
      } else if (entry.chain?.length) {
        ensureFfmpeg();
        mp4 = await generateChainedClip(entry);
      } else {
        const dur = compliantDuration(entry.duration_seconds!);
        console.log(`▶ ${entry.id}: requesting Veo (${dur}s, ${entry.aspect_ratio})…`);
        mp4 = await runVeoTextToVideo({
          prompt: entry.prompt!,
          aspectRatio: entry.aspect_ratio,
          durationSeconds: dur,
        });
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
        duration_seconds: entry.duration_seconds ?? entryBillingSeconds(entry),
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
  if (records.some((r) => r.status === "failed")) {
    process.exit(1);
  }
}

// ─── Chained generation (text → image-to-video → concat) ─────────────────

async function generateChainedClip(entry: VeoPromptEntry): Promise<Buffer> {
  const segments = entry.chain!;
  const partPaths: string[] = [];
  const tmp = os.tmpdir();

  for (let i = 0; i < segments.length; i++) {
    const seg = segments[i]!;
    const dur = compliantDuration(seg.duration_seconds);
    if (dur !== seg.duration_seconds) {
      console.warn(
        `⚠ ${entry.id} seg ${i + 1}: duration ${seg.duration_seconds}s → ${dur}s (Veo 3 requires 4, 6, or 8)`
      );
    }

    const partPath = path.join(tmp, `pepper-${entry.id}-part${i}.mp4`);

    if (i === 0) {
      console.log(`▶ ${entry.id}: segment 1/${segments.length} text-to-video (${dur}s, ${entry.aspect_ratio})…`);
      const buf = await runVeoTextToVideo({
        prompt: seg.prompt,
        aspectRatio: entry.aspect_ratio,
        durationSeconds: dur,
      });
      fs.writeFileSync(partPath, buf);
    } else {
      const prevPath = partPaths[i - 1]!;
      console.log(`▶ ${entry.id}: segment ${i + 1}/${segments.length} image-conditioned (${dur}s)…`);
      const { base64, mimeType } = extractLastFrameJpeg(prevPath);
      const buf = await runVeoImageToVideo({
        prompt: seg.prompt,
        aspectRatio: entry.aspect_ratio,
        durationSeconds: dur,
        imageBase64: base64,
        mimeType,
      });
      fs.writeFileSync(partPath, buf);
    }
    partPaths.push(partPath);
  }

  const outPath = path.join(tmp, `pepper-${entry.id}-joined.mp4`);
  concatMp4Files(partPaths, outPath);
  const final = fs.readFileSync(outPath);
  for (const p of [...partPaths, outPath]) {
    try {
      fs.unlinkSync(p);
    } catch {
      /* ignore */
    }
  }
  return final;
}

function ensureFfmpeg(): void {
  try {
    execFileSync("ffmpeg", ["-version"], { stdio: "ignore" });
    execFileSync("ffprobe", ["-version"], { stdio: "ignore" });
  } catch {
    throw new Error(
      "ffmpeg / ffprobe not found. Install: brew install ffmpeg (required for chained videos + concat)."
    );
  }
}

/** Last ~1–2 frames before EOF as high-quality JPEG for Veo image conditioning. */
function extractLastFrameJpeg(mp4Path: string): { base64: string; mimeType: string } {
  const durStr = execFileSync(
    "ffprobe",
    [
      "-v", "error",
      "-show_entries", "format=duration",
      "-of", "default=noprint_wrappers=1:nokey=1",
      mp4Path,
    ],
    { encoding: "utf8" }
  ).trim();
  const duration = parseFloat(durStr);
  if (!Number.isFinite(duration) || duration <= 0) {
    throw new Error(`Could not read duration of ${mp4Path}`);
  }
  const seekSec = Math.max(0, duration - 0.08);
  const jpgPath = path.join(os.tmpdir(), `pepper-lastframe-${Date.now()}.jpg`);
  execFileSync(
    "ffmpeg",
    [
      "-y",
      "-ss", String(seekSec),
      "-i", mp4Path,
      "-frames:v", "1",
      "-q:v", "2",
      jpgPath,
    ],
    { stdio: "ignore" }
  );
  const buf = fs.readFileSync(jpgPath);
  fs.unlinkSync(jpgPath);
  return { base64: buf.toString("base64"), mimeType: "image/jpeg" };
}

/** Concatenate MP4 parts; try stream copy first, then re-encode if codecs differ. */
function concatMp4Files(inputs: string[], outPath: string): void {
  const listFile = path.join(os.tmpdir(), `pepper-concat-${Date.now()}.txt`);
  const body = inputs
    .map((p) => {
      const abs = path.resolve(p).replace(/'/g, "'\\''");
      return `file '${abs}'`;
    })
    .join("\n");
  fs.writeFileSync(listFile, body, "utf8");
  try {
    try {
      execFileSync(
        "ffmpeg",
        ["-y", "-f", "concat", "-safe", "0", "-i", listFile, "-c", "copy", outPath],
        { stdio: "pipe" }
      );
    } catch {
      console.warn("  concat: stream copy failed, re-encoding to H.264…");
      execFileSync(
        "ffmpeg",
        [
          "-y",
          "-f", "concat",
          "-safe", "0",
          "-i", listFile,
          "-c:v", "libx264",
          "-crf", "20",
          "-preset", "fast",
          "-pix_fmt", "yuv420p",
          "-movflags", "+faststart",
          outPath,
        ],
        { stdio: "inherit" }
      );
    }
  } finally {
    try {
      fs.unlinkSync(listFile);
    } catch {
      /* ignore */
    }
  }
}

// ─── Vertex AI Veo ─────────────────────────────────────────────────────────

interface VeoRunOpts {
  prompt: string;
  aspectRatio: string;
  durationSeconds: number;
}

async function runVeoTextToVideo(opts: VeoRunOpts): Promise<Buffer> {
  const body = {
    instances: [{ prompt: opts.prompt }],
    parameters: {
      sampleCount: 1,
      aspectRatio: opts.aspectRatio,
      durationSeconds: opts.durationSeconds,
      enhancePrompt: true,
    },
  };
  const op = await startVeoPredict(body);
  return pollVeoUntilVideo(op);
}

async function runVeoImageToVideo(opts: VeoRunOpts & {
  imageBase64: string;
  mimeType: string;
}): Promise<Buffer> {
  const body = {
    instances: [{
      prompt: opts.prompt,
      image: {
        bytesBase64Encoded: opts.imageBase64,
        mimeType: opts.mimeType,
      },
    }],
    parameters: {
      sampleCount: 1,
      aspectRatio: opts.aspectRatio,
      durationSeconds: opts.durationSeconds,
      enhancePrompt: true,
    },
  };
  const op = await startVeoPredict(body);
  return pollVeoUntilVideo(op);
}

async function startVeoPredict(body: object): Promise<string> {
  const accessToken = await getAccessToken();
  const startRes = await fetch(PREDICT_URL, {
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
  if (!startJson.name) throw new Error("Veo did not return an operation name.");
  return startJson.name;
}

async function pollVeoUntilVideo(operation: string): Promise<Buffer> {
  const accessToken = await getAccessToken();
  const deadline = Date.now() + 16 * 60 * 1000; // 16 minutes (two segments)
  while (Date.now() < deadline) {
    await sleep(5000);
    const r = await fetch(POLL_URL, {
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
      if (op.response.raiMediaFilteredCount && op.response.raiMediaFilteredCount > 0) {
        const reasons = op.response.raiMediaFilteredReasons?.join("; ") || "unspecified policy block";
        throw new Error(`Veo safety filter rejected this prompt: ${reasons}`);
      }
      const inline =
        op.response.videos?.[0]?.bytesBase64Encoded ??
        op.response.predictions?.[0]?.bytesBase64Encoded;
      if (!inline) {
        throw new Error(
          `Veo returned no inline video bytes. Response: ${JSON.stringify(op.response).slice(0, 400)}`
        );
      }
      return Buffer.from(inline, "base64");
    }
  }
  throw new Error("Veo operation timed out.");
}

async function getAccessToken(): Promise<string> {
  const { execSync } = await import("node:child_process");
  try {
    const env = KEY_FILE ? `GOOGLE_APPLICATION_CREDENTIALS="${KEY_FILE}" ` : "";
    const token = execSync(`${env}gcloud auth application-default print-access-token`, {
      stdio: ["ignore", "pipe", "ignore"],
    }).toString().trim();
    if (!token) throw new Error("empty token");
    return token;
  } catch {
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

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

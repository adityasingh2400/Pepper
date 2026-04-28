# Pepper data + seed scripts

← Back to the main project: **[README.md](../README.md)**

One-shot scripts for populating the Pepper Supabase project.

## Prereqs

- [Bun](https://bun.sh) ≥ 1.1
- `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in your shell (NOT the anon key)
- The matching SQL migration applied (`supabase db push` or via dashboard)
- **ffmpeg** (for chained prompts such as `subq-abdomen`): `brew install ffmpeg`

## Scripts

### `seed_compound_metadata.ts`

Loads `data/compound_metadata.yaml` and upserts the 24-compound starter
catalog into `compounds` + `compound_pin_sites`.

```bash
bun scripts/seed_compound_metadata.ts             # dry run
bun scripts/seed_compound_metadata.ts --apply     # write
```

### `seed_citations.ts` (TODO)

Pulls peer-reviewed sources from PubMed for each compound + topic and writes
them to `citations`.

### `generate_veo_videos.ts`

Renders videos from `data/veo_prompts.yaml` using Vertex AI **Veo 3** and uploads to Supabase
Storage. Single-clip entries use text-to-video. **`chain:`** entries (e.g. `subq-abdomen`) run
multiple segments: first clip is text-to-video; the **last frame** is extracted with **ffmpeg** and passed to the next clip as image conditioning; parts are stitched into one `<slug>.mp4`. Idempotent — re-runs skip objects already present unless `--force`.

**One-time Supabase setup:** create a storage bucket named `videos` and mark
it **public** (Supabase dashboard → Storage → New bucket → Public bucket
toggle on). The iOS app pulls videos from the public URL —
`https://<project>.supabase.co/storage/v1/object/public/videos/<slug>.mp4`
— so the bucket *must* be public for playback to work without auth.

**Default model:** `veo-3.0-generate-001` ([Veo 3 on Vertex](https://cloud.google.com/vertex-ai/generative-ai/docs/models/veo/3-0-generate)).

**If Vertex errors (404/403/quota):** your project may not have Veo 3 yet — try
`VEO_MODEL=veo-2.0-generate-001`. **Image-conditioned continuation requires Veo 3** — chained abdomen clips will not work on pure Veo 2 unless you refactor to two separate text clips (continuity suffers).

Preview outputs locally: **`open data/generated_videos/<slug>.mp4`** (macOS) or any video player.

```bash
GCP_PROJECT_ID=your-project \
GCP_LOCATION=us-central1 \
GCP_SERVICE_ACCOUNT_KEY=path/to/key.json \
SUPABASE_URL=https://<project>.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=eyJ... \
bun scripts/generate_veo_videos.ts --dry-run           # validate prompts only
bun scripts/generate_veo_videos.ts                     # generate all missing
bun scripts/generate_veo_videos.ts --only=subq-abdomen # regenerate one prompt (chain = 2 Veo jobs)
bun scripts/generate_veo_videos.ts --only=im-quad --force  # force overwrite
```

Produces a per-run cost report in `data/veo_runs.json`.

**Cost budget** (approximate list pricing for Veo 3):

- Straight clips — proportional to clip length (~\$0.75/s).
- **`subq-abdomen`** chain — two 6 s generations ≈ **12 s** billed.

**Vertex safety:** realistic needle-on-skin shots may trip filters. If a segment fails, soften that segment’s wording in YAML or shorten the injection description. Stylized prompts (other sites) intentionally avoid stark puncture depiction.

### `seed_citations.ts` (TODO)

Pulls peer-reviewed sources from PubMed for each compound + topic and writes
them to `citations`.

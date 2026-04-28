# Pepper data + seed scripts

← Back to the main project: **[README.md](../README.md)**

One-shot scripts for populating the Pepper Supabase project.

## Prereqs

- [Bun](https://bun.sh) ≥ 1.1
- `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in your shell (NOT the anon key)
- The matching SQL migration applied (`supabase db push` or via dashboard)

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

Renders the instructional injection videos (defined in `data/veo_prompts.yaml`)
using Vertex AI **Veo 3** and uploads them to Supabase Storage. Idempotent —
re-runs skip videos that are already in the bucket.

**One-time Supabase setup:** create a storage bucket named `videos` and mark
it **public** (Supabase dashboard → Storage → New bucket → Public bucket
toggle on). The iOS app pulls videos from the public URL —
`https://<project>.supabase.co/storage/v1/object/public/videos/<slug>.mp4`
— so the bucket *must* be public for playback to work without auth.

**Veo 3 access:** Veo 3 is in preview and requires allowlisting on your GCP
project. Check at https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/veo-3-generate-preview
If you don't have access yet, fall back to Veo 2 by setting
`VEO_MODEL=veo-2.0-generate` in the env.

```bash
GCP_PROJECT_ID=your-project \
GCP_LOCATION=us-central1 \
GCP_SERVICE_ACCOUNT_KEY=path/to/key.json \
SUPABASE_URL=https://<project>.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=eyJ... \
bun scripts/generate_veo_videos.ts --dry-run           # validate prompts only
bun scripts/generate_veo_videos.ts                     # generate all missing
bun scripts/generate_veo_videos.ts --only=subq-abdomen # regenerate one prompt
bun scripts/generate_veo_videos.ts --only=im-quad --force  # force overwrite
```

Produces a per-run cost report in `data/veo_runs.json`.

**Cost budget** (Veo 3 @ $0.75/sec preview price):
- 8 prompts × ~6s average ≈ $36 per full run
- Partial re-runs via `--only=<id>` cost ~$4.50 per 6s clip

**Content-policy troubleshooting:** Veo blocks anything that looks like a
needle puncturing skin. The prompts already avoid this — they use dotted
target rings and gold sparkles for dose delivery instead. If a prompt
still gets blocked, edit `data/veo_prompts.yaml` to add more language
like "the needle is never shown touching skin, illustrative medical
diagram only" and re-run with `--only=<id> --force`.

### `seed_citations.ts` (TODO)

Pulls peer-reviewed sources from PubMed for each compound + topic and writes
them to `citations`.

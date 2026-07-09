# Known Issues

Status: `MVP Validated / Limited Production Handoff`

## YouTube Is Fragile

`cookies_path` can help `yt-dlp`, but YouTube downloads are not stable enough to be a hard dependency.

Known failure modes:

- browser cookie database is locked.
- exported cookies are stale or incomplete.
- Windows DPAPI decryption fails for browser cookies.
- YouTube returns sign-in, bot-check, throttling, or region restrictions.
- a downloaded file is incomplete or invalid even when yt-dlp exits successfully.

Use local reference videos for deterministic tests. If YouTube is required, run download and visual preflight before starting the full render.

## Reference Footage Rights Are High-Risk

YouTube/X/reference videos are treated as visual reference or temporary B-roll unless rights are explicit. For commercial release, replace high-risk reference clips with licensed or owned material.

## ASR Accuracy Is Limited

Audio-only jobs use ASR transcript text for subtitles, key segment detection, and visual search.

Known limitations:

- brand names and mixed Chinese/English terms can be wrong.
- punctuation and sentence breaks may be imperfect.
- timing is segment-level, not word-level forced alignment.
- production jobs should review or replace `text/asr_transcript.json`.

Use `transcript_path` when a corrected transcript already exists.

## Subtitle Rendering Is Basic

The MVP burns subtitles through FFmpeg/libass. It enforces one-line cues and short text, but advanced typography, animation, safe-area variants, and platform-specific styles should be handled by a dedicated subtitle overlay renderer later.

## Visual Matching Is Heuristic

The MVP maps semantic segments to practical visual queries. It can find broadly relevant B-roll, but it cannot guarantee perfect sentence-level semantic matching for every segment.

## Reference Clip Shuffle Is Structural

Reference-video cuts are deterministically shuffled before selection. This avoids rebuilding the source video in original order, but it does not guarantee a perfect narrative arc.

## Asset Platform Limits

Pexels/Pixabay/free-resource can fail because of:

- API key limits.
- rate limiting.
- no relevant result for a query.
- provider download errors.
- network instability.

When `required_for_key_segments` is true, these failures should stop the job with structured failure output.

## Placeholder Output Must Not Pass Production

The runner can fall back to placeholders in non-production scenarios. Production handoff requires `placeholder_count = 0`.

## Long Context Can Drop Details

The workflow has many moving parts: ASR, TTS, yt-dlp, FFmpeg, free-resource, subtitles, manifests, QA, and licensing. Keep state in job files and reports instead of chat memory.

## Multiple Aspect Ratios Are Not Fully Batched

The schema accepts multiple aspect ratios, but the current runner works one aspect ratio per run. Run separate jobs for `16:9` and `9:16` until batching is added.

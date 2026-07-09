# Workflow

This is the `v0.3.0` end-to-end workflow for generating a complete narrated B-roll video from a document/script or narration audio.

## 1. Input

Accept exactly one primary input:

- `document_path`: `.txt`, `.md`, `.docx`, or `.pdf`.
- `script_text`: inline confirmed script.
- `audio_path`: uploaded narration audio.

Rules:

- Do not rewrite, summarize, translate, or polish document/script text.
- Store source text and hash it.
- Split text only for processing and subtitles.
- For audio input, derive text from ASR and mark it as ASR-derived.

## 2. Audio-Only ASR

When `audio_path` is provided:

- Run ASR through `asr_config.provider`.
- Supported providers are `faster-whisper`, `command`, and test-only `mock`.
- Prefer `command` when using a known local ASR tool such as whisper.cpp.
- Write `text/asr_transcript.json`.
- Convert ASR segments into text segments.
- Cut the original uploaded audio into segment WAV files.
- Use `source_mode=audio-asr` in manifests.

Command ASR request shape:

```json
{
  "audio_path": "input.wav",
  "language": "zh"
}
```

Expected ASR output shape:

```json
{
  "provider": "command",
  "text": "full transcript",
  "segments": [
    {
      "start_seconds": 0.0,
      "end_seconds": 3.2,
      "text": "segment transcript"
    }
  ]
}
```

If a corrected transcript exists, provide `transcript_path` and skip live ASR.

## 3. Text-To-Speech

For document/script jobs:

- Default provider is `local-sapi` on Windows.
- `command` TTS can replace local SAPI.
- The input text must remain exact.
- The provider must write WAV audio.
- The runner writes one segment WAV plus `audio/narration.wav`.
- Audio metadata is stored in `audio/audio_manifest.json`.

TTS replacement boundary:

- Text in, WAV out.
- No text mutation.
- No schema mutation.
- Preserve segment hashes.

## 4. Semantic Timeline

The runner creates:

- `text/segments.json`
- `audio/audio_manifest.json`
- `timeline/timeline.json`

Each segment contains:

- `segment_id`
- exact or ASR-derived text
- text hash
- audio duration
- start/end time
- visual query
- key-segment flag

## 5. Key Segment Detection

Key segments can come from:

- `source_policy.key_segment_keywords`
- `source_policy.key_segment_ids`
- `source_policy.auto_key_segment_count`

MVP automatic scoring favors:

- AI and agent concepts
- enterprise adoption
- workflow/process/productivity
- security, compliance, governance, permissions
- procurement, budget, cost, finance
- concrete product or platform claims

Key segments should prefer authorized stock assets when `free-resource` is configured.

## 6. Visual Query Generation

Each segment receives a practical visual query.

For Chinese source text, map abstract content into English stock-search concepts such as:

- `artificial intelligence technology office`
- `business team workflow office`
- `cloud computing data center servers`
- `cybersecurity compliance business meeting`
- `finance budget planning office`
- `software platform product demo`

The query is a search helper, not a promise that the visual perfectly matches the sentence.

## 7. Reference And Authorized Assets

Reference videos:

- Can be local files, YouTube URLs, or yt-dlp search results.
- Must be muted before use.
- Must be scene-cut into short clips.
- Must be shuffled before selection.
- Should be visually checked for blank, green, black, title-card, or static frames.
- Are high-risk unless the user owns or licenses them.

Authorized assets:

- Use `free-resource` for Pexels/Pixabay when configured.
- Prefer authorized assets for key segments.
- Store request, provider, and license manifests.

## 8. YouTube Preflight

Before rendering with YouTube material:

- Use `yt-dlp` with optional cookies only to obtain candidate material.
- Reject files that fail `ffprobe`.
- Extract frames with FFmpeg.
- Reject files with no real frame data or placeholder-like frames.
- Copy validated candidates into a local reference path.
- Start the full render only after validation passes.

This prevents wasting a render on a video with subtitles over a blank or green screen.

## 9. Cutting

Reference video processing:

- remove audio
- detect scene changes
- cut clips
- prefer 5-8 second clips
- allow natural flexibility when useful
- cap every clip at 15 seconds

Important settings:

- `scene.threshold`
- `scene.min_duration_seconds`
- `scene.preferred_max_duration_seconds`
- `scene.max_duration_seconds`

## 10. Selection And Stitching

For each timeline segment:

- choose a free-resource asset if the segment is key and an asset exists.
- otherwise choose a validated reference clip.
- choose reference clips from a deterministic shuffled pool.
- avoid source-order reconstruction.
- only use placeholders in non-production fallback.
- loop/crop/scale video to match segment duration and aspect ratio.

The selected plan is written to:

```text
timeline/asset_plan.json
```

## 11. Subtitles

Subtitles are generated as SRT:

- one visible line per cue.
- target 10-16 Chinese characters.
- hard cap 20 displayed Chinese characters.
- no two-line subtitle display.
- timing follows the narration timeline and cue text length.

Output:

```text
subtitles/final.srt
```

## 12. Export

Outputs:

- `render/final.mp4`: video + audio + soft subtitle track when supported.
- `render/final_burned.mp4`: burned subtitles when requested and FFmpeg subtitle rendering succeeds.
- `render/result.json`: runner summary.
- `render/verification.json`: verifier summary.
- `render/agent-response.json`: parent-agent response.

## 13. Verification

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File scripts\verify-script-broll-video.ps1 `
  -ProjectRoot "projects\<project_id>"
```

Recommended QA:

- Check final video has video and audio.
- Check `placeholder_count` is zero.
- Check subtitles are one-line and max 20 displayed Chinese characters.
- Check selected visuals are not blank, green, black, or still.
- Check key segments use authorized assets when configured.
- Review ASR transcript before publishing.
- Review reference-video licensing risk before commercial use.

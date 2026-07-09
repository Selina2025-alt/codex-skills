---
name: script-broll-video-maker
description: Build a complete narrated B-roll/mixed-footage video from an uploaded article, document, inline script, or narration audio. Use when the user needs exact-text TTS, ASR from audio-only input, semantic timeline splitting, key sentence detection, YouTube/reference-video cuts, free-resource/Pexels/Pixabay B-roll, one-line subtitles, FFmpeg rendering, structured manifests, and a workflow that can be migrated into another agent system or GitHub project.
---

# Script B-roll Video Maker

Version: `v0.3.0`

Status: `MVP Validated / Limited Production Handoff`

Use this skill to turn a confirmed article, document, script, or uploaded narration audio into a narrated mixed-footage video. The MVP has been validated on:

- text/document input with exact narration, local TTS, reference-video cuts, free-resource key assets, SRT, burned subtitles, and final MP4 export.
- audio-only input with ASR transcript generation, original-audio narration, semantic timeline splitting, reference-video cuts, free-resource key assets, SRT, burned subtitles, and final MP4 export.
- YouTube-cookie preflight where a reference video must be downloaded, probed, and visually validated before the render starts.

`v0.3.0` focuses on making the workflow portable: stable input/output schemas, clear provider boundaries, deterministic local tests, GitHub-safe packaging, and explicit risk notes for parent agents.

## Responsibilities

This skill is responsible for:

- Accepting one primary content input: `document_path`, `script_text`, or `audio_path`.
- Preserving document/script text exactly for narration; no rewriting, summarizing, translating, or polishing.
- Transcribing audio-only input through ASR and marking transcript text as ASR-derived.
- Generating narration audio with local Windows SAPI TTS or a replaceable command TTS provider.
- Splitting narration into semantic/timed segments.
- Detecting key segments from keywords, manual segment ids, or automatic scoring.
- Building visual search queries for each segment.
- Downloading or using reference videos for broad B-roll texture.
- Calling `free-resource`/Pexels/Pixabay for authorized key-segment footage when configured.
- Cutting reference videos into short clips, preferring 5-8 seconds and capping every clip at 15 seconds.
- Shuffling reference clips before selection so the output does not follow the source video's chronology.
- Creating one-line SRT subtitles with 10-16 Chinese characters as the target and 20 displayed characters as the hard limit.
- Rendering `final.mp4` and optional `final_burned.mp4`.
- Writing manifests, reports, logs, and structured success/failure responses for parent agents.

## Boundaries

This skill is not responsible for:

- Legal clearance for YouTube, X, or other third-party reference footage.
- Guaranteeing that downloaded reference footage is commercially safe.
- Solving YouTube login, cookie, bot-check, throttling, or account restrictions.
- Rewriting the user's article or making editorial changes.
- Guaranteeing perfect ASR accuracy without human transcript review.
- Building a full DAM/licensing platform.
- Providing advanced motion-graphics subtitle design; the MVP uses FFmpeg/libass burn-in and can hand off to a dedicated subtitle renderer later.
- Producing multiple aspect ratios in one batch run; run one aspect ratio per job until batching is added.

## Hard Rules

- Do not modify source text before TTS.
- For audio-only jobs, do not claim ASR text is the user's original script.
- Treat YouTube/X/reference footage as high-risk unless the user provides rights.
- Prefer authorized stock assets for key production claims.
- Validate YouTube downloads before rendering: the file must probe successfully, contain a video stream, extract frames, and not be blank/placeholder.
- Avoid placeholder/static visuals in final acceptance; `placeholder_count` must be zero for production handoff.
- Keep subtitles single-line; never render two subtitle lines at once.
- Return structured failure JSON whenever possible.

## Inputs And Outputs

Use [input_schema.json](input_schema.json) and [output_schema.json](output_schema.json) as the stable contract.

Required input is one of:

- `document_path`: `.txt`, `.md`, `.docx`, or `.pdf`.
- `script_text`: inline confirmed script.
- `audio_path`: uploaded narration audio; use ASR or provide `transcript_path`.

Important optional fields:

- `voice_config`: local or command TTS settings.
- `asr_config`: `faster-whisper`, `command`, or test-only `mock`.
- `source_policy.reference_video_paths`: deterministic local reference footage.
- `source_policy.reference_urls` / `reference_search_query`: YouTube/reference download inputs.
- `source_policy.free_resource_*`: configured `free-resource` path, command, config, or pre-downloaded root.
- `cookies_path`: optional exported Netscape cookies file for yt-dlp.
- `scene`: scene detection and clip-duration policy.
- `render.burn_subtitles`: whether to create `final_burned.mp4`.

Stable output artifacts:

- `render/final.mp4`
- `render/final_burned.mp4`
- `subtitles/final.srt`
- `audio/narration.wav`
- `text/segments.json`
- `text/asr_transcript.json` for audio-only jobs
- `timeline/timeline.json`
- `timeline/asset_plan.json`
- `render/result.json`
- `render/verification.json`
- `render/agent-response.json`

## Execution

From the skill root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run.ps1 `
  -RequestPath .\job_config.example.json `
  -Workspace "C:\path\to\workspace" `
  -ResponsePath "projects\demo\render\agent-response.json"
```

On hosts with PowerShell 7:

```bash
./run.sh ./job_config.example.json /path/to/workspace projects/demo/render/agent-response.json
```

For deterministic CI and GitHub tests, use local reference video paths and the bundled mock providers. Do not make YouTube cookies a required test dependency.

## Workflow

Read [workflow.md](workflow.md) when implementing or debugging the full pipeline:

`document/script -> exact TTS -> semantic timeline -> key segments -> visual queries -> reference/authorized assets -> cutting -> shuffling -> stitching -> subtitles -> export -> verification`

Audio-only path:

`audio -> ASR transcript -> original-audio segment cuts -> semantic timeline -> key segments -> visuals -> subtitles -> export -> verification`

## Acceptance Criteria

A job can be accepted when:

- Response `status` is `completed`.
- Final video exists and has video plus audio.
- Burned video exists when requested.
- SRT cues are single-line and max 20 displayed Chinese characters.
- `asset_plan.json` has a selected visual for every segment.
- `placeholder_count` is zero.
- Reference clips follow the 5-8 second preferred / 15 second hard-cap policy.
- Reference clip selection is shuffled rather than source-order.
- Free-resource/Pexels/Pixabay assets are used for configured key segments when available.
- YouTube/reference downloads have passed preflight before render.
- `verification.status` is `passed`.
- Risk notes are preserved for parent-agent review.

## Migration

Read [migration_guide.md](migration_guide.md) before moving this skill into another agent platform. Keep the schema contract, provider interfaces, executable entrypoints, output directory structure, and risk notes stable.

## Compliance

Read [compliance_policy.md](compliance_policy.md) before using third-party footage. For commercial publishing, replace high-risk reference clips with authorized footage or store explicit approval/licensing evidence.

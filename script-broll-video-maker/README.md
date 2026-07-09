# Script B-roll Video Maker

Version: `v0.3.0`

Turn an uploaded article, document, inline script, or narration audio into a complete B-roll/mixed-footage video with narration, visual cuts, subtitles, manifests, and verification output.

This package is designed to work as:

- a local Codex skill under `$CODEX_HOME/skills/script-broll-video-maker`;
- a GitHub repository that another agent can clone and execute;
- a sub-agent module inside a larger video-production system.

## Install As A Codex Skill

This repository is intended to be installed with `SKILL.md` at the repository root.

Expected installed layout:

```text
~/.codex/skills/script-broll-video-maker/
  SKILL.md
  agents/openai.yaml
  run.ps1
  scripts/
  tests/
```

Windows:

```powershell
git clone https://github.com/<owner>/<repo>.git "$env:USERPROFILE\.codex\skills\script-broll-video-maker"
```

macOS/Linux:

```bash
git clone https://github.com/<owner>/<repo>.git ~/.codex/skills/script-broll-video-maker
```

Then restart Codex or open a new Codex conversation. Invoke explicitly with:

```text
$script-broll-video-maker
```

The skill package does not include API keys, YouTube cookies, downloaded assets, or generated videos. Each user must configure those locally.

## What This Skill Does

- Reads `document_path`, `script_text`, or `audio_path`.
- Keeps document/script narration text exact.
- Uses ASR for audio-only jobs.
- Uses local TTS or command TTS for text jobs.
- Creates semantic/timed segments.
- Detects key segments automatically or from configured rules.
- Searches or accepts reference videos, including YouTube via `yt-dlp`.
- Calls `free-resource`/Pexels/Pixabay for key B-roll when configured.
- Cuts reference material into short clips, usually 5-8 seconds and never above 15 seconds.
- Shuffles reference clips before stitching.
- Creates one-line subtitles aligned to narration.
- Exports `final.mp4`, optional `final_burned.mp4`, and structured reports.

## What This Skill Does Not Do

- It does not rewrite the user's article.
- It does not guarantee ASR correctness without review.
- It does not guarantee rights to YouTube/reference footage.
- It does not solve YouTube cookies or bot checks.
- It does not replace legal/licensing review.
- It does not provide advanced animated subtitle design; that can be delegated to a subtitle renderer later.

## Repository Layout

```text
script-broll-video-maker/
  SKILL.md
  README.md
  input_schema.json
  output_schema.json
  job_config.example.json
  production_report.example.json
  asset_license_record.example.json
  workflow.md
  compliance_policy.md
  known_issues.md
  migration_guide.md
  run.ps1
  run.sh
  agents/
  references/
  scripts/
  tests/
```

Runtime outputs are written outside the skill code, usually under:

```text
projects/<project_id>/
  input/
  text/
  audio/
  subtitles/
  references/
  assets/
  timeline/
  render/
  logs/
```

## Requirements

Required:

- PowerShell 5.1+ on Windows, or PowerShell 7+ for cross-platform use.
- FFmpeg and FFprobe in `PATH`.

Recommended:

- `yt-dlp` for YouTube/reference URLs.
- `python` for helper scripts.
- `whisper.cpp` or another ASR command provider for audio-only jobs.
- `free-resource` with Pexels/Pixabay API keys for authorized stock footage.

Optional:

- exported Netscape `cookies.txt` for YouTube.
- `pdftotext` for PDF input.

Do not commit API keys, cookies, generated videos, or downloaded assets to GitHub.

## Quick Start: Document Or Script

Create `job.json`:

```json
{
  "project_id": "demo-document-video",
  "document_path": "samples/article.txt",
  "target_platforms": ["bilibili", "douyin"],
  "output_aspect_ratios": ["16:9"],
  "voice_config": {
    "provider": "local-sapi",
    "voice": ""
  },
  "source_policy": {
    "reference_video_paths": ["samples/reference.mp4"],
    "free_resource_skill_root": "C:\\path\\to\\free-resource",
    "free_resource_command": "C:\\path\\to\\free-resource",
    "free_resource_config_path": "C:\\path\\to\\free-resource\\config.json",
    "required_for_key_segments": false,
    "auto_key_segment_count": 4
  },
  "scene": {
    "threshold": 0.35,
    "min_duration_seconds": 5,
    "preferred_max_duration_seconds": 8,
    "max_duration_seconds": 15
  },
  "output_dir": "projects",
  "render": {
    "burn_subtitles": true
  }
}
```

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "C:\path\to\script-broll-video-maker\run.ps1" `
  -RequestPath "C:\path\to\workspace\job.json" `
  -Workspace "C:\path\to\workspace" `
  -ResponsePath "projects\demo-document-video\render\agent-response.json"
```

## Quick Start: Audio Only

Create `job-audio.json`:

```json
{
  "project_id": "demo-audio-video",
  "audio_path": "samples/narration.wav",
  "asr_config": {
    "provider": "command",
    "command": "C:\\path\\to\\script-broll-video-maker\\scripts\\asr-whisper-cpp.ps1",
    "language": "zh"
  },
  "source_policy": {
    "reference_video_paths": ["samples/reference.mp4"],
    "free_resource_command": "C:\\path\\to\\free-resource",
    "free_resource_config_path": "C:\\path\\to\\free-resource\\config.json",
    "auto_key_segment_count": 3
  },
  "output_aspect_ratios": ["16:9"],
  "output_dir": "projects",
  "render": {
    "burn_subtitles": true
  }
}
```

If you already have a corrected transcript, provide `transcript_path` and reuse it instead of live ASR.

## YouTube Reference Preflight

When using YouTube, first prove that the material is real and readable:

1. Use an exported cookies file only if needed.
2. Download to a simple ASCII temp path when Windows Unicode paths cause invalid MP4 writes.
3. Run `ffprobe` on the downloaded file.
4. Extract several frames with FFmpeg.
5. Reject the file if it has no video stream, cannot extract frames, is blank, green, black, a title card, or mostly static.
6. Only pass validated local reference video paths to the render job.

For deterministic tests, skip YouTube and use local reference videos.

## Outputs

Read `render/agent-response.json` first. Important fields:

- `status`
- `final_video_path`
- `final_burned_video_path`
- `srt_path`
- `audio_path`
- `asr_transcript_path`
- `timeline_path`
- `segments`
- `used_assets`
- `verification`
- `risk_notes`
- `logs`

## Validation

Run the bundled tests from the skill root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test_minimal_job.ps1 -Workspace "C:\path\to\workspace"
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test_audio_asr_job.ps1 -Workspace "C:\path\to\workspace"
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test_failure_response.ps1 -Workspace "C:\path\to\workspace"
```

Production acceptance should additionally check:

- `placeholder_count = 0`
- final video has video and audio
- subtitles are single-line and max 20 displayed Chinese characters
- reference clips are not selected in original source order
- key segments use authorized stock assets when configured
- license records exist for commercial use

## GitHub Use

Recommended GitHub flow:

1. Copy this entire folder into a repository.
2. Keep `.gitignore` in place.
3. Add a repository README pointing to this package README if this skill is not the repository root.
4. Store secrets in environment variables or local config files outside the repository.
5. Use local reference videos or generated test videos in CI.
6. Keep YouTube cookies optional and never commit them.
7. Version future changes in `VERSION` and `CHANGELOG.md`.

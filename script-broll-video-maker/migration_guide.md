# Migration Guide

Use this guide to move `script-broll-video-maker` into another agent platform, parent project, or GitHub repository.

## Stable Contract

Input contract:

- Follow `input_schema.json`.
- Accept one of `document_path`, `script_text`, or `audio_path`.
- Keep `voice_config`, `asr_config`, `source_policy`, `cookies_path`, `output_dir`, `scene`, and `render` stable.
- Preserve the B-roll duration policy: 5-8 seconds preferred, 15 seconds hard cap.
- Keep YouTube cookies optional.

Output contract:

- Follow `output_schema.json`.
- Return `status`, `phase`, and `error` on failure.
- Return final video paths, subtitle path, audio path, timeline path, segments, used assets, verification, risk notes, and logs.
- Preserve `used_assets[].source_type` values: `reference_video`, `free-resource`, `placeholder`, `manual`, `unknown`.

## Recommended Repository Structure

```text
script-broll-video-maker/
  SKILL.md
  README.md
  VERSION
  CHANGELOG.md
  .gitignore
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

Do not commit:

- `projects/`
- downloaded videos
- generated audio/video/subtitles
- API keys
- cookies files
- Python caches
- provider output folders

## Runtime Output Structure

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

## Environment Variables

Common optional variables:

- `FREE_RESOURCE_COMMAND`
- `FREE_RESOURCE_ROOT`
- `FREE_RESOURCE_SKILL_ROOT`
- `FREE_RESOURCE_CONFIG_PATH`
- `PEXELS_API_KEY`
- `PIXABAY_API_KEY`
- `YTDLP_COOKIES_PATH`
- `WHISPER_CPP_EXE`
- `WHISPER_CPP_MODEL`
- `WHISPER_CPP_THREADS`

Do not print API keys or cookie values in logs.

## External Tools

Required:

- PowerShell 5.1+ on Windows or PowerShell 7+ cross-platform.
- FFmpeg and FFprobe.

Required for default text jobs on Windows:

- Windows SAPI voices.

Optional:

- `yt-dlp` for YouTube/reference URLs.
- `python` for helper scripts.
- `faster-whisper` or a command ASR provider.
- `whisper.cpp` for local command ASR.
- `pdftotext` for PDF input.
- `free-resource` with Pexels/Pixabay config.
- Bun if the configured free-resource skill depends on Bun.

## Execution Command

PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "<skill_root>\run.ps1" `
  -RequestPath "<workspace>\job.json" `
  -Workspace "<workspace>" `
  -ResponsePath "projects\<project_id>\render\agent-response.json"
```

Bash with PowerShell 7:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass \
  -File "<skill_root>/run.ps1" \
  -RequestPath "<workspace>/job.json" \
  -Workspace "<workspace>" \
  -ResponsePath "projects/<project_id>/render/agent-response.json"
```

## Parent Agent Handoff

The parent agent should:

1. Write a job JSON that follows `input_schema.json`.
2. Put secrets in environment variables or local config, not the prompt.
3. Preflight YouTube material if YouTube is required.
4. Call `run.ps1` or `run.sh`.
5. Read `render/agent-response.json`.
6. If `status=completed`, collect final paths and reports.
7. If `status=failed`, display `phase`, `error`, and relevant log paths.
8. Apply commercial-release policy outside this MVP if reference footage is high-risk.

## Provider Replacement Boundaries

TTS provider:

- Input: exact segment text.
- Output: WAV file.
- Constraint: no text rewrite.

ASR provider:

- Input: uploaded audio path and optional language hint.
- Output: JSON with `text` and timed `segments`.
- Constraint: keep original audio as narration.

Asset provider:

- Input: visual query and segment metadata.
- Output: local media file plus license/source metadata.
- Constraint: do not hide licensing risk.

Subtitle renderer:

- Input: video, audio, timeline, SRT.
- Output: burned or overlaid subtitle video.
- Constraint: preserve one-line subtitle policy unless the parent project intentionally changes it.

Reference-video provider:

- Input: local file, URL, or search query.
- Output: validated local video file.
- Constraint: pass visual preflight before rendering.

## GitHub Migration Checklist

- Copy the skill directory into a repository.
- Keep `.gitignore`.
- Run skill validation.
- Run at least `tests/test_minimal_job.ps1`.
- Run `tests/test_audio_asr_job.ps1` if audio-only mode is part of the target system.
- Run `tests/test_failure_response.ps1`.
- Use local reference videos in CI.
- Configure `free-resource` through environment or untracked config.
- Keep cookies optional and untracked.
- Update `VERSION` and `CHANGELOG.md` for future changes.
- Keep schema changes backward-compatible when possible.

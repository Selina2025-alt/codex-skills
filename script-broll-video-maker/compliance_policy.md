# Compliance Policy

This policy applies to `script-broll-video-maker v0.3.0`.

## Source Content

- Process only text, documents, or audio the user owns or is allowed to process.
- Do not rewrite or expand source text unless the parent workflow adds a separate editing step.
- Keep source hashes and transcripts for audit.
- For audio-only input, label transcript text as ASR-derived.

## Narration

- Text jobs must generate narration from exact source segments.
- Audio-only jobs must use the uploaded audio as the narration source.
- External TTS providers must preserve the same text-in/audio-out contract.
- Store TTS/ASR provider, voice/model, language, hashes, and durations in manifests where available.

## Reference Videos

- Treat YouTube, X, and similar platform videos as high-risk reference footage unless explicit rights exist.
- Remove audio from reference videos by default.
- Do not assume downloaded reference footage is commercially safe.
- Do not use invalid, blank, green, black, static, or placeholder-like downloads.
- For commercial publishing, replace reference clips with authorized assets or store explicit approval.

## Pexels / Pixabay / free-resource

- Store provider, source URL, license label, download time, local path, and used clip range for each asset.
- Re-check provider terms before high-volume commercial publication.
- Keep asset records even when attribution is not required.
- Do not log API keys.

## Platform Fit

For Douyin, Kuaishou, Xiaohongshu, Bilibili, Video Account, YouTube, and X:

- avoid unlicensed recognizable footage.
- avoid visible third-party watermarks.
- avoid misleading visual claims.
- avoid subtitle text that changes the source meaning.
- keep a project-level report with asset risk notes.

## Risk Levels

- `low`: authorized stock asset with provider metadata.
- `medium`: user-provided or generated material requiring review.
- `high`: YouTube/X/reference video without explicit license.
- `unknown`: missing source metadata.

## Release Gate

Before commercial release:

- `placeholder_count` must be zero.
- subtitle checks must pass.
- final video must have video and audio.
- selected visuals should pass basic blank/static checks.
- every authorized asset should have a license/source record.
- high-risk reference clips must be replaced or explicitly approved.
- ASR transcript should be reviewed when audio-only input is used.

# Changelog

## v0.3.0 - Portable Skill Package

- Clarified responsibilities and non-responsibilities in `SKILL.md`.
- Documented the complete document/script/audio-to-video workflow.
- Added GitHub usage guidance and repository hygiene rules.
- Added YouTube preflight as a required gate before rendering with downloaded reference footage.
- Replaced machine-specific and mojibake path examples with portable placeholders.
- Documented provider replacement boundaries for TTS, ASR, assets, subtitles, and reference video.
- Preserved MVP policies: exact text narration, audio-only ASR, 5-8 second B-roll target, 15 second clip cap, shuffled reference clips, single-line subtitles, and zero-placeholder production handoff.

## v0.2.1 - Shuffled Short Reference Clips

- Preferred YouTube/reference videos for general B-roll texture.
- Preferred free-resource/Pexels/Pixabay for key segments.
- Added 5-8 second reference clip preference with 15 second hard cap.
- Shuffled reference clips before stitching to avoid source-order reconstruction.
- Added ASR command adapter support for audio-only jobs.

## v0.1.0 - MVP Validated

- Validated text/document to narration video loop.
- Added TTS, timeline, key segment detection, reference cuts, subtitles, render output, and verification files.

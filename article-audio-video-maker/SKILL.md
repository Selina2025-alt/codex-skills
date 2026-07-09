---
name: article-audio-video-maker
description: Build a complete 16:9 illustrated business explainer video from an uploaded article/document or a finished narration audio file. Use when Codex needs to segment article text into image scenes, preserve provided visual style rules and reference assets, transcribe or generate one continuous narration track, align sentence-level subtitles, place each segment image on the matching audio timeline, and render a finished video.
---

# Article Audio Video Maker

## Overview

Turn an article or a completed narration audio file into a finished 16:9 business explainer video. The skill orchestrates text segmentation, style-locked image planning, full-length narration handling, subtitle alignment, image-to-audio timeline placement, HyperFrames rendering, and QA reports.

For detailed schemas and validation rules, read `references/pipeline-contract.md` before implementing the pipeline or modifying code. Use `references/job-config-template.json` as the default portable job configuration.

The skill includes a replaceable default style pack at `assets/default-style/`. Use it when the job folder does not provide its own style rules or reference assets.

## Scope

This skill is responsible for:

- Reading one article/document, one narration audio file, or both from a job folder.
- Reading provided visual rules and reference asset descriptions before planning images.
- Splitting article text by length, natural paragraphs, semantic turns, and viewing rhythm.
- Creating one image scene per text segment.
- Keeping narration audio as one complete continuous track.
- Aligning segment images to the complete audio timeline.
- Producing sentence-level subtitles that match the audio.
- Rendering a 1920x1080, 16:9 video.
- Writing manifests, timelines, subtitle files, and QA reports.

This skill is not responsible for:

- Training, fine-tuning, or cloning a company voice model.
- Building a general video editor or multi-ratio publishing system.
- YouTube/B-roll/external footage search or mixed-footage editing.
- Changing the locked visual style unless the user explicitly updates the style rules.
- Packaging this workflow as a marketplace product unless separately requested.

## Inputs

Expect a portable job folder with some or all of these files:

- Article/document: `.txt`, `.md`, `.docx`, `.pdf`, or another readable document.
- Finished narration audio: `.wav`, `.mp3`, `.m4a`, `.aac`, or `.flac`.
- Style rules: usually `画风锁定与出图规则.md` or an equivalent style document.
- Reference assets folder: images that define character identity, layout, color, and composition.
- Optional `job_config.json`: use `references/job-config-template.json` as a starting point.

Never assume local absolute paths are portable. Resolve all paths relative to the job folder unless the user explicitly provides absolute paths.

## Default Style Pack

Use these bundled assets when the user provides only an article or audio file:

- `assets/default-style/画风锁定与出图规则.md`
- `assets/default-style/reference-assets/`

Treat `assets/default-style/` as the replaceable style-pack slot. To change brand style or character assets, replace the files inside this folder while keeping the same structure. If a job folder provides its own `画风锁定与出图规则.md` and `参考素材/`, prefer the job-specific files over the bundled defaults.

## Decision Tree

1. If audio is provided, use it as the single master narration track. Do not regenerate TTS unless the user asks.
2. If only article text is provided, generate one complete narration track from the article or cleaned narration script. Do not generate separate audio per image segment.
3. If both article and audio are provided, use the article as the source for segmentation and image planning, and use the audio as the master timing source.
4. If the article and audio disagree, transcribe the audio and write the mismatch in the report before choosing an alignment strategy.

## Workflow

1. Inspect the job folder and identify article, audio, style rules, reference assets, and prior outputs.
2. Resolve style assets: prefer job-folder rules/assets, otherwise use `assets/default-style/`.
3. Read the style rules and reference asset notes. Treat them as higher priority than generic design preferences.
4. Extract article text with encoding detection. Preserve an untouched original-text copy.
5. Segment the article into scene paragraphs. Segment count is not fixed; each segment maps to exactly one image.
6. Build image prompts and storyboard rows for each segment. Include visual meaning, layout, character choice, and emotion/action variant.
7. Prepare the master audio:
   - For uploaded audio, normalize/convert it only as needed for rendering.
   - For article-only jobs, synthesize one continuous narration track with a stable voice backend.
   - Do not create one audio file per article segment as the production audio.
8. Transcribe and align the master audio. Create sentence-level subtitle JSON/SRT and a narration timeline.
9. Map article segments to audio time ranges using transcript text matching first, sentence index ranges second, and proportional fallback only when alignment is weak.
10. Generate or load one 16:9 image per segment.
11. Render with the master audio, image timeline, and sentence subtitles.
12. Validate outputs and write a production report.

## Audio Rules

- The finished video uses exactly one continuous master narration track.
- Do not split production narration by article segment.
- If TTS is required, use a stable fixed voice profile, fixed reference voice or voice ID, and fixed seed when supported.
- Prefer a high-quality API voice with stable `voice_id` or a proven local voice-cloning backend for long-form consistency.
- Keep Windows SAPI or other low-quality local voices only as a fallback and mark fallback usage in the report.
- Normalize loudness and keep peaks below -1 dB when feasible.

## Subtitle Rules

- Subtitles are sentence-level or short phrase-level, not paragraph-level.
- Each spoken sentence or phrase must have a matching subtitle item.
- Show only one subtitle at a time.
- Keep every subtitle on one line; split long Chinese text into natural 10-18 character units, max 20 Chinese characters when possible.
- Do not let subtitles wrap, truncate, overlap, or cover the main image subject.

## Image Rules

- One article segment equals one image.
- Image duration is determined by that segment's matching audio time range.
- Follow the provided visual style document and reference assets strictly.
- Keep canvas 16:9 and render output at 1920x1080.
- Keep text inside image modules short and away from box edges; avoid arrow/text overlap.
- Use the reference characters only at the scale required by the style rules.

## Required Outputs

Create a new output folder for each run. Include:

- `分段原文.md`
- `storyboard.json` or `分镜表.md`
- `英文绘图提示词.md`
- `images/001.png ...`
- `audio/master_narration.wav` or the normalized source audio
- `data/narration_timeline.json`
- `subtitles/subtitles.srt`
- `subtitles/subtitles.json`
- `data/render_plan.json`
- `video/final_16x9.mp4`
- `production_report.md`

Use variant filenames when iterating, such as `final_16x9_v2.mp4`, but keep the same folder structure.

## QA Before Final Response

Verify and report:

- Video is 1920x1080 and 16:9.
- Video duration matches the master audio duration.
- There is one master narration track.
- Image count equals segment count.
- Every segment image has a non-overlapping audio time range.
- Every subtitle has start/end time and visible text.
- No subtitle wraps to two lines.
- No subtitle is missing or truncated.
- Image text is not clipped and arrows do not cover text.
- Style rules and character scale were followed.
- Any fallback, weak alignment, ASR uncertainty, or manual correction needed.

Return only the key output paths and QA status unless the user asks for implementation details.

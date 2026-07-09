# Pipeline Contract

## Portable Folder Contract

Use relative paths from the job folder wherever possible.

Recommended structure:

```text
job-folder/
├── article.txt | article.md | article.docx | article.pdf
├── narration.wav | narration.mp3          # optional
├── job_config.json                        # optional
├── 画风锁定与出图规则.md                  # optional override
├── 参考素材/                              # optional override
└── outputs/
```

If multiple articles or audio files exist, choose the newest clearly named source file only when the user asked for automatic batch mode. Otherwise ask or write a report warning.

## Style Asset Resolution

Use this priority order:

1. Job-folder `job_config.json` explicit `style_rules_path` and `reference_assets_dir`.
2. Job-folder `画风锁定与出图规则.md` and `参考素材/`.
3. Bundled default style pack:
   - `assets/default-style/画风锁定与出图规则.md`
   - `assets/default-style/reference-assets/`

The bundled default style pack is intentionally replaceable. To port the skill to a new brand, replace files inside `assets/default-style/` while preserving the directory layout. Do not edit the workflow just to change visual style.

## Processing Modes

### Article Only

1. Extract article text.
2. Segment article into scenes.
3. Generate one image per scene.
4. Generate one continuous narration audio from the article or narration script.
5. Transcribe/align the final audio.
6. Map images to the audio timeline.
7. Render video.

### Audio Only

1. Use uploaded audio as master narration.
2. Transcribe and correct transcript.
3. Segment the corrected transcript into scenes.
4. Generate one image per scene.
5. Map images to transcript/audio time ranges.
6. Render video.

### Article Plus Audio

1. Use article for scene segmentation and image planning.
2. Use uploaded audio as master narration.
3. Transcribe audio.
4. Align article segments to transcript spans.
5. Report mismatches between article and audio.
6. Render video from the audio timeline.

## Text Extraction

- Detect UTF-8, UTF-8 BOM, GBK/GB18030, and common Windows encodings before reading Chinese documents.
- Preserve `source_original.txt` or `source_original.md`.
- Do not rewrite the original segment text. Store corrected narration or ASR text separately.

## Segmentation

Segment by article length, natural paragraphing, semantic turns, and narrative rhythm. Do not force exactly 10 segments.

Suggested ranges:

- Short article: 3-6 scenes.
- Medium article: 6-12 scenes.
- Long article: 12-25 scenes.
- Very long article: increase as needed, prioritizing logic and watchability.

Each scene must include:

- `scene_id`
- `source_text`
- `core_meaning`
- `image_prompt_en`
- `character_role`
- `character_emotion_action`
- `audio_start`
- `audio_end`
- `image_path`

## Audio Alignment

The master audio is the source of truth for video timing.

Alignment priority:

1. ASR word/sentence timestamps.
2. Text matching between article segments and transcript sentences.
3. Sentence index ranges if article and transcript are nearly identical.
4. Duration-proportional fallback only when text matching is weak.

If fallback alignment is used, write it in `production_report.md`.

## Transcription And Correction

Recommended ASR choices:

- API/high quality: OpenAI transcription models such as `gpt-4o-transcribe` when available.
- Local fallback: `faster-whisper` large models.
- Word-level alignment: WhisperX when exact timing is required.

Correction pipeline:

1. Produce raw transcript with timestamps.
2. Apply domain glossary and proper-noun correction.
3. Use constrained proofreading: fix obvious ASR mistakes and punctuation only.
4. Keep corrected text aligned to the original audio; do not invent content.
5. Generate final SRT/JSON from corrected timed units.

## Subtitle Contract

`subtitles.json` items:

```json
{
  "id": 1,
  "start": 0.0,
  "end": 2.4,
  "text": "这里是一条完整字幕",
  "source_sentence_id": 1
}
```

Rules:

- One visible subtitle at a time.
- One line only.
- Prefer 10-18 Chinese characters.
- Maximum 20 Chinese characters when feasible.
- Split long sentences by punctuation or semantic phrase.
- Never drop spoken content.

## Render Plan Contract

`render_plan.json` should include:

```json
{
  "canvas": { "width": 1920, "height": 1080, "fps": 30 },
  "master_audio": "audio/master_narration.wav",
  "scenes": [
    {
      "scene_id": "001",
      "start": 0.0,
      "end": 12.5,
      "image": "images/001.png",
      "segment_text": "..."
    }
  ],
  "subtitles": "subtitles/subtitles.srt"
}
```

Scene boundaries must be contiguous or intentionally separated by short black/white transitions. Avoid gaps where no image is displayed.

## Visual Contract

- Use the project style rules as the top visual authority.
- Use reference images for color, layout, line weight, character scale, and visual vocabulary.
- Generate no image that changes the locked art style.
- Keep important text inside boxes with clear padding.
- Do not allow arrows, icons, character hands, or subtitles to cover image text.
- Avoid placing large characters in the center unless the style rules permit it.

## QA Contract

Before finishing, inspect:

- MP4 dimensions and duration with `ffprobe`.
- Audio duration vs video duration.
- Subtitle count vs transcript unit count.
- Subtitle overlap and wrapping risk.
- Scene count vs image count.
- Scene timing coverage.
- Representative extracted frames for style, text clipping, arrows, and subtitle placement.

Write `production_report.md` with:

- Inputs used.
- Mode: article-only, audio-only, or article-plus-audio.
- ASR/TTS backend used.
- Segment count and image count.
- Any weak alignment.
- Any TTS or ASR fallback.
- Remaining issues.

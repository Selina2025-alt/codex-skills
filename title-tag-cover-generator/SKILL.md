---
name: title-tag-cover-generator
description: "Two-stage channel material workflow for Chinese articles: generate platform-specific high-cognition titles and 5-8 optimized tags first, pause for human review, then after confirmed title generate cover prompt/image and final publishing package. Use when asked to turn an article into titles, tags, cover copy, Xiaohongshu/Douyin/Shipinhao/WeChat channel assets, or to follow a mandatory title-review-before-cover workflow."
---

# Title Tag Cover Generator

Use this skill to turn one article into a publishable Chinese channel material package. Always run it in two stages with human review between them.

## Required Flow

1. Stage 1: article -> title candidates + tag strategy + AI recommendations.
2. Stop at Review Gate 1. Do not generate a cover until the user confirms the title.
3. Stage 2: confirmed title -> cover prompt -> image provider or mock -> final package.
4. Stop at Review Gate 2 after cover generation for user inspection.

Never auto-publish, connect CRM, generate video, bypass title review, or put API keys in files or logs.

## Responsibility Boundary

This skill owns article analysis, platform titles, platform tags, cover prompt/image generation, and final package assembly. It does not own content publishing, CRM integration, database writes, video production, or final editorial approval.

## Inputs

For local test runs, expect:

- `input/article.txt`
- `input/title_reference.md`
- `input/tag_reference.md`
- optional `input/cover_references/`
- optional cover rules supplied by the user

For production runs, the article may come from another agent. Optional metadata: target platforms, brand or column name, reference cover image, and cover style rules.

## Stage 1

Run:

```bash
python scripts/run_stage1.py --article input/article.txt --title-reference input/title_reference.md --tag-reference input/tag_reference.md --out outputs/stage1
```

Then review and improve the generated files manually if needed using the reference documents:

- `article_analysis.md`
- `title_options.md`
- `selected_title_recommendation.md`
- `tag_strategy.md`
- `selected_tags_recommendation.md`
- `stage1_report.md`

Title requirements:

- Generate titles from the article; do not require a user-provided title.
- Use the title reference document as the strategy source.
- Provide candidates for Xiaohongshu, Douyin/Shipinhao, and WeChat article.
- Recommend one title per platform and briefly explain why.
- Prefer high-cognition formulas such as "not A but B", "from A to B", "the stronger A gets, the more important B becomes", and "the real risk is not A but B".

Tag requirements:

- Use the tag reference document as the strategy source.
- Keep total tags at 5-8 per platform.
- Xiaohongshu: search, long-tail terms, concrete scenarios.
- Douyin/Shipinhao: algorithm distribution, precise audience or circle terms.
- Sort by traffic precision, avoid duplicate tags and hollow broad terms.

At the end of Stage 1, ask the user to confirm:

- which title to use,
- which words should be highlighted on the cover,
- whether tags pass,
- whether title revisions are needed.

## Stage 2

Only start after the user confirms a title. Stage 2 is intentionally separate.

Inputs:

- confirmed title,
- optional subtitle,
- line breaks,
- green highlight words,
- cover reference image or rules,
- `config/image_api_config.example.json` copied to a real local config if needed.

Required outputs:

- `outputs/cover/confirmed_title.json`
- `outputs/cover/cover_prompt.md`
- `outputs/cover/cover_prompt.json`
- `outputs/cover/cover_image.png`
- `outputs/cover/cover_generation_report.md`
- `outputs/final/channel_content_package.json`
- `outputs/final/production_report.md`

Run:

```bash
python scripts/run_stage2.py --confirmed-title "<confirmed title>" --line-breaks "line 1|line 2|line 3" --highlight-words "word1,word2"
```

Cover rules:

- Generate a complete 3:4 cover image or mock placeholder.
- Include the confirmed title text on the cover.
- Highlight key words in green.
- Preserve reference-like spacing, margins, hierarchy, and bottom image area when a reference is provided.
- Leave top space for later tags and bottom space for logo.
- Do not add unrelated text or change the title meaning.

## Image API Rules

Use `mock` mode until a real provider is configured. Mock mode only validates the workflow and should not be treated as final visual quality. Read API keys only from the environment variable named by `api_key_env`. Never print or store the key.

## Final Package

`channel_content_package.json` must include article summary, core angle, platform title pools, selected titles, tags, cover metadata, publish copy, and remaining human review items.

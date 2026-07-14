# Responsibility Boundaries

## Owned by this skill

- Read a text article and reference rules.
- Generate article analysis, platform title candidates, recommended titles, tag strategy, and recommended tags.
- Stop after Stage 1 until a human confirms the title.
- Build cover prompt and image through mock or external API only after title confirmation.
- Assemble `channel_content_package.json` and `production_report.md`.

## Not owned by this skill

- Automatic publishing to any platform.
- CRM, private-domain, database, or workflow automation integrations.
- Video generation or caption generation.
- Legal, medical, financial, or compliance review.
- Final editorial approval.

## Human review gates

Review Gate 1:

- Confirm final title.
- Confirm cover highlight words and line breaks.
- Confirm tags.

Review Gate 2:

- Inspect generated cover.
- Confirm no text drift, no unwanted text in the photo, and no layout conflict with labels or logo.

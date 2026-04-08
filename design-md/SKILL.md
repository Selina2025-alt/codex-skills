---
name: design-md
description: Use when the user wants a page or interface to follow a known brand aesthetic, mentions DESIGN.md, asks for a specific visual vibe, or needs help choosing a template from the local awesome-design-md library before building UI.
---

# Design MD

## Overview

This skill wraps the local `awesome-design-md` library at `C:\Users\koubinyue\.codex\awesome-design-md\design-md`. Use it to choose a style, load the matching `DESIGN.md`, and keep the resulting UI consistent.

## Workflow

1. Identify the style request.
   - Exact brand or product: use that folder directly.
   - Abstract vibe or a Chinese-language request: translate it into concise English design terms, then run the search script.
2. Search when needed:
   - `powershell -ExecutionPolicy Bypass -File C:\Users\koubinyue\.codex\skills\design-md\scripts\find-design.ps1 -Query "<query>"`
3. Tell the user which template you picked and why.
4. Read the selected `DESIGN.md` before building anything.
5. Inspect `preview.html` or `preview-dark.html` only when layout cues or component tone matter.
6. If the user also wants actual UI code, pair this skill with [`frontend-design`](C:/Users/koubinyue/.codex/skills/frontend-design/SKILL.md).

## Selection Rules

- Prefer exact brand matches over loose vibe matches.
- If the search returns several strong candidates, present the best 2-3 with one-line tradeoffs instead of picking silently.
- Keep the chosen style coherent across typography, color, spacing, surface treatment, and motion.
- Recreate the design language, not the protected brand assets. Do not copy logos, trademarks, or proprietary illustrations.
- When the user only wants inspiration or selection help, stop after the shortlist instead of building UI.

## Paths

- Library root: `C:\Users\koubinyue\.codex\awesome-design-md\design-md`
- Selected file: `C:\Users\koubinyue\.codex\awesome-design-md\design-md\<slug>\DESIGN.md`
- Optional previews:
  - `C:\Users\koubinyue\.codex\awesome-design-md\design-md\<slug>\preview.html`
  - `C:\Users\koubinyue\.codex\awesome-design-md\design-md\<slug>\preview-dark.html`

## Examples

- "Claude-like sign-in page" -> use `claude`
- "Warm editorial marketing site" -> search `editorial warm serif`
- "Dark developer tool landing page" -> search `dark developer terminal`
- "Premium fintech launch page" -> search `fintech premium trust`

## Resources

- Search utility: `scripts/find-design.ps1`
- Library index and vibe shortcuts: `references/style-index.md`

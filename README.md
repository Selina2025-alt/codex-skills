# Codex Skills

This repository is synced from `C:\Users\koubinyue\.codex\skills` and publishes the skills currently installed in this Codex environment. The README structure is inspired by `claude-skills-library` and adapted for Codex usage.

## Repository Structure

```text
codex-skills/
|-- .system/
|   |-- imagegen/
|   |-- openai-docs/
|   |-- plugin-creator/
|   |-- skill-creator/
|   |-- skill-installer/
|-- docx/
|-- frontend-design/
|-- khazix-writer/
|-- pdf/
|-- pptx/
|-- pua/
|-- xlsx/
`-- README.md
```

## Skills Index

| Category | Skill | Repository Path | Direct Trigger | Other Trigger Modes | Typical Use Cases |
| --- | --- | --- | --- | --- | --- |
| system | [imagegen](./.system/imagegen) | `.system/imagegen` | `$imagegen` | auto-match | Generate or edit raster images when the task benefits from AI-created bitmap visuals such... |
| system | [openai-docs](./.system/openai-docs) | `.system/openai-docs` | `$openai-docs` | auto-match | Use when the user asks how to build with OpenAI products or APIs and needs up-to-date offi... |
| system | [plugin-creator](./.system/plugin-creator) | `.system/plugin-creator` | `$plugin-creator` | auto-match | Create and scaffold plugin directories for Codex with a required `.codex-plugin/plugin.jso... |
| system | [skill-creator](./.system/skill-creator) | `.system/skill-creator` | `$skill-creator` | auto-match | Guide for creating effective skills. This skill should be used when users want to create a... |
| system | [skill-installer](./.system/skill-installer) | `.system/skill-installer` | `$skill-installer` | auto-match | Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path. Us... |
| regular | [docx](./docx) | `docx` | `$docx` | auto-match | Use this skill whenever the user wants to create, read, edit, or manipulate Word documents... |
| regular | [frontend-design](./frontend-design) | `frontend-design` | `$frontend-design` | auto-match | Create distinctive, production-grade frontend interfaces with high design quality. Use thi... |
| regular | [khazix-writer](./khazix-writer) | `khazix-writer` | `$khazix-writer` | auto-match | 数字生命卡兹克（Khazix）的公众号长文写作skill。当用户需要撰写公众号文章、写稿子、续写文章、根据素材产出长文时使用。触发词包括但不限于：写文章、写稿子、帮我写、续写、扩写... |
| regular | [pdf](./pdf) | `pdf` | `$pdf` | auto-match | Use this skill whenever the user wants to do anything with PDF files. This includes readin... |
| regular | [pptx](./pptx) | `pptx` | `$pptx` | auto-match | Use this skill any time a .pptx file is involved in any way — as input, output, or both. T... |
| regular | [pua](./pua) | `pua` | `$pua` | auto-match / `/prompts:pua` | 让你的 AI 不敢摆烂。用大厂 PUA 话术穷尽一切方案。触发条件：(1) 任务失败 2+ 次或反复微调同一思路; (2) 即将说'我无法解决'、建议用户手动操作、未验证就归因环境... |
| regular | [xlsx](./xlsx) | `xlsx` | `$xlsx` | auto-match | Use this skill any time a spreadsheet file is the primary input or output. This means any... |

## Details

### System Skills

#### [imagegen](./.system/imagegen)

- Category: system
- Repository path: `.system/imagegen`
- Trigger modes: Direct: `$imagegen`; Auto-match: matches requests described in SKILL.md
- Description: Generate or edit raster images when the task benefits from AI-created bitmap visuals such as photos, illustrations, textures, sprites, mockups, or transparent-background cutouts. Use when Codex should create a brand-new image, transform an existing image, or derive visual variants from references, and the output should be a bitmap asset rather than repo-native code or vector. Do not use when the task is better handled by editing existing SVG/vector/code-native assets, extending an established icon or logo system, or building the visual directly in HTML/CSS/canvas.
- Key contents: `SKILL.md`, `LICENSE.txt`, `scripts/`, `references/`, `assets/`, `agents/`

#### [openai-docs](./.system/openai-docs)

- Category: system
- Repository path: `.system/openai-docs`
- Trigger modes: Direct: `$openai-docs`; Auto-match: matches requests described in SKILL.md
- Description: Use when the user asks how to build with OpenAI products or APIs and needs up-to-date official documentation with citations, help choosing the latest model for a use case, or explicit GPT-5.4 upgrade and prompt-upgrade guidance; prioritize OpenAI docs MCP tools, use bundled references only as helper context, and restrict any fallback browsing to official OpenAI domains.
- Key contents: `SKILL.md`, `LICENSE.txt`, `references/`, `assets/`, `agents/`

#### [plugin-creator](./.system/plugin-creator)

- Category: system
- Repository path: `.system/plugin-creator`
- Trigger modes: Direct: `$plugin-creator`; Auto-match: matches requests described in SKILL.md
- Description: Create and scaffold plugin directories for Codex with a required `.codex-plugin/plugin.json`, optional plugin folders/files, and baseline placeholders you can edit before publishing or testing. Use when Codex needs to create a new local plugin, add optional plugin structure, or generate or update repo-root `.agents/plugins/marketplace.json` entries for plugin ordering and availability metadata.
- Key contents: `SKILL.md`, `scripts/`, `references/`, `assets/`, `agents/`

#### [skill-creator](./.system/skill-creator)

- Category: system
- Repository path: `.system/skill-creator`
- Trigger modes: Direct: `$skill-creator`; Auto-match: matches requests described in SKILL.md
- Description: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Codex's capabilities with specialized knowledge, workflows, or tool integrations.
- Key contents: `SKILL.md`, `LICENSE.txt`, `scripts/`, `references/`, `assets/`, `agents/`

#### [skill-installer](./.system/skill-installer)

- Category: system
- Repository path: `.system/skill-installer`
- Trigger modes: Direct: `$skill-installer`; Auto-match: matches requests described in SKILL.md
- Description: Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path. Use when a user asks to list installable skills, install a curated skill, or install a skill from another repo (including private repos).
- Key contents: `SKILL.md`, `LICENSE.txt`, `scripts/`, `assets/`, `agents/`

### Regular Skills

#### [docx](./docx)

- Category: regular
- Repository path: `docx`
- Trigger modes: Direct: `$docx`; Auto-match: matches requests described in SKILL.md
- Description: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.
- Key contents: `SKILL.md`, `LICENSE.txt`, `scripts/`

#### [frontend-design](./frontend-design)

- Category: regular
- Repository path: `frontend-design`
- Trigger modes: Direct: `$frontend-design`; Auto-match: matches requests described in SKILL.md
- Description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, artifacts, posters, or applications (examples include websites, landing pages, dashboards, React components, HTML/CSS layouts, or when styling/beautifying any web UI). Generates creative, polished code and UI design that avoids generic AI aesthetics.
- Key contents: `SKILL.md`, `LICENSE.txt`

#### [khazix-writer](./khazix-writer)

- Category: regular
- Repository path: `khazix-writer`
- Trigger modes: Direct: `$khazix-writer`; Auto-match: matches requests described in SKILL.md
- Description: 数字生命卡兹克（Khazix）的公众号长文写作skill。当用户需要撰写公众号文章、写稿子、续写文章、根据素材产出长文时使用。触发词包括但不限于：写文章、写稿子、帮我写、续写、扩写、公众号文章、长文、出稿、按我的风格写。即使用户只是说"帮我把这个写成文章"或"用我的风格写一下"，只要上下文涉及内容创作和公众号输出，都应该触发。也适用于用户丢过来一个PDF、brief、新闻链接、语音转文字或任何素材说"帮我写篇文章"的场景。不要用于短内容（小红书帖子、推特、朋友圈）或纯标题摘要生成（那个用wechat-title skill）。
- Key contents: `SKILL.md`, `references/`

#### [pdf](./pdf)

- Category: regular
- Repository path: `pdf`
- Trigger modes: Direct: `$pdf`; Auto-match: matches requests described in SKILL.md
- Description: Use this skill whenever the user wants to do anything with PDF files. This includes reading or extracting text/tables from PDFs, combining or merging multiple PDFs into one, splitting PDFs apart, rotating pages, adding watermarks, creating new PDFs, filling PDF forms, encrypting/decrypting PDFs, extracting images, and OCR on scanned PDFs to make them searchable. If the user mentions a .pdf file or asks to produce one, use this skill.
- Key contents: `SKILL.md`, `LICENSE.txt`, `scripts/`

#### [pptx](./pptx)

- Category: regular
- Repository path: `pptx`
- Trigger modes: Direct: `$pptx`; Auto-match: matches requests described in SKILL.md
- Description: Use this skill any time a .pptx file is involved in any way — as input, output, or both. This includes: creating slide decks, pitch decks, or presentations; reading, parsing, or extracting text from any .pptx file (even if the extracted content will be used elsewhere, like in an email or summary); editing, modifying, or updating existing presentations; combining or splitting slide files; working with templates, layouts, speaker notes, or comments. Trigger whenever the user mentions \"deck,\" \"slides,\" \"presentation,\" or references a .pptx filename, regardless of what they plan to do with the content afterward. If a .pptx file needs to be opened, created, or touched, use this skill.
- Key contents: `SKILL.md`, `LICENSE.txt`, `scripts/`

#### [pua](./pua)

- Category: regular
- Repository path: `pua`
- Trigger modes: Direct: `$pua`; Auto-match: matches requests described in SKILL.md; Prompt: `/prompts:pua`
- Description: 让你的 AI 不敢摆烂。用大厂 PUA 话术穷尽一切方案。触发条件：(1) 任务失败 2+ 次或反复微调同一思路; (2) 即将说'我无法解决'、建议用户手动操作、未验证就归因环境; (3) 被动等待——不搜索、不读源码、只等指示; (4) 用户不满：'try harder'、'stop giving up'、'换个方法'、'为什么还不行'、'你再试试'、'你怎么又失败了'。适用于所有任务类型。首次失败或已知修复正在执行时不触发。
- Key contents: `SKILL.md`

#### [xlsx](./xlsx)

- Category: regular
- Repository path: `xlsx`
- Trigger modes: Direct: `$xlsx`; Auto-match: matches requests described in SKILL.md
- Description: Use this skill any time a spreadsheet file is the primary input or output. This means any task where the user wants to: open, read, edit, or fix an existing .xlsx, .xlsm, .csv, or .tsv file (e.g., adding columns, computing formulas, formatting, charting, cleaning messy data); create a new spreadsheet from scratch or from other data sources; or convert between tabular file formats. Trigger especially when the user references a spreadsheet file by name or path — even casually (like \"the xlsx in my downloads\") — and wants something done to it or produced from it. Also trigger for cleaning or restructuring messy tabular data files (malformed rows, misplaced headers, junk data) into proper spreadsheets. The deliverable must be a spreadsheet file. Do NOT trigger when the primary deliverable is a Word document, HTML report, standalone Python script, database pipeline, or Google Sheets API integration, even if tabular data is involved.
- Key contents: `SKILL.md`, `LICENSE.txt`, `scripts/`

## Stats

| Item | Count |
| --- | ---: |
| System skills | 5 |
| Regular skills | 7 |
| Skills with standalone prompt commands | 1 |
| Total | 12 |

---

*Last updated: 2026-04-08*

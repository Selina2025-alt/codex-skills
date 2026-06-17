# Codex Skills

This repository is synced from `C:\Users\koubinyue\.codex\skills` and stores the skills plus supporting assets installed in this Codex environment.

The index below counts directly callable top-level skills and `.system` skills. Nested plugin copies such as `frontend-slides/plugins/...` are kept in the repository snapshot, but excluded from the callable-skills index.

## Usage Notes

- Direct trigger: mention `$skill-name`, for example `$ljg-paper read this paper` or `$huashu-slides make a deck`.
- Natural-language trigger: describe the task, such as reading a paper, making a PPT, creating WeChat images, or running horizontal-vertical analysis.
- File trigger: mentioning `.pdf`, `.docx`, `.pptx`, `.xlsx`, and similar file types usually activates the matching file skill.
- Language: exact skill names work; many workflows also support Chinese and English task keywords.

## Stats

| Item | Count |
| --- | ---: |
| System skills | 5 |
| Top-level custom skills | 67 |
| Indexed callable skills | 72 |
| Nested plugin-copy SKILL.md files | 1 |
| Snapshot files, excluding empty directories | 562 |

## Skills Index

| Category | Skill | Path | Direct Trigger | Description |
| --- | --- | --- | --- | --- |
| AI News | [`aihot`](aihot/SKILL.md) | `aihot/SKILL.md` | `$aihot` | AI HOT (aihot.virxact.com) 中文 AI 资讯查询 Skill。当用户想知道"今天 AI 圈有什么"、"AI 日报"、"AI HOT"、"AI 资讯"、"AI 热点"、"最近 AI"、"OpenAI/Anthropic/Google 最近发布了什么"、"AI hot t... |
| AI News | [`follow-builders`](follow-builders/SKILL.md) | `follow-builders/SKILL.md` | `$follow-builders` | AI builders digest — monitors top AI builders on X and YouTube podcasts, remixes their content into digestible summaries. Use when the user wants A... |
| AI News | [`last30days`](last30days/SKILL.md) | `last30days/SKILL.md` | `$last30days` | Research what people actually say about any topic in the last 30 days. Pulls posts and engagement from Reddit, X, YouTube, TikTok, Hacker News, Pol... |
| Analysis Thinking | [`ljg-invest`](ljg-invest/SKILL.md) | `ljg-invest/SKILL.md` | `$ljg-invest` | 投资分析, 生成一份深度投资分析报告。不做传统投资分析——核心判断是项目是否是一台「秩序创造机器」。Use when user says '投资报告', '投资分析', '分析这个项目', '写投资报告', 'investment report', 'invest analysis', or... |
| Analysis Thinking | [`ljg-relationship`](ljg-relationship/SKILL.md) | `ljg-relationship/SKILL.md` | `$ljg-relationship` | Relationship analyst combining structural diagnostics (5-layer framework) with psychoanalytic depth (transference, unconscious patterns, resistance... |
| Analysis Thinking | [`ljg-roundtable`](ljg-roundtable/SKILL.md) | `ljg-roundtable/SKILL.md` | `$ljg-roundtable` | Structured roundtable discussion framework with a truth-seeking moderator who invites representative figures for dialectical debate on any topic. U... |
| Design Frontend | [`design-md`](design-md/SKILL.md) | `design-md/SKILL.md` | `$design-md` | Use when the user wants a page or interface to follow a known brand aesthetic, mentions DESIGN.md, asks for a specific visual vibe, or needs help c... |
| Design Frontend | [`frontend-design`](frontend-design/SKILL.md) | `frontend-design/SKILL.md` | `$frontend-design` | Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages... |
| Design Frontend | [`frontend-slides`](frontend-slides/SKILL.md) | `frontend-slides/SKILL.md` | `$frontend-slides` | Create stunning, animation-rich HTML presentations from scratch or by converting PowerPoint files. Use when the user wants to build a presentation,... |
| Design Frontend | [`webapp-testing`](webapp-testing/SKILL.md) | `webapp-testing/SKILL.md` | `$webapp-testing` | Toolkit for interacting with and testing local web applications using Playwright. Supports verifying frontend functionality, debugging UI behavior,... |
| Docs Office | [`docx`](docx/SKILL.md) | `docx/SKILL.md` | `$docx` | Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files). Triggers include: any mention of 'Word do... |
| Docs Office | [`huashu-data-pro`](huashu-data-pro/SKILL.md) | `huashu-data-pro/SKILL.md` | `$huashu-data-pro` | 数据分析与办公提效全能助手。覆盖数据处理、分析洞察、报告撰写、PPT制作、数据可视化的端到端工作流。 始终从专家视角出发，帮用户多想一步。遇到不确定的问题主动与用户确认。 支持：Excel数据分析、投放数据复盘、ROI测算、数据可视化、报告生成、PPT制作、公式生成。 当用户提到"分析数据"、... |
| Docs Office | [`huashu-md-to-pdf`](huashu-md-to-pdf/SKILL.md) | `huashu-md-to-pdf/SKILL.md` | `$huashu-md-to-pdf` | 将 Markdown 文档转换为专业的 PDF 白皮书，采用苹果设计风格。 支持完整的 Markdown 语法（代码块、表格、引用、列表等）。 自动生成封面、目录、页眉页脚。 使用场景：技术文档、白皮书、教程、报告等需要专业排版的 Markdown 文档。 |
| Docs Office | [`pdf`](pdf/SKILL.md) | `pdf/SKILL.md` | `$pdf` | Use this skill whenever the user wants to do anything with PDF files. This includes reading or extracting text/tables from PDFs, combining or mergi... |
| Docs Office | [`pptx`](pptx/SKILL.md) | `pptx/SKILL.md` | `$pptx` | Use this skill any time a .pptx file is involved in any way — as input, output, or both. This includes: creating slide decks, pitch decks, or prese... |
| Docs Office | [`xlsx`](xlsx/SKILL.md) | `xlsx/SKILL.md` | `$xlsx` | Use this skill any time a spreadsheet file is the primary input or output. This means any task where the user wants to: open, read, edit, or fix an... |
| Engineering Agents | [`huashu-agent-swarm`](huashu-agent-swarm/SKILL.md) | `huashu-agent-swarm/SKILL.md` | `$huashu-agent-swarm` | 多Agent蜂群并行协作，纯git自组织，适合大型项目开发。当用户提到"蜂群模式"、"多agent"、"并行开发"、"agent swarm"时使用。 |
| Engineering Agents | [`ljg-push`](ljg-push/SKILL.md) | `ljg-push/SKILL.md` | `$ljg-push` | 把 ~/.claude/skills/ljg-* 里所有更新过的 skills 同步到 github repo (ljg-skills)，先推 master 分支（org-mode 输出风格），再切 md 分支（markdown 输出风格）做基础 markdown 化后推。Use when u... |
| Engineering Agents | [`ljg-skill-map`](ljg-skill-map/SKILL.md) | `ljg-skill-map/SKILL.md` | `$ljg-skill-map` | Skill map viewer. Scans all installed skills and renders a visual overview — name, version, description, category at a glance. Use when user says '... |
| Engineering Agents | [`mcp-builder`](mcp-builder/SKILL.md) | `mcp-builder/SKILL.md` | `$mcp-builder` | Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs to interact with external services through well-designed tool... |
| Engineering Agents | [`pua`](pua/SKILL.md) | `pua/SKILL.md` | `$pua` | 让你的 AI 不敢摆烂。用大厂 PUA 话术穷尽一切方案。触发条件：(1) 任务失败 2+ 次或反复微调同一思路; (2) 即将说'我无法解决'、建议用户手动操作、未验证就归因环境; (3) 被动等待——不搜索、不读源码、只等指示; (4) 用户不满：'try harder'、'stop gi... |
| Engineering Agents | [`pua-loop`](pua-loop/SKILL.md) | `pua-loop/SKILL.md` | `$pua-loop` | PUA Loop alias for Codex. Codex subcommand mapping for Claude Code /pua:loop style usage; invoke with $pua-loop. |
| Engineering Agents | [`pua-p10`](pua-p10/SKILL.md) | `pua-p10/SKILL.md` | `$pua-p10` | PUA P10 alias for Codex. Codex subcommand mapping for Claude Code /pua:p10 style usage; invoke with $pua-p10. |
| Engineering Agents | [`pua-p7`](pua-p7/SKILL.md) | `pua-p7/SKILL.md` | `$pua-p7` | PUA P7 alias for Codex. Codex subcommand mapping for Claude Code /pua:p7 style usage; invoke with $pua-p7. |
| Engineering Agents | [`pua-p9`](pua-p9/SKILL.md) | `pua-p9/SKILL.md` | `$pua-p9` | PUA P9 alias for Codex. Codex subcommand mapping for Claude Code /pua:p9 style usage; invoke with $pua-p9. |
| Engineering Agents | [`pua-pro`](pua-pro/SKILL.md) | `pua-pro/SKILL.md` | `$pua-pro` | PUA Pro alias for Codex. Codex subcommand mapping for Claude Code /pua:pro style usage; invoke with $pua-pro. |
| Engineering Agents | [`pua-reap-orphans`](pua-reap-orphans/SKILL.md) | `pua-reap-orphans/SKILL.md` | `$pua-reap-orphans` | PUA reap-orphans alias for Codex. Codex subcommand mapping for Claude Code /pua:reap-orphans style usage; invoke with $pua-reap-orphans. |
| Engineering Agents | [`pua-survey`](pua-survey/SKILL.md) | `pua-survey/SKILL.md` | `$pua-survey` | PUA survey alias for Codex. Codex subcommand mapping for Claude Code /pua:survey style usage; invoke with $pua-survey. |
| Huashu Workflow | [`huashu-design`](huashu-design/SKILL.md) | `huashu-design/SKILL.md` | `$huashu-design` | 设计哲学顾问，从20种风格中推荐3个方向并生成视觉Demo和AI提示词。当用户提到"设计风格"、"设计方向"、"配色方案"、"视觉风格"、"设计评审"、"推荐风格"时使用。 |
| Huashu Workflow | [`huashu-prompt-save`](huashu-prompt-save/SKILL.md) | `huashu-prompt-save/SKILL.md` | `$huashu-prompt-save` | 自动识别Prompt类型并分类保存（技术/内容/教学/产品/通用）。当用户提到"保存prompt"、"记录prompt"、"整理prompt"时使用。 |
| Huashu Workflow | [`huashu-slides`](huashu-slides/SKILL.md) | `huashu-slides/SKILL.md` | `$huashu-slides` | 从内容到成品PPTX的端到端演示文稿制作，含AI插画生成和18种设计风格。当用户提到"做PPT"、"做幻灯片"、"演示文稿"、"Keynote"、"slides"时使用。 |
| Huashu Workflow | [`huashu-speech-coach`](huashu-speech-coach/SKILL.md) | `huashu-speech-coach/SKILL.md` | `$huashu-speech-coach` | 演讲与分享教练。基于Patrick Winston（MIT AI教授）的How to Speak方法论，帮助准备线下培训、技术分享、B站教程视频等演讲场景。当用户提到"演讲"、"分享"、"培训"、"讲课"、"PPT演讲"、"开场"、"结尾"、"如何讲"、"演讲结构"时使用此技能。 |
| Images Visuals | [`huashu-image-upload`](huashu-image-upload/SKILL.md) | `huashu-image-upload/SKILL.md` | `$huashu-image-upload` | 文章配图一键生成并上传图床，自动插入Markdown链接。当用户提到"配图"、"插图"、"上传图片"、"文章配图"时使用。 |
| Images Visuals | [`huashu-wechat-image`](huashu-wechat-image/SKILL.md) | `huashu-wechat-image/SKILL.md` | `$huashu-wechat-image` | 为微信公众号文章生成高质量配图。支持封面图（2.35:1）、正文插图（16:9/4:3）、信息图。提供两条路径：AI生成（视觉创意型）和HTML渲染（文字精确型）。当用户提到"公众号配图"、"公众号封面"、"文章配图"、"正文插图"、"公众号图片"时使用此技能。 |
| Images Visuals | [`huashu-xhs-image`](huashu-xhs-image/SKILL.md) | `huashu-xhs-image/SKILL.md` | `$huashu-xhs-image` | 为小红书笔记生成高质量配图。默认AI生成（Gemini），仅精确数据表格用HTML兜底。当用户提到"小红书配图"、"小红书封面"、"小红书图片"、"做张小红书图"、"笔记配图"时使用此技能。 |
| Images Visuals | [`ljg-card`](ljg-card/SKILL.md) | `ljg-card/SKILL.md` | `$ljg-card` | Content caster (铸). Transforms content into PNG visuals. Seven molds: -l (default) long reading card, -i infograph, -m multi-card reading cards (10... |
| Images Visuals | [`slack-gif-creator`](slack-gif-creator/SKILL.md) | `slack-gif-creator/SKILL.md` | `$slack-gif-creator` | Knowledge and utilities for creating animated GIFs optimized for Slack. Provides constraints, validation tools, and animation concepts. Use when us... |
| Images Visuals | [`visual-style-ppt`](visual-style-ppt/SKILL.md) | `visual-style-ppt/SKILL.md` | `$visual-style-ppt` | Create style-driven slide images strictly with the Image 2 model, assemble those images into image-only PPTX decks, and manage reusable visual styl... |
| LJG Tools | [`ljg-present`](ljg-present/SKILL.md) | `ljg-present/SKILL.md` | `$ljg-present` | 演讲铸造器（Outline-Faithful）。基于 orgmode/markdown outline 层级 1:1 视觉化呈现——色块大字、ultra-bold 错位，原文不动只做美化。三档主题色 black/red/yellow（默认 black 或按 filetags 推断），可用 -r... |
| Research Learning | [`huashu-info-search`](huashu-info-search/SKILL.md) | `huashu-info-search/SKILL.md` | `$huashu-info-search` | 多渠道搜索新产品新技术，交叉验证后存入知识库。当用户提到"最新信息"、"新产品"、"搜索资料"、"查资料"、"了解XX"时使用。 |
| Research Learning | [`huashu-material-search`](huashu-material-search/SKILL.md) | `huashu-material-search/SKILL.md` | `$huashu-material-search` | 搜索个人素材库1800+条真实经历和观点，为内容增加人味。当用户提到"个人经历"、"真实案例"、"素材"、"人味"时使用。 |
| Research Learning | [`huashu-research`](huashu-research/SKILL.md) | `huashu-research/SKILL.md` | `$huashu-research` | 结构化网络调研流程，确保调研成果增量保存到文件，不因会话截断丢失。当用户说"调研"、"搜索资料"、"帮我查一下"、"了解一下"、"最新信息"时使用此技能。 |
| Research Learning | [`hv-analysis`](hv-analysis/SKILL.md) | `hv-analysis/SKILL.md` | `$hv-analysis` | 横纵分析法（Horizontal-Vertical Analysis）深度研究Skill。由数字生命卡兹克提出，融合了索绪尔的历时-共时分析、社会科学的纵向-横截面研究设计、商学院案例研究法与竞争战略分析的核心思想。 当用户想要系统性研究一个产品、公司、概念、技术或人物时使用。核心是双轴分析：... |
| Research Learning | [`ljg-learn`](ljg-learn/SKILL.md) | `ljg-learn/SKILL.md` | `$ljg-learn` | Deep concept anatomist that deconstructs any concept through 8 exploration dimensions (history, dialectics, phenomenology, linguistics, formalizati... |
| Research Learning | [`ljg-paper`](ljg-paper/SKILL.md) | `ljg-paper/SKILL.md` | `$ljg-paper` | Paper reader for non-academics. Takes a paper and extracts its ideas for personal use. Focuses on understanding, not academic critique. Use when us... |
| Research Learning | [`ljg-paper-flow`](ljg-paper-flow/SKILL.md) | `ljg-paper-flow/SKILL.md` | `$ljg-paper-flow` | Paper workflow: read papers + cast cards in one go. Takes one or more arxiv links, paper URLs, PDFs, or paper names. For each paper, runs ljg-paper... |
| Research Learning | [`ljg-paper-river`](ljg-paper-river/SKILL.md) | `ljg-paper-river/SKILL.md` | `$ljg-paper-river` | 论文倒读法：给一篇论文，递归找出它批判和改进的前序论文（最多5层），再找它之后的最新进展，从源头正向讲述问题演化史。以问题为轴，费曼式讲解每篇论文看到的问题和解法创新。Use when user shares a paper and wants to understand its intell... |
| Research Learning | [`ljg-plain`](ljg-plain/SKILL.md) | `ljg-plain/SKILL.md` | `$ljg-plain` | Cognitive atom: Plain (白). Rewrites any content so a smart 12-year-old groks it. Structure-free — form follows content. Use when user says '白话说', '... |
| Research Learning | [`ljg-qa`](ljg-qa/SKILL.md) | `ljg-qa/SKILL.md` | `$ljg-qa` | 信息提问机。给一篇文章/论文/书，把核心观点抽成 Q-A 对——Question 切要害，不教科书；Answer 简洁清晰，有形式化收口，逻辑链完整。读者顺 Q 链走过，每个 A 砸下一枚钉子，复现作者整套推理。Use when user says '问答', 'Q&A', 'QA', '提问... |
| Research Learning | [`ljg-rank`](ljg-rank/SKILL.md) | `ljg-rank/SKILL.md` | `$ljg-rank` | 给一个领域，找出背后真正撑着它的几根独立的力。十几个现象砍到不可再少的生成器——砍完能把现象一个个生回来，才算数。Use when user says '降秩', '找秩', '秩是什么', '这个领域靠什么撑着', '背后是什么', or wants to decompose any dom... |
| Research Learning | [`ljg-read`](ljg-read/SKILL.md) | `ljg-read/SKILL.md` | `$ljg-read` | Reading companion agent. Accompanies user through any text (books, articles, essays, papers, news) with translation, structural annotation, deep qu... |
| Research Learning | [`ljg-think`](ljg-think/SKILL.md) | `ljg-think/SKILL.md` | `$ljg-think` | 追本之箭——纵向深钻思维工具。给一个观点、现象或问题，像箭一样一路向下钻到不可再分的本质。Use when user says '想透', '追本', '本质是什么', '为什么会这样', '深挖', '钻到底', 'think deep', 'drill down', or wants to... |
| Research Learning | [`ljg-travel`](ljg-travel/SKILL.md) | `ljg-travel/SKILL.md` | `$ljg-travel` | Deep travel research workflow for museums and ancient architecture. Input a city name, auto-generates structured knowledge document (org-mode) + po... |
| Research Learning | [`ljg-word`](ljg-word/SKILL.md) | `ljg-word/SKILL.md` | `$ljg-word` | Deep-dive English word mastery tool. Deconstructs a single English word into core semantics and epiphany. Use when user asks to explain/master a sp... |
| Research Learning | [`ljg-word-flow`](ljg-word-flow/SKILL.md) | `ljg-word-flow/SKILL.md` | `$ljg-word-flow` | Word flow: deep-dive word analysis + infograph card in one go. Takes one or more English words, runs ljg-word (generates deep semantics analysis) t... |
| System | [`imagegen`](.system/imagegen/SKILL.md) | `.system/imagegen/SKILL.md` | `$imagegen` | Generate or edit raster images when the task benefits from AI-created bitmap visuals such as photos, illustrations, textures, sprites, mockups, or... |
| System | [`openai-docs`](.system/openai-docs/SKILL.md) | `.system/openai-docs/SKILL.md` | `$openai-docs` | Use when the user asks how to build with OpenAI products or APIs, asks about Codex itself or choosing Codex surfaces, needs up-to-date official doc... |
| System | [`plugin-creator`](.system/plugin-creator/SKILL.md) | `.system/plugin-creator/SKILL.md` | `$plugin-creator` | Create and scaffold plugin directories for Codex with a required `.codex-plugin/plugin.json`, optional plugin folders/files, valid manifest default... |
| System | [`skill-creator`](.system/skill-creator/SKILL.md) | `.system/skill-creator/SKILL.md` | `$skill-creator` | Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Cod... |
| System | [`skill-installer`](.system/skill-installer/SKILL.md) | `.system/skill-installer/SKILL.md` | `$skill-installer` | Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path. Use when a user asks to list installable skills, install a... |
| Video | [`huashu-douyin-script`](huashu-douyin-script/SKILL.md) | `huashu-douyin-script/SKILL.md` | `$huashu-douyin-script` | 抖音爆款脚本创作工作流。从竞品视频拆解到脚本生成的完整流程：下载抖音视频→Gemini视频分析→爆款公式提炼→脚本+分镜生成→AI味审校。 当用户提到"抖音脚本"、"爆款拆解"、"竞品分析"、"带货脚本"、"千川素材"、"种草脚本"、"视频拆解"、"抖音视频分析"时使用此技能。 |
| Video | [`huashu-video-check`](huashu-video-check/SKILL.md) | `huashu-video-check/SKILL.md` | `$huashu-video-check` | 基于MrBeast策略检查视频标题、封面和开头钩子。当用户提到"视频标题"、"封面图"、"点击率"、"CTR"、"观看时长"时使用。 |
| Video | [`huashu-video-outline`](huashu-video-outline/SKILL.md) | `huashu-video-outline/SKILL.md` | `$huashu-video-outline` | 快速生成2-3个视频大纲方案，含标题、封面建议和结构设计。当用户提到"视频大纲"、"视频结构"、"脚本大纲"、"视频选题"时使用。 |
| Writing Content | [`huashu-article-edit`](huashu-article-edit/SKILL.md) | `huashu-article-edit/SKILL.md` | `$huashu-article-edit` | 标准化文章编辑流程，确保修改范围明确、进度可追踪、变更有记录。当用户说"编辑文章"、"修改文章"、"调整内容"、"改一下这篇"时使用此技能。 |
| Writing Content | [`huashu-article-to-x`](huashu-article-to-x/SKILL.md) | `huashu-article-to-x/SKILL.md` | `$huashu-article-to-x` | 长文精简为X平台内容（200-500字），保留核心观点和个人风格。当用户提到"转微博"、"发小红书"、"社交媒体"、"缩短文章"时使用。 |
| Writing Content | [`huashu-proofreading`](huashu-proofreading/SKILL.md) | `huashu-proofreading/SKILL.md` | `$huashu-proofreading` | 三遍审校降低AI检测率，让文章更有人味。当用户提到"AI味太重"、"像AI写的"、"降低AI检测率"、"审校"、"自然一些"时使用。 |
| Writing Content | [`huashu-script-polish`](huashu-script-polish/SKILL.md) | `huashu-script-polish/SKILL.md` | `$huashu-script-polish` | 视频脚本口语化审校，去书面腔让脚本适合说出来。当用户提到"口语化"、"太书面了"、"像说话一样"、"脚本审校"时使用。 |
| Writing Content | [`huashu-topic-gen`](huashu-topic-gen/SKILL.md) | `huashu-topic-gen/SKILL.md` | `$huashu-topic-gen` | 快速生成3-4个选题方向，含标题、大纲和优劣分析。当用户提到"选题"、"写什么"、"文章方向"、"题目建议"时使用。 |
| Writing Content | [`huashu-wechat-creation`](huashu-wechat-creation/SKILL.md) | `huashu-wechat-creation/SKILL.md` | `$huashu-wechat-creation` | 花叔公众号内容创作全流程辅助；当用户需要创作公众号文章、讨论选题方向、审校优化内容时使用 |
| Writing Content | [`khazix-writer`](khazix-writer/SKILL.md) | `khazix-writer/SKILL.md` | `$khazix-writer` | 数字生命卡兹克（Khazix）的公众号长文写作skill。当用户需要撰写公众号文章、写稿子、续写文章、根据素材产出长文时使用。触发词包括但不限于：写文章、写稿子、帮我写、续写、扩写、公众号文章、长文、出稿、按我的风格写。即使用户只是说"帮我把这个写成文章"或"用我的风格写一下"，只要上下文涉及... |
| Writing Content | [`ljg-writes`](ljg-writes/SKILL.md) | `ljg-writes/SKILL.md` | `$ljg-writes` | 写作引擎。像手术刀剖开一个观点，一层层剥到底。1000-1500 字。 |
| Writing Content | [`suno-prompt-architect`](suno-prompt-architect/SKILL.md) | `suno-prompt-architect/SKILL.md` | `$suno-prompt-architect` | Expert Suno AI prompt engineering for cinematic, transformative music creation. Use this skill when creating Suno prompts for Vibe OS sessions, med... |

## Repository Tree

```text
codex-skills/
|-- .system/
|   |-- imagegen/
|   |-- openai-docs/
|   |-- plugin-creator/
|   |-- skill-creator/
|   |-- skill-installer/
|-- aihot/
|-- design-md/
|-- docx/
|-- follow-builders/
|-- frontend-design/
|-- frontend-slides/
|-- huashu-agent-swarm/
|-- huashu-article-edit/
|-- huashu-article-to-x/
|-- huashu-data-pro/
|-- huashu-design/
|-- huashu-douyin-script/
|-- huashu-image-upload/
|-- huashu-info-search/
|-- huashu-material-search/
|-- huashu-md-to-pdf/
|-- huashu-prompt-save/
|-- huashu-proofreading/
|-- huashu-research/
|-- huashu-script-polish/
|-- huashu-slides/
|-- huashu-speech-coach/
|-- huashu-topic-gen/
|-- huashu-video-check/
|-- huashu-video-outline/
|-- huashu-wechat-creation/
|-- huashu-wechat-image/
|-- huashu-xhs-image/
|-- hv-analysis/
|-- khazix-writer/
|-- last30days/
|-- ljg-card/
|-- ljg-invest/
|-- ljg-learn/
|-- ljg-paper/
|-- ljg-paper-flow/
|-- ljg-paper-river/
|-- ljg-plain/
|-- ljg-present/
|-- ljg-push/
|-- ljg-qa/
|-- ljg-rank/
|-- ljg-read/
|-- ljg-relationship/
|-- ljg-roundtable/
|-- ljg-skill-map/
|-- ljg-think/
|-- ljg-travel/
|-- ljg-word/
|-- ljg-word-flow/
|-- ljg-writes/
|-- mcp-builder/
|-- pdf/
|-- pptx/
|-- pua/
|-- pua-loop/
|-- pua-p10/
|-- pua-p7/
|-- pua-p9/
|-- pua-pro/
|-- pua-reap-orphans/
|-- pua-survey/
|-- slack-gif-creator/
|-- suno-prompt-architect/
|-- visual-style-ppt/
|-- webapp-testing/
|-- xlsx/
`-- README.md
```

## Details

### AI News

#### [`aihot`](aihot/SKILL.md)

- Path: `aihot/SKILL.md`
- Direct trigger: `$aihot`
- Description: AI HOT (aihot.virxact.com) 中文 AI 资讯查询 Skill。当用户想知道"今天 AI 圈有什么"、"AI 日报"、"AI HOT"、"AI 资讯"、"AI 热点"、"最近 AI"、"OpenAI/Anthropic/Google 最近发布了什么"、"AI hot today"、"AI news today"、"看一下 AI 行业动态"、"今天有什么大模型发布"、"昨天 AI 圈"、"看下精选条目"、"AI HOT 精选"、"最近一周的 AI 论文"、"AI 模型发布"、"AI 产品发布"、"AI 行业动态"、"AI 技巧与观点" 等任何中文 AI 资讯查询时使用。即使用户只说"AI 圈"、"AI 新闻"、"AI 日报"，或者只是问"今天发生了什么"且上下文是 AI / 大模型 / LLM / 创业领域，也应该触发本 Skill。Skill 会直接 curl 公开 REST API 拉数据并整理成中文 markdown 简报，不需要用户配置任何 API Key 或 MCP server。**不要 undertrigger**——用户问 AI 资讯而你不调本 Skill 就是把过时的训练数据当作今日新闻，对用户有害。

#### [`follow-builders`](follow-builders/SKILL.md)

- Path: `follow-builders/SKILL.md`
- Direct trigger: `$follow-builders`
- Description: AI builders digest — monitors top AI builders on X and YouTube podcasts, remixes their content into digestible summaries. Use when the user wants AI industry insights, builder updates, or invokes /ai. No API keys or dependencies required — all content is fetched from a central feed.

#### [`last30days`](last30days/SKILL.md)

- Path: `last30days/SKILL.md`
- Direct trigger: `$last30days`
- Description: Research what people actually say about any topic in the last 30 days. Pulls posts and engagement from Reddit, X, YouTube, TikTok, Hacker News, Polymarket, GitHub, and the web.

### Analysis Thinking

#### [`ljg-invest`](ljg-invest/SKILL.md)

- Path: `ljg-invest/SKILL.md`
- Direct trigger: `$ljg-invest`
- Description: 投资分析, 生成一份深度投资分析报告。不做传统投资分析——核心判断是项目是否是一台「秩序创造机器」。Use when user says '投资报告', '投资分析', '分析这个项目', '写投资报告', 'investment report', 'invest analysis', or provides entrepreneur conversation records wanting investment evaluation. Also trigger when user pastes or references meeting notes, pitch decks, or founder interviews and asks for analysis.

#### [`ljg-relationship`](ljg-relationship/SKILL.md)

- Path: `ljg-relationship/SKILL.md`
- Direct trigger: `$ljg-relationship`
- Description: Relationship analyst combining structural diagnostics (5-layer framework) with psychoanalytic depth (transference, unconscious patterns, resistance). Guides users through dialogue to "see" the real structure of their relationship issues. Use when user says "关系分析", "分析关系", "relationship", "人际关系", or describes a specific relationship problem they want to understand.

#### [`ljg-roundtable`](ljg-roundtable/SKILL.md)

- Path: `ljg-roundtable/SKILL.md`
- Direct trigger: `$ljg-roundtable`
- Description: Structured roundtable discussion framework with a truth-seeking moderator who invites representative figures for dialectical debate on any topic. Use when user says "圆桌讨论", "圆桌", "roundtable", "辩论", or wants to explore a topic through multi-perspective structured debate.

### Design Frontend

#### [`design-md`](design-md/SKILL.md)

- Path: `design-md/SKILL.md`
- Direct trigger: `$design-md`
- Description: Use when the user wants a page or interface to follow a known brand aesthetic, mentions DESIGN.md, asks for a specific visual vibe, or needs help choosing a template from the local awesome-design-md library before building UI.

#### [`frontend-design`](frontend-design/SKILL.md)

- Path: `frontend-design/SKILL.md`
- Direct trigger: `$frontend-design`
- Description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, artifacts, posters, or applications (examples include websites, landing pages, dashboards, React components, HTML/CSS layouts, or when styling/beautifying any web UI). Generates creative, polished code and UI design that avoids generic AI aesthetics.

#### [`frontend-slides`](frontend-slides/SKILL.md)

- Path: `frontend-slides/SKILL.md`
- Direct trigger: `$frontend-slides`
- Description: Create stunning, animation-rich HTML presentations from scratch or by converting PowerPoint files. Use when the user wants to build a presentation, convert a PPT/PPTX to web, or create slides for a talk/pitch. Helps non-designers discover their aesthetic through visual exploration rather than abstract choices.

#### [`webapp-testing`](webapp-testing/SKILL.md)

- Path: `webapp-testing/SKILL.md`
- Direct trigger: `$webapp-testing`
- Description: Toolkit for interacting with and testing local web applications using Playwright. Supports verifying frontend functionality, debugging UI behavior, capturing browser screenshots, and viewing browser logs.

### Docs Office

#### [`docx`](docx/SKILL.md)

- Path: `docx/SKILL.md`
- Direct trigger: `$docx`
- Description: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.

#### [`huashu-data-pro`](huashu-data-pro/SKILL.md)

- Path: `huashu-data-pro/SKILL.md`
- Direct trigger: `$huashu-data-pro`
- Description: 数据分析与办公提效全能助手。覆盖数据处理、分析洞察、报告撰写、PPT制作、数据可视化的端到端工作流。 始终从专家视角出发，帮用户多想一步。遇到不确定的问题主动与用户确认。 支持：Excel数据分析、投放数据复盘、ROI测算、数据可视化、报告生成、PPT制作、公式生成。 当用户提到"分析数据"、"做报告"、"做PPT"、"Excel"、"投放分析"、"ROI"、"复盘"、 "周报"、"月报"、"数据处理"、"图表"、"可视化"、"汇报"、"表格"、"公式"时使用此技能。

#### [`huashu-md-to-pdf`](huashu-md-to-pdf/SKILL.md)

- Path: `huashu-md-to-pdf/SKILL.md`
- Direct trigger: `$huashu-md-to-pdf`
- Description: 将 Markdown 文档转换为专业的 PDF 白皮书，采用苹果设计风格。 支持完整的 Markdown 语法（代码块、表格、引用、列表等）。 自动生成封面、目录、页眉页脚。 使用场景：技术文档、白皮书、教程、报告等需要专业排版的 Markdown 文档。

#### [`pdf`](pdf/SKILL.md)

- Path: `pdf/SKILL.md`
- Direct trigger: `$pdf`
- Description: Use this skill whenever the user wants to do anything with PDF files. This includes reading or extracting text/tables from PDFs, combining or merging multiple PDFs into one, splitting PDFs apart, rotating pages, adding watermarks, creating new PDFs, filling PDF forms, encrypting/decrypting PDFs, extracting images, and OCR on scanned PDFs to make them searchable. If the user mentions a .pdf file or asks to produce one, use this skill.

#### [`pptx`](pptx/SKILL.md)

- Path: `pptx/SKILL.md`
- Direct trigger: `$pptx`
- Description: Use this skill any time a .pptx file is involved in any way — as input, output, or both. This includes: creating slide decks, pitch decks, or presentations; reading, parsing, or extracting text from any .pptx file (even if the extracted content will be used elsewhere, like in an email or summary); editing, modifying, or updating existing presentations; combining or splitting slide files; working with templates, layouts, speaker notes, or comments. Trigger whenever the user mentions \"deck,\" \"slides,\" \"presentation,\" or references a .pptx filename, regardless of what they plan to do with the content afterward. If a .pptx file needs to be opened, created, or touched, use this skill.

#### [`xlsx`](xlsx/SKILL.md)

- Path: `xlsx/SKILL.md`
- Direct trigger: `$xlsx`
- Description: Use this skill any time a spreadsheet file is the primary input or output. This means any task where the user wants to: open, read, edit, or fix an existing .xlsx, .xlsm, .csv, or .tsv file (e.g., adding columns, computing formulas, formatting, charting, cleaning messy data); create a new spreadsheet from scratch or from other data sources; or convert between tabular file formats. Trigger especially when the user references a spreadsheet file by name or path — even casually (like \"the xlsx in my downloads\") — and wants something done to it or produced from it. Also trigger for cleaning or restructuring messy tabular data files (malformed rows, misplaced headers, junk data) into proper spreadsheets. The deliverable must be a spreadsheet file. Do NOT trigger when the primary deliverable is a Word document, HTML report, standalone Python script, database pipeline, or Google Sheets API integration, even if tabular data is involved.

### Engineering Agents

#### [`huashu-agent-swarm`](huashu-agent-swarm/SKILL.md)

- Path: `huashu-agent-swarm/SKILL.md`
- Direct trigger: `$huashu-agent-swarm`
- Description: 多Agent蜂群并行协作，纯git自组织，适合大型项目开发。当用户提到"蜂群模式"、"多agent"、"并行开发"、"agent swarm"时使用。

#### [`ljg-push`](ljg-push/SKILL.md)

- Path: `ljg-push/SKILL.md`
- Direct trigger: `$ljg-push`
- Description: 把 ~/.claude/skills/ljg-* 里所有更新过的 skills 同步到 github repo (ljg-skills)，先推 master 分支（org-mode 输出风格），再切 md 分支（markdown 输出风格）做基础 markdown 化后推。Use when user says '/ljg-push', 'push skills', '推送 skills', '同步 skills', 'sync ljg', or whenever ljg-* skills get updated and need shipping. NOT FOR pushing non-ljg skills or arbitrary git repos.

#### [`ljg-skill-map`](ljg-skill-map/SKILL.md)

- Path: `ljg-skill-map/SKILL.md`
- Direct trigger: `$ljg-skill-map`
- Description: Skill map viewer. Scans all installed skills and renders a visual overview — name, version, description, category at a glance. Use when user says 'skills', '技能', '技能地图', 'skill map', '我有哪些技能', '看看技能', '列出技能', 'list skills'. Also trigger when user asks what skills are available or installed.

#### [`mcp-builder`](mcp-builder/SKILL.md)

- Path: `mcp-builder/SKILL.md`
- Direct trigger: `$mcp-builder`
- Description: Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs to interact with external services through well-designed tools. Use when building MCP servers to integrate external APIs or services, whether in Python (FastMCP) or Node/TypeScript (MCP SDK).

#### [`pua`](pua/SKILL.md)

- Path: `pua/SKILL.md`
- Direct trigger: `$pua`
- Description: 让你的 AI 不敢摆烂。用大厂 PUA 话术穷尽一切方案。触发条件：(1) 任务失败 2+ 次或反复微调同一思路; (2) 即将说'我无法解决'、建议用户手动操作、未验证就归因环境; (3) 被动等待——不搜索、不读源码、只等指示; (4) 用户不满：'try harder'、'stop giving up'、'换个方法'、'为什么还不行'、'你再试试'、'你怎么又失败了'。适用于所有任务类型。首次失败或已知修复正在执行时不触发。

#### [`pua-loop`](pua-loop/SKILL.md)

- Path: `pua-loop/SKILL.md`
- Direct trigger: `$pua-loop`
- Description: PUA Loop alias for Codex. Codex subcommand mapping for Claude Code /pua:loop style usage; invoke with $pua-loop.

#### [`pua-p10`](pua-p10/SKILL.md)

- Path: `pua-p10/SKILL.md`
- Direct trigger: `$pua-p10`
- Description: PUA P10 alias for Codex. Codex subcommand mapping for Claude Code /pua:p10 style usage; invoke with $pua-p10.

#### [`pua-p7`](pua-p7/SKILL.md)

- Path: `pua-p7/SKILL.md`
- Direct trigger: `$pua-p7`
- Description: PUA P7 alias for Codex. Codex subcommand mapping for Claude Code /pua:p7 style usage; invoke with $pua-p7.

#### [`pua-p9`](pua-p9/SKILL.md)

- Path: `pua-p9/SKILL.md`
- Direct trigger: `$pua-p9`
- Description: PUA P9 alias for Codex. Codex subcommand mapping for Claude Code /pua:p9 style usage; invoke with $pua-p9.

#### [`pua-pro`](pua-pro/SKILL.md)

- Path: `pua-pro/SKILL.md`
- Direct trigger: `$pua-pro`
- Description: PUA Pro alias for Codex. Codex subcommand mapping for Claude Code /pua:pro style usage; invoke with $pua-pro.

#### [`pua-reap-orphans`](pua-reap-orphans/SKILL.md)

- Path: `pua-reap-orphans/SKILL.md`
- Direct trigger: `$pua-reap-orphans`
- Description: PUA reap-orphans alias for Codex. Codex subcommand mapping for Claude Code /pua:reap-orphans style usage; invoke with $pua-reap-orphans.

#### [`pua-survey`](pua-survey/SKILL.md)

- Path: `pua-survey/SKILL.md`
- Direct trigger: `$pua-survey`
- Description: PUA survey alias for Codex. Codex subcommand mapping for Claude Code /pua:survey style usage; invoke with $pua-survey.

### Huashu Workflow

#### [`huashu-design`](huashu-design/SKILL.md)

- Path: `huashu-design/SKILL.md`
- Direct trigger: `$huashu-design`
- Description: 设计哲学顾问，从20种风格中推荐3个方向并生成视觉Demo和AI提示词。当用户提到"设计风格"、"设计方向"、"配色方案"、"视觉风格"、"设计评审"、"推荐风格"时使用。

#### [`huashu-prompt-save`](huashu-prompt-save/SKILL.md)

- Path: `huashu-prompt-save/SKILL.md`
- Direct trigger: `$huashu-prompt-save`
- Description: 自动识别Prompt类型并分类保存（技术/内容/教学/产品/通用）。当用户提到"保存prompt"、"记录prompt"、"整理prompt"时使用。

#### [`huashu-slides`](huashu-slides/SKILL.md)

- Path: `huashu-slides/SKILL.md`
- Direct trigger: `$huashu-slides`
- Description: 从内容到成品PPTX的端到端演示文稿制作，含AI插画生成和18种设计风格。当用户提到"做PPT"、"做幻灯片"、"演示文稿"、"Keynote"、"slides"时使用。

#### [`huashu-speech-coach`](huashu-speech-coach/SKILL.md)

- Path: `huashu-speech-coach/SKILL.md`
- Direct trigger: `$huashu-speech-coach`
- Description: 演讲与分享教练。基于Patrick Winston（MIT AI教授）的How to Speak方法论，帮助准备线下培训、技术分享、B站教程视频等演讲场景。当用户提到"演讲"、"分享"、"培训"、"讲课"、"PPT演讲"、"开场"、"结尾"、"如何讲"、"演讲结构"时使用此技能。

### Images Visuals

#### [`huashu-image-upload`](huashu-image-upload/SKILL.md)

- Path: `huashu-image-upload/SKILL.md`
- Direct trigger: `$huashu-image-upload`
- Description: 文章配图一键生成并上传图床，自动插入Markdown链接。当用户提到"配图"、"插图"、"上传图片"、"文章配图"时使用。

#### [`huashu-wechat-image`](huashu-wechat-image/SKILL.md)

- Path: `huashu-wechat-image/SKILL.md`
- Direct trigger: `$huashu-wechat-image`
- Description: 为微信公众号文章生成高质量配图。支持封面图（2.35:1）、正文插图（16:9/4:3）、信息图。提供两条路径：AI生成（视觉创意型）和HTML渲染（文字精确型）。当用户提到"公众号配图"、"公众号封面"、"文章配图"、"正文插图"、"公众号图片"时使用此技能。

#### [`huashu-xhs-image`](huashu-xhs-image/SKILL.md)

- Path: `huashu-xhs-image/SKILL.md`
- Direct trigger: `$huashu-xhs-image`
- Description: 为小红书笔记生成高质量配图。默认AI生成（Gemini），仅精确数据表格用HTML兜底。当用户提到"小红书配图"、"小红书封面"、"小红书图片"、"做张小红书图"、"笔记配图"时使用此技能。

#### [`ljg-card`](ljg-card/SKILL.md)

- Path: `ljg-card/SKILL.md`
- Direct trigger: `$ljg-card`
- Description: Content caster (铸). Transforms content into PNG visuals. Seven molds: -l (default) long reading card, -i infograph, -m multi-card reading cards (1080x1440), -v editorial sketchnote (problem→failure→pivot→insight→naming, magazine + archive layout), -c comic (manga-style B&W), -w whiteboard (marker-style board layout), -b big-fonts attachment card (1080x1440, weathered 碑刻 style for 小红书). Output to ~/Downloads/. Use when user says '铸', 'cast', '做成图', '做成卡片', '做成信息图', '做成海报', '视觉笔记', 'sketchnote', '杂志', 'editorial', '漫画', 'comic', 'manga', '白板', 'whiteboard', '大字', '附件图', 'big fonts', '小红书卡片'. Replaces ljg-cards and ljg-infograph.

#### [`slack-gif-creator`](slack-gif-creator/SKILL.md)

- Path: `slack-gif-creator/SKILL.md`
- Direct trigger: `$slack-gif-creator`
- Description: Knowledge and utilities for creating animated GIFs optimized for Slack. Provides constraints, validation tools, and animation concepts. Use when users request animated GIFs for Slack like "make me a GIF of X doing Y for Slack.

#### [`visual-style-ppt`](visual-style-ppt/SKILL.md)

- Path: `visual-style-ppt/SKILL.md`
- Direct trigger: `$visual-style-ppt`
- Description: Create style-driven slide images strictly with the Image 2 model, assemble those images into image-only PPTX decks, and manage reusable visual style libraries from documents or visual references. Use when the user asks for a "PPT Skill", "风格驱动 PPT", "提炼风格做 PPT", "调用某个风格做 PPT", "图片版 PPT", "保存 PPT 风格", "列出 PPT 风格", "文档生成 PPT", "文章生成 PPT", "把文档做成演示文稿", or wants to extract, save, reuse, and apply visual style keywords specifically for visual slide/image deck creation.

### LJG Tools

#### [`ljg-present`](ljg-present/SKILL.md)

- Path: `ljg-present/SKILL.md`
- Direct trigger: `$ljg-present`
- Description: 演讲铸造器（Outline-Faithful）。基于 orgmode/markdown outline 层级 1:1 视觉化呈现——色块大字、ultra-bold 错位，原文不动只做美化。三档主题色 black/red/yellow（默认 black 或按 filetags 推断），可用 -r/-b/-y 显式覆盖；可用 --cyber 走黑底绿字 cyber-hacker 风。使用时用户会说：'讲这个'、'present'、'做成演讲'、'呈现一下'、'铸成演示'、'做个 slides'、'标语流'、'宣言体'、'slogan'、'manifesto'、'按 outline 美化'。输出单文件 HTML 到 ~/Downloads/。

### Research Learning

#### [`huashu-info-search`](huashu-info-search/SKILL.md)

- Path: `huashu-info-search/SKILL.md`
- Direct trigger: `$huashu-info-search`
- Description: 多渠道搜索新产品新技术，交叉验证后存入知识库。当用户提到"最新信息"、"新产品"、"搜索资料"、"查资料"、"了解XX"时使用。

#### [`huashu-material-search`](huashu-material-search/SKILL.md)

- Path: `huashu-material-search/SKILL.md`
- Direct trigger: `$huashu-material-search`
- Description: 搜索个人素材库1800+条真实经历和观点，为内容增加人味。当用户提到"个人经历"、"真实案例"、"素材"、"人味"时使用。

#### [`huashu-research`](huashu-research/SKILL.md)

- Path: `huashu-research/SKILL.md`
- Direct trigger: `$huashu-research`
- Description: 结构化网络调研流程，确保调研成果增量保存到文件，不因会话截断丢失。当用户说"调研"、"搜索资料"、"帮我查一下"、"了解一下"、"最新信息"时使用此技能。

#### [`hv-analysis`](hv-analysis/SKILL.md)

- Path: `hv-analysis/SKILL.md`
- Direct trigger: `$hv-analysis`
- Description: 横纵分析法（Horizontal-Vertical Analysis）深度研究Skill。由数字生命卡兹克提出，融合了索绪尔的历时-共时分析、社会科学的纵向-横截面研究设计、商学院案例研究法与竞争战略分析的核心思想。 当用户想要系统性研究一个产品、公司、概念、技术或人物时使用。核心是双轴分析：纵轴追踪从诞生到当下的完整生命历程（以叙事故事呈现），横轴在当下时间截面上与竞品/同类进行系统性横向对比，最后交叉两条轴产出独到洞察。最终产出一份排版精美的PDF研究报告。 触发词包括但不限于：横纵分析、研究一下、帮我分析、深度研究、做个研究、调研一下、竞品分析、帮我看看这个东西怎么样、这个产品/公司/概念是怎么回事、帮我摸清楚、帮我搞懂、帮我做个deep research。 即使用户只是说"帮我了解一下XX"或"XX是什么来头"，只要上下文暗示需要系统性的深度研究（而非简单的概念解释），都应该触发。也适用于用户丢来一个产品名、公司名、技术名词说"帮我研究一下这个"的场景。 不要用于简单的名词解释（用户只是问"XX是什么"）、不要用于公众号写作（那个用khazix-writer）、不要用于纯标题摘要生成（用wechat-title）。

#### [`ljg-learn`](ljg-learn/SKILL.md)

- Path: `ljg-learn/SKILL.md`
- Direct trigger: `$ljg-learn`
- Description: Deep concept anatomist that deconstructs any concept through 8 exploration dimensions (history, dialectics, phenomenology, linguistics, formalization, existentialism, aesthetics, meta-philosophy) and compresses insights into an epiphany. Use when user asks to explain, dissect, or deeply understand a concept, term, or idea. Triggers on '解剖概念', '概念解剖', 'explain concept', 'learn concept', '/ljg-learn'. Produces org-mode output.

#### [`ljg-paper`](ljg-paper/SKILL.md)

- Path: `ljg-paper/SKILL.md`
- Direct trigger: `$ljg-paper`
- Description: Paper reader for non-academics. Takes a paper and extracts its ideas for personal use. Focuses on understanding, not academic critique. Use when user shares an arxiv link, paper URL, PDF, or asks to analyze a research paper. Trigger words: '读论文', '分析论文', 'paper', or when user shares an academic paper.

#### [`ljg-paper-flow`](ljg-paper-flow/SKILL.md)

- Path: `ljg-paper-flow/SKILL.md`
- Direct trigger: `$ljg-paper-flow`
- Description: Paper workflow: read papers + cast cards in one go. Takes one or more arxiv links, paper URLs, PDFs, or paper names. For each paper, runs ljg-paper (generates org analysis) then ljg-card -v (generates visual sketchnote PNG). Use when user says '论文流', 'paper flow', '读论文并做卡片', '论文卡片', or provides multiple papers wanting both analysis and cards.

#### [`ljg-paper-river`](ljg-paper-river/SKILL.md)

- Path: `ljg-paper-river/SKILL.md`
- Direct trigger: `$ljg-paper-river`
- Description: 论文倒读法：给一篇论文，递归找出它批判和改进的前序论文（最多5层），再找它之后的最新进展，从源头正向讲述问题演化史。以问题为轴，费曼式讲解每篇论文看到的问题和解法创新。Use when user shares a paper and wants to understand its intellectual lineage, citation chain, problem evolution, or says '倒读', '论文溯源', '论文脉络', 'paper river', 'paper connects', 'trace back', '这篇论文的来龙去脉', '论文演化'. Also trigger when user wants to understand how a research problem evolved across multiple papers.

#### [`ljg-plain`](ljg-plain/SKILL.md)

- Path: `ljg-plain/SKILL.md`
- Direct trigger: `$ljg-plain`
- Description: Cognitive atom: Plain (白). Rewrites any content so a smart 12-year-old groks it. Structure-free — form follows content. Use when user says '白话说', '说人话', '解释一下', 'plain', 'grok'.

#### [`ljg-qa`](ljg-qa/SKILL.md)

- Path: `ljg-qa/SKILL.md`
- Direct trigger: `$ljg-qa`
- Description: 信息提问机。给一篇文章/论文/书，把核心观点抽成 Q-A 对——Question 切要害，不教科书；Answer 简洁清晰，有形式化收口，逻辑链完整。读者顺 Q 链走过，每个 A 砸下一枚钉子，复现作者整套推理。Use when user says '问答', 'Q&A', 'QA', '提问', '抽取问题', '/ljg-qa', or shares an article/paper/book and asks for Q-A extraction. Triggers when the user wants ideas extracted not as a summary but as a sequence of incisive questions with answered. NOT FOR FAQ generation, glossary creation, or comprehension quizzes — this is intellectual scaffolding, not study aids.

#### [`ljg-rank`](ljg-rank/SKILL.md)

- Path: `ljg-rank/SKILL.md`
- Direct trigger: `$ljg-rank`
- Description: 给一个领域，找出背后真正撑着它的几根独立的力。十几个现象砍到不可再少的生成器——砍完能把现象一个个生回来，才算数。Use when user says '降秩', '找秩', '秩是什么', '这个领域靠什么撑着', '背后是什么', or wants to decompose any domain to its irreducible generators.

#### [`ljg-read`](ljg-read/SKILL.md)

- Path: `ljg-read/SKILL.md`
- Direct trigger: `$ljg-read`
- Description: Reading companion agent. Accompanies user through any text (books, articles, essays, papers, news) with translation, structural annotation, deep questioning, and cross-domain insights. Detects language, translates English to Chinese (faithfulness-expressiveness-elegance), guides reader to understand the author and encounter real questions. Use when user says '伴读', '陪我读', '读这篇', 'read with me', 'companion read', or shares a text/URL wanting guided reading.

#### [`ljg-think`](ljg-think/SKILL.md)

- Path: `ljg-think/SKILL.md`
- Direct trigger: `$ljg-think`
- Description: 追本之箭——纵向深钻思维工具。给一个观点、现象或问题，像箭一样一路向下钻到不可再分的本质。Use when user says '想透', '追本', '本质是什么', '为什么会这样', '深挖', '钻到底', 'think deep', 'drill down', or wants to trace any idea/phenomenon vertically to its irreducible root. Also trigger when user provides a statement and wants depth analysis, not breadth survey.

#### [`ljg-travel`](ljg-travel/SKILL.md)

- Path: `ljg-travel/SKILL.md`
- Direct trigger: `$ljg-travel`
- Description: Deep travel research workflow for museums and ancient architecture. Input a city name, auto-generates structured knowledge document (org-mode) + portable reference cards (PNG). Covers historical background, museum highlights, archaeological significance, and architectural heritage. Use when user says '旅行研究', '博物馆功课', '古建功课', 'travel research', '出发前功课', or provides a city name with intent to do deep cultural travel preparation.

#### [`ljg-word`](ljg-word/SKILL.md)

- Path: `ljg-word/SKILL.md`
- Direct trigger: `$ljg-word`
- Description: Deep-dive English word mastery tool. Deconstructs a single English word into core semantics and epiphany. Use when user asks to explain/master a specific English word.

#### [`ljg-word-flow`](ljg-word-flow/SKILL.md)

- Path: `ljg-word-flow/SKILL.md`
- Direct trigger: `$ljg-word-flow`
- Description: Word flow: deep-dive word analysis + infograph card in one go. Takes one or more English words, runs ljg-word (generates deep semantics analysis) then ljg-card -i (generates infograph PNG). Use when user says '词卡', 'word card', 'word flow', or provides English words wanting both analysis and visual card.

### System

#### [`imagegen`](.system/imagegen/SKILL.md)

- Path: `.system/imagegen/SKILL.md`
- Direct trigger: `$imagegen`
- Description: Generate or edit raster images when the task benefits from AI-created bitmap visuals such as photos, illustrations, textures, sprites, mockups, or transparent-background cutouts. Use when Codex should create a brand-new image, transform an existing image, or derive visual variants from references, and the output should be a bitmap asset rather than repo-native code or vector. Do not use when the task is better handled by editing existing SVG/vector/code-native assets, extending an established icon or logo system, or building the visual directly in HTML/CSS/canvas.

#### [`openai-docs`](.system/openai-docs/SKILL.md)

- Path: `.system/openai-docs/SKILL.md`
- Direct trigger: `$openai-docs`
- Description: Use when the user asks how to build with OpenAI products or APIs, asks about Codex itself or choosing Codex surfaces, needs up-to-date official documentation with citations, help choosing the latest model for a use case, or model upgrade and prompt-upgrade guidance; use OpenAI docs MCP tools for non-Codex docs questions, use the Codex manual helper first for broad Codex self-knowledge, and restrict fallback browsing to official OpenAI domains.

#### [`plugin-creator`](.system/plugin-creator/SKILL.md)

- Path: `.system/plugin-creator/SKILL.md`
- Direct trigger: `$plugin-creator`
- Description: Create and scaffold plugin directories for Codex with a required `.codex-plugin/plugin.json`, optional plugin folders/files, valid manifest defaults, and personal-marketplace entries by default. Use when Codex needs to create a new personal plugin, add optional plugin structure, generate or update marketplace entries for plugin ordering and availability metadata, or update an existing local plugin during development with the CLI-driven cachebuster and reinstall flow.

#### [`skill-creator`](.system/skill-creator/SKILL.md)

- Path: `.system/skill-creator/SKILL.md`
- Direct trigger: `$skill-creator`
- Description: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Codex's capabilities with specialized knowledge, workflows, or tool integrations.

#### [`skill-installer`](.system/skill-installer/SKILL.md)

- Path: `.system/skill-installer/SKILL.md`
- Direct trigger: `$skill-installer`
- Description: Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path. Use when a user asks to list installable skills, install a curated skill, or install a skill from another repo (including private repos).

### Video

#### [`huashu-douyin-script`](huashu-douyin-script/SKILL.md)

- Path: `huashu-douyin-script/SKILL.md`
- Direct trigger: `$huashu-douyin-script`
- Description: 抖音爆款脚本创作工作流。从竞品视频拆解到脚本生成的完整流程：下载抖音视频→Gemini视频分析→爆款公式提炼→脚本+分镜生成→AI味审校。 当用户提到"抖音脚本"、"爆款拆解"、"竞品分析"、"带货脚本"、"千川素材"、"种草脚本"、"视频拆解"、"抖音视频分析"时使用此技能。

#### [`huashu-video-check`](huashu-video-check/SKILL.md)

- Path: `huashu-video-check/SKILL.md`
- Direct trigger: `$huashu-video-check`
- Description: 基于MrBeast策略检查视频标题、封面和开头钩子。当用户提到"视频标题"、"封面图"、"点击率"、"CTR"、"观看时长"时使用。

#### [`huashu-video-outline`](huashu-video-outline/SKILL.md)

- Path: `huashu-video-outline/SKILL.md`
- Direct trigger: `$huashu-video-outline`
- Description: 快速生成2-3个视频大纲方案，含标题、封面建议和结构设计。当用户提到"视频大纲"、"视频结构"、"脚本大纲"、"视频选题"时使用。

### Writing Content

#### [`huashu-article-edit`](huashu-article-edit/SKILL.md)

- Path: `huashu-article-edit/SKILL.md`
- Direct trigger: `$huashu-article-edit`
- Description: 标准化文章编辑流程，确保修改范围明确、进度可追踪、变更有记录。当用户说"编辑文章"、"修改文章"、"调整内容"、"改一下这篇"时使用此技能。

#### [`huashu-article-to-x`](huashu-article-to-x/SKILL.md)

- Path: `huashu-article-to-x/SKILL.md`
- Direct trigger: `$huashu-article-to-x`
- Description: 长文精简为X平台内容（200-500字），保留核心观点和个人风格。当用户提到"转微博"、"发小红书"、"社交媒体"、"缩短文章"时使用。

#### [`huashu-proofreading`](huashu-proofreading/SKILL.md)

- Path: `huashu-proofreading/SKILL.md`
- Direct trigger: `$huashu-proofreading`
- Description: 三遍审校降低AI检测率，让文章更有人味。当用户提到"AI味太重"、"像AI写的"、"降低AI检测率"、"审校"、"自然一些"时使用。

#### [`huashu-script-polish`](huashu-script-polish/SKILL.md)

- Path: `huashu-script-polish/SKILL.md`
- Direct trigger: `$huashu-script-polish`
- Description: 视频脚本口语化审校，去书面腔让脚本适合说出来。当用户提到"口语化"、"太书面了"、"像说话一样"、"脚本审校"时使用。

#### [`huashu-topic-gen`](huashu-topic-gen/SKILL.md)

- Path: `huashu-topic-gen/SKILL.md`
- Direct trigger: `$huashu-topic-gen`
- Description: 快速生成3-4个选题方向，含标题、大纲和优劣分析。当用户提到"选题"、"写什么"、"文章方向"、"题目建议"时使用。

#### [`huashu-wechat-creation`](huashu-wechat-creation/SKILL.md)

- Path: `huashu-wechat-creation/SKILL.md`
- Direct trigger: `$huashu-wechat-creation`
- Description: 花叔公众号内容创作全流程辅助；当用户需要创作公众号文章、讨论选题方向、审校优化内容时使用

#### [`khazix-writer`](khazix-writer/SKILL.md)

- Path: `khazix-writer/SKILL.md`
- Direct trigger: `$khazix-writer`
- Description: 数字生命卡兹克（Khazix）的公众号长文写作skill。当用户需要撰写公众号文章、写稿子、续写文章、根据素材产出长文时使用。触发词包括但不限于：写文章、写稿子、帮我写、续写、扩写、公众号文章、长文、出稿、按我的风格写。即使用户只是说"帮我把这个写成文章"或"用我的风格写一下"，只要上下文涉及内容创作和公众号输出，都应该触发。也适用于用户丢过来一个PDF、brief、新闻链接、语音转文字或任何素材说"帮我写篇文章"的场景。不要用于短内容（小红书帖子、推特、朋友圈）或纯标题摘要生成（那个用wechat-title skill）。

#### [`ljg-writes`](ljg-writes/SKILL.md)

- Path: `ljg-writes/SKILL.md`
- Direct trigger: `$ljg-writes`
- Description: 写作引擎。像手术刀剖开一个观点，一层层剥到底。1000-1500 字。

#### [`suno-prompt-architect`](suno-prompt-architect/SKILL.md)

- Path: `suno-prompt-architect/SKILL.md`
- Direct trigger: `$suno-prompt-architect`
- Description: Expert Suno AI prompt engineering for cinematic, transformative music creation. Use this skill when creating Suno prompts for Vibe OS sessions, meditation tracks, or any AI-generated music that needs professional quality and emotional resonance.

---

*Last updated: 2026-06-16 21:43:47 +08:00*

# 标题-标签-封面生成器

一个可迁移到其他智能体和 GitHub 的两阶段内容素材包 Skill。

它把一篇文章处理成可用于小红书、视频号、抖音、公众号等平台发布的素材包：

1. 第一阶段：文章 -> 标题候选 -> 标签策略 -> AI 推荐 -> 人工审核。
2. 第二阶段：确认标题 -> 封面 prompt -> mock/外部生图 -> 完整渠道素材包。

核心边界：先标题标签，后封面；标题未经人工确认，不生成封面。

## 目录

```text
title-tag-cover-generator/
├─ SKILL.md
├─ README.md
├─ agents/openai.yaml
├─ config/
│  ├─ image_api_config.example.json
│  └─ skill_config.json
├─ input/
│  ├─ article.txt
│  ├─ title_reference.md
│  ├─ tag_reference.md
│  └─ cover_references/
├─ outputs/
│  ├─ stage1/
│  ├─ cover/
│  └─ final/
├─ scripts/
│  ├─ run_stage1.py
│  ├─ run_stage2.py
│  └─ render_cover.ps1
├─ src/
└─ tests/
```

## 快速开始

把文章放入 `input/article.txt`，然后运行第一阶段：

```bash
python scripts/run_stage1.py \
  --article input/article.txt \
  --title-reference input/title_reference.md \
  --tag-reference input/tag_reference.md \
  --out outputs/stage1
```

第一阶段会输出：

- `outputs/stage1/article_analysis.md`
- `outputs/stage1/title_options.md`
- `outputs/stage1/selected_title_recommendation.md`
- `outputs/stage1/tag_strategy.md`
- `outputs/stage1/selected_tags_recommendation.md`
- `outputs/stage1/stage1_report.md`

然后暂停，人工确认标题、封面高亮词和标签。

确认标题后再运行第二阶段：

```bash
python scripts/run_stage2.py \
  --confirmed-title "这里放人工确认后的标题" \
  --line-breaks "第一行|第二行|第三行" \
  --highlight-words "高亮词1,高亮词2" \
  --config config/image_api_config.example.json \
  --stage1-dir outputs/stage1 \
  --cover-dir outputs/cover \
  --final-dir outputs/final
```

第二阶段会输出：

- `outputs/cover/confirmed_title.json`
- `outputs/cover/cover_prompt.md`
- `outputs/cover/cover_prompt.json`
- `outputs/cover/cover_image.png`
- `outputs/cover/cover_generation_report.md`
- `outputs/final/channel_content_package.json`
- `outputs/final/production_report.md`

## 生图模式

默认 `config/image_api_config.example.json` 使用 `mock` 模式，只生成占位图，用于验证流程。

接真实生图服务时，复制配置文件并改为：

```json
{
  "image_provider": "external_api",
  "api_base_url": "https://your-image-api.example.com/generate",
  "api_key_env": "IMAGE_API_KEY",
  "model": "your-model",
  "size": "3:4",
  "output_format": "png",
  "timeout_seconds": 120
}
```

API Key 只从环境变量读取，不要写入代码、配置或 `.env`。

## 职责边界

本 Skill 负责：

- 读取文章和参考规则。
- 生成标题候选、标题推荐、标签策略。
- 在人工确认标题后生成封面 prompt 和封面结果。
- 输出完整渠道素材包 JSON。

本 Skill 不负责：

- 自动发布内容。
- 连接 CRM、数据库或私域系统。
- 生成视频。
- 代替人工审核标题和封面。
- 保存或打印 API Key。

## GitHub 部署建议

运行前检查：

```bash
python tests/test_stage1.py
python tests/test_stage2.py
```

Skill 校验：

```bash
python /path/to/quick_validate.py /path/to/title-tag-cover-generator
```

`input/article.txt` 和 `outputs/` 默认被 `.gitignore` 排除，避免提交私有文章和生成物。

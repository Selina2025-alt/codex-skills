from pathlib import Path


PLATFORM_LABELS = {
    "xiaohongshu": "小红书",
    "douyin_shipinhao": "视频号 / 抖音",
    "wechat_article": "公众号",
}


def _write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _title_table(options):
    lines = ["| 平台 | 标题类型 | 标题 | 分数 | 推荐理由 |", "| --- | --- | --- | ---: | --- |"]
    for platform, items in options.items():
        label = PLATFORM_LABELS.get(platform, platform)
        for item in items:
            lines.append(f"| {label} | {item['type']} | {item['title']} | {item['score']} | {item['reason']} |")
    return "\n".join(lines)


def _selected_titles(options):
    lines = ["# AI 推荐标题", ""]
    for platform, items in options.items():
        best = items[0]
        label = PLATFORM_LABELS.get(platform, platform)
        lines.extend([
            f"## {label}",
            "",
            f"推荐标题：{best['title']}",
            "",
            f"推荐分数：{best['score']}",
            "",
            f"推荐理由：{best['reason']}",
            "",
        ])
    cover_words = _suggest_cover_words(options)
    lines.extend([
        "## 封面文字建议",
        "",
        f"建议高亮词：{', '.join(cover_words)}",
        "",
        "说明：封面阶段必须等待人工确认标题后再继续。",
    ])
    return "\n".join(lines)


def _suggest_cover_words(options):
    first_title = next(iter(options.values()))[0]["title"]
    words = []
    for token in ["别再", "真正", "不是", "而是", "判断", "失控", "底层逻辑", "工厂", "电网"]:
        if token in first_title:
            words.append(token)
    if not words:
        compact = first_title.replace("，", "").replace("：", "")
        words = [compact[:4], compact[-4:]]
    return words[:4]


def write_stage1_outputs(out_dir, analysis, title_options, tags):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)

    _write(out / "article_analysis.md", "\n".join([
        "# 文章分析",
        "",
        f"内容类型：{analysis['content_type']}",
        "",
        f"文章摘要：{analysis['summary']}",
        "",
        f"核心传播角度：{analysis['core_angle']}",
        "",
        f"旧认知：{analysis['old_belief']}",
        "",
        f"新判断：{analysis['new_belief']}",
        "",
        "关键词：",
        "",
        "\n".join(f"- {word}" for word in analysis["keywords"]),
    ]))

    _write(out / "title_options.md", "\n".join([
        "# 多平台标题候选",
        "",
        _title_table(title_options),
    ]))

    _write(out / "selected_title_recommendation.md", _selected_titles(title_options))

    _write(out / "tag_strategy.md", "\n".join([
        "# 标签策略",
        "",
        "## 策略原则",
        "",
        "\n".join(f"- {line}" for line in tags["strategy"]),
        "",
        "## 小红书标签",
        "",
        " ".join(tags["xiaohongshu"]),
        "",
        "## 抖音 / 视频号标签",
        "",
        " ".join(tags["douyin_shipinhao"]),
    ]))

    _write(out / "selected_tags_recommendation.md", "\n".join([
        "# AI 推荐标签",
        "",
        "## 小红书",
        "",
        " ".join(tags["xiaohongshu"]),
        "",
        "推荐理由：侧重搜索优化、长尾词和具体场景词，适合收藏与搜索流量。",
        "",
        "## 抖音 / 视频号",
        "",
        " ".join(tags["douyin_shipinhao"]),
        "",
        "推荐理由：侧重算法分发、核心内容和精准圈层识别。",
    ]))

    _write(out / "stage1_report.md", "\n".join([
        "# 第一阶段报告",
        "",
        "状态：已完成标题和标签生成。",
        "",
        "审核点 1：必须暂停，等待人工确认。",
        "",
        "请确认：",
        "",
        "- 使用哪个标题",
        "- 哪些词作为封面绿色高亮词",
        "- 标签是否通过",
        "- 是否需要改标题",
        "",
        "重要：第一阶段完成后不要继续生成封面。只有人工确认标题后，才允许进入第二阶段。",
    ]))

    return sorted(path.name for path in out.glob("*.md"))

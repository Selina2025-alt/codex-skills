import re


def _normalize_tag(text):
    cleaned = re.sub(r"[^\w\u4e00-\u9fff]", "", text)
    return "#" + cleaned if cleaned else ""


def _unique(tags, limit=8):
    result = []
    seen = set()
    for tag in tags:
        normalized = _normalize_tag(tag)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        result.append(normalized)
        if len(result) >= limit:
            break
    return result


def generate_tags(analysis, tag_reference):
    keywords = analysis.get("keywords") or []
    primary = keywords[0] if keywords else "内容创作"
    secondary = keywords[1] if len(keywords) > 1 else "认知升级"
    audience = keywords[2] if len(keywords) > 2 else "职场人"
    content_type = analysis.get("content_type", "高认知内容")
    joined = " ".join(keywords) + analysis.get("summary", "")

    xhs_candidates = [
        "企业AI" if "企业" in joined or "ToB" in joined else primary,
        f"{primary}避坑",
        f"{secondary}方法",
        f"{audience}必看",
        f"{content_type}笔记",
        "知识干货",
        "底层逻辑",
        "AI基础设施" if "AI" in joined else "成长思考",
    ]

    douyin_candidates = [
        "企业AI" if "企业" in joined or "ToB" in joined else primary,
        secondary,
        audience,
        content_type,
        "知识干货",
        "认知升级",
        "产业升级" if "产业" in joined else "职场成长",
        "商业思维" if content_type == "商业认知" else "实用经验",
    ]

    return {
        "xiaohongshu": _unique(xhs_candidates, 8),
        "douyin_shipinhao": _unique(douyin_candidates, 8),
        "strategy": [
            "高优先级：核心内容标签 + 内容价值标签，决定系统分发给谁。",
            "中优先级：目标人群标签 + 场景标签，决定转化率和精准度。",
            "低优先级：热点或品牌标签，仅在文章明确出现时使用。",
            "小红书使用长尾词和场景词；抖音/视频号使用精准圈层词。",
        ],
    }

import re


PLATFORM_NAMES = {
    "xiaohongshu": "小红书",
    "douyin_shipinhao": "视频号 / 抖音",
    "wechat_article": "公众号",
}


def _kw(analysis, index, fallback):
    keywords = analysis.get("keywords") or []
    return keywords[index] if index < len(keywords) else fallback


def _trim(title, max_len):
    return title if len(title) <= max_len else title[: max_len - 1] + "…"


def _contains_any(text, words):
    return any(word in text for word in words)


def _derive_terms(analysis):
    text = analysis.get("summary", "") + " " + " ".join(analysis.get("keywords") or [])
    primary = _kw(analysis, 0, "AI")
    if _contains_any(text, ["JovaAI", "ToB", "企业", "产业", "商业"]):
        primary = "企业AI"
    anchor = "权威专家"
    if "Zach" in text or "Lloyd" in text or "Warp" in text:
        anchor = "Warp创始人Zach Lloyd"
    metaphor = "电网层" if _contains_any(text, ["电网", "基础设施", "JovaAI", "网络"]) else "方向盘"
    old_model = "工具级Agent" if _contains_any(text, ["Agent", "Copilot", "智能体"]) else "AI工具"
    new_model = "产业级智能工厂" if _contains_any(text, ["产业", "工厂", "JovaAI"]) else "智能工厂"
    audience = "ToB企业" if _contains_any(text, ["ToB", "企业"]) else _kw(analysis, 2, "企业")
    return {
        "primary": primary,
        "anchor": anchor,
        "metaphor": metaphor,
        "old_model": old_model,
        "new_model": new_model,
        "audience": audience,
    }


def _score(title):
    score = 60
    if re.search(r"不是.+而是|别再|真正|为什么|从.+到|越.+越|没有消失|终局|底层逻辑", title):
        score += 12
    if _contains_any(title, ["工厂", "电网", "黑盒", "方向盘", "分水岭", "护城河", "许愿池", "老虎机"]):
        score += 10
    if _contains_any(title, ["错", "怕", "失控", "浪费", "平庸", "掏空", "卡住", "误区", "入场券"]):
        score += 8
    if _contains_any(title, ["揭秘", "讲清楚", "看懂", "拆解", "避坑", "拿回", "布局", "必修课"]):
        score += 6
    if 8 <= len(title) <= 58:
        score += 4
    return min(score, 96)


def _reason(title):
    reasons = []
    if "不是" in title or "而是" in title:
        reasons.append("有反常识判断")
    if "为什么" in title or "揭秘" in title:
        reasons.append("能制造解释欲")
    if "从" in title and "到" in title:
        reasons.append("有认知迁移")
    if _contains_any(title, ["别再", "真正", "失控", "入场券", "错过"]):
        reasons.append("用户后果清晰")
    if _contains_any(title, ["Zach", "Warp", "YC", "李飞飞", "Fadell"]):
        reasons.append("有高势能锚点")
    if not reasons:
        reasons.append("关键词明确，适合基础分发")
    return "，".join(reasons)


def generate_titles(analysis, title_reference):
    terms = _derive_terms(analysis)
    primary = terms["primary"]
    anchor = terms["anchor"]
    metaphor = terms["metaphor"]
    old_model = terms["old_model"]
    new_model = terms["new_model"]
    audience = terms["audience"]

    pools = {
        "xiaohongshu": [
            f"{primary}不是买工具，而是重建一座“{metaphor}”",
            f"别再只买AI工具了，老板真正缺的是{metaphor}",
            f"{anchor}提醒：未来企业拼的是智能工厂",
            f"{primary}转型必修课：先看懂工厂战",
            f"从软件工厂到产业工厂，{primary}要变了",
            f"{audience}避坑：别把{old_model}当全部答案",
            f"AI时代，企业真正要补的是产业网络",
            f"{primary}布局：为什么要先建“{metaphor}”",
            f"不是AI工具没用，是企业缺少智能工厂",
            f"老板看AI，别只盯着效率工具",
        ],
        "douyin_shipinhao": [
            f"{primary}，不是工具战，是工厂战",
            f"别把AI当工具，真正牌桌在产业网络",
            f"未来竞争，是工厂对工厂",
            f"AI越强，企业越需要{metaphor}",
            f"只买Copilot，救不了{audience}",
            f"{anchor}说透AI新战场",
            f"{primary}的终局，是智能工厂",
            f"别再用工具思维做{primary}",
            f"产业AI，不拼人力拼网络",
            f"拿不到交易网络，就拿不到入场券",
        ],
        "wechat_article": [
            f"从“软件工厂”到“{new_model}”：{primary}的底层逻辑变了",
            f"真正该怕的不是企业不会用AI，而是还停留在{old_model}",
            f"大模型提供电力，企业真正缺的是智能体协同的{metaphor}",
            f"AI原生时代，{audience}的胜负手不是工具，而是交易网络",
            f"{anchor}的软件工厂判断，为什么会指向产业级AI基础设施？",
            f"{primary}转型必修课：从内部效率工具到外部交易网络",
            f"未来十年，企业AI布局只剩两条路：工具内卷，或者工厂重构",
            f"为什么单点Agent救不了ToB企业？产业级智能工厂才是答案",
            f"从Copilot到智能体集群：企业AI正在进入基础设施竞争",
            f"{primary}的终局，不是更快写文档，而是重构客户入口和供应链话语权",
        ],
    }

    max_lens = {
        "xiaohongshu": 34,
        "douyin_shipinhao": 28,
        "wechat_article": 58,
    }

    result = {}
    for platform, titles in pools.items():
        options = []
        seen = set()
        for title in titles:
            clean = _trim(title, max_lens[platform])
            if clean in seen:
                continue
            seen.add(clean)
            options.append({
                "title": clean,
                "score": _score(clean),
                "type": _classify(clean),
                "reason": _reason(clean),
            })
        options.sort(key=lambda item: item["score"], reverse=True)
        result[platform] = options[:10]
    return result


def _classify(title):
    if "为什么" in title or "揭秘" in title:
        return "解释欲标题"
    if "不是" in title or "而是" in title or "别再" in title:
        return "认知纠偏标题"
    if "从" in title and "到" in title:
        return "认知迁移标题"
    if "必修课" in title or "布局" in title:
        return "权威/课程标题"
    if "终局" in title or "未来" in title:
        return "趋势判断标题"
    return "认知标题"

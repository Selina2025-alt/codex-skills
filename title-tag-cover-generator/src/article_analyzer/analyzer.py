import re
from collections import Counter


STOPWORDS = {
    "一个", "一种", "这个", "那个", "我们", "你们", "他们", "自己", "因为", "所以",
    "但是", "如果", "已经", "正在", "不是", "而是", "可以", "需要", "通过", "这些",
    "那些", "进行", "对于", "没有", "什么", "如何", "为什么", "以及", "或者", "可能",
    "今天", "现在", "未来", "真正", "很多", "大量", "核心", "内容", "文章",
}


def split_sentences(text):
    parts = re.split(r"[。！？!?；;\r\n]+", text)
    return [part.strip() for part in parts if part.strip()]


def extract_keywords(text, limit=14):
    tokens = re.findall(r"[A-Za-z][A-Za-z0-9_\-]{1,}|[\u4e00-\u9fff]{2,10}", text)
    cleaned = []
    for token in tokens:
        if token in STOPWORDS:
            continue
        if len(token) < 2:
            continue
        cleaned.append(token)
    counts = Counter(cleaned)
    return [word for word, _ in counts.most_common(limit)]


def infer_content_type(text, keywords):
    joined = text + " ".join(keywords)
    rules = [
        ("AI科技", ["AI", "人工智能", "大模型", "智能体", "Agent", "自动化", "Copilot"]),
        ("商业认知", ["商业", "增长", "企业", "管理", "战略", "客户", "品牌", "ToB"]),
        ("职场成长", ["职场", "能力", "效率", "团队", "老板", "高管", "管理者"]),
        ("知识科普", ["原理", "逻辑", "方法", "解释", "为什么", "科普"]),
        ("产品种草", ["产品", "工具", "体验", "功能", "用户", "设计"]),
        ("热点评论", ["刷屏", "热点", "事件", "争议", "最新", "趋势"]),
    ]
    for name, needles in rules:
        if any(needle in joined for needle in needles):
            return name
    return "高认知内容"


def build_core_angle(sentences, keywords, content_type):
    seed = sentences[0] if sentences else "这篇文章需要提炼一个清晰、可转发的核心判断"
    keyword = keywords[0] if keywords else "这件事"
    return f"围绕“{keyword}”，把文章从信息介绍升级为{content_type}判断：{seed[:90]}"


def analyze_article(text):
    stripped = text.strip()
    sentences = split_sentences(stripped)
    keywords = extract_keywords(stripped)
    content_type = infer_content_type(stripped, keywords)
    summary = "；".join(sentences[:3])[:300] if sentences else stripped[:300]
    core_angle = build_core_angle(sentences, keywords, content_type)
    first_keyword = keywords[0] if keywords else "这件事"
    return {
        "summary": summary,
        "core_angle": core_angle,
        "keywords": keywords,
        "content_type": content_type,
        "old_belief": f"用户可能以为重点只是“{first_keyword}是什么”",
        "new_belief": f"真正值得理解的是“{first_keyword}会如何改变判断和行动”",
        "sentences": sentences,
    }

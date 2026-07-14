import json
import re
from pathlib import Path


def build_final_package(stage1_dir, cover_dir, final_dir):
    stage1 = Path(stage1_dir)
    cover = Path(cover_dir)
    final = Path(final_dir)
    final.mkdir(parents=True, exist_ok=True)

    analysis_text = _read(stage1 / "article_analysis.md")
    title_options_text = _read(stage1 / "title_options.md")
    selected_title_text = _read(stage1 / "selected_title_recommendation.md")
    selected_tags_text = _read(stage1 / "selected_tags_recommendation.md")
    confirmed = _read_json(cover / "confirmed_title.json", default={})
    cover_prompt = _read_json(cover / "cover_prompt.json", default={})

    package = {
        "article_summary": _extract_after(analysis_text, "文章摘要："),
        "core_angle": _extract_after(analysis_text, "核心传播角度："),
        "platform_titles": _parse_title_options(title_options_text),
        "selected_titles": _parse_selected_titles(selected_title_text),
        "tags": _parse_tags(selected_tags_text),
        "cover": {
            "title": confirmed.get("confirmed_title", cover_prompt.get("title", "")),
            "subtitle": confirmed.get("subtitle", ""),
            "highlight_words": confirmed.get("highlight_words", cover_prompt.get("highlight_words", [])),
            "line_breaks": confirmed.get("line_breaks", cover_prompt.get("line_breaks", [])),
            "cover_prompt_path": str(cover / "cover_prompt.md"),
            "cover_image_path": str(cover / "cover_image.png"),
        },
        "publish_copy": {
            "xiaohongshu": "",
            "douyin_shipinhao": "",
            "wechat_article": "",
        },
        "human_review_items": [
            "Review final cover image before publishing.",
            "Confirm platform-specific copy before publishing.",
        ],
    }

    package_path = final / "channel_content_package.json"
    report_path = final / "production_report.md"
    package_path.write_text(json.dumps(package, ensure_ascii=False, indent=2), encoding="utf-8")
    report_path.write_text(_report(package), encoding="utf-8")
    return package_path, report_path


def _read(path):
    return path.read_text(encoding="utf-8") if path.exists() else ""


def _read_json(path, default):
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def _extract_after(text, prefix):
    for line in text.splitlines():
        if line.startswith(prefix):
            return line[len(prefix):].strip()
    return ""


def _parse_title_options(text):
    result = {"xiaohongshu": [], "douyin_shipinhao": [], "wechat_article": []}
    platform_map = {"小红书": "xiaohongshu", "视频号 / 抖音": "douyin_shipinhao", "公众号": "wechat_article"}
    for line in text.splitlines():
        if not line.startswith("| "):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) < 5 or cells[0] in ("平台", "---"):
            continue
        key = platform_map.get(cells[0])
        if key:
            result[key].append(cells[2])
    return result


def _parse_selected_titles(text):
    result = {"xiaohongshu": "", "douyin_shipinhao": "", "wechat_article": ""}
    current = None
    for line in text.splitlines():
        if line.startswith("## 小红书"):
            current = "xiaohongshu"
        elif line.startswith("## 视频号"):
            current = "douyin_shipinhao"
        elif line.startswith("## 公众号"):
            current = "wechat_article"
        elif current and line.startswith("推荐标题："):
            result[current] = line.replace("推荐标题：", "").strip()
    return result


def _parse_tags(text):
    sections = {"xiaohongshu": [], "douyin_shipinhao": []}
    current = None
    for line in text.splitlines():
        if line.startswith("## 小红书"):
            current = "xiaohongshu"
        elif line.startswith("## 抖音"):
            current = "douyin_shipinhao"
        elif current and "#" in line:
            sections[current].extend(re.findall(r"#[\w\u4e00-\u9fff]+", line))
    return sections


def _report(package):
    return "\n".join([
        "# Production Report",
        "",
        "Status: final package generated.",
        "",
        f"Cover image: `{package['cover']['cover_image_path']}`",
        "",
        "Human review items:",
        "",
        *[f"- {item}" for item in package["human_review_items"]],
    ])

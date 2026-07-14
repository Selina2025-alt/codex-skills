import json
from pathlib import Path


def build_cover_prompt(confirmed_title):
    title = confirmed_title["confirmed_title"]
    line_breaks = confirmed_title.get("line_breaks") or [title]
    highlight_words = confirmed_title.get("highlight_words") or confirmed_title.get("suggested_highlight_words") or []
    prompt = (
        "Create a complete 3:4 Chinese channel cover based on the provided title. "
        "Keep the title meaning unchanged. Use a black background, bold high-contrast title typography, "
        "green highlights for selected key words, and a black-and-white lower image related to the title. "
        "Leave top space for later tags and bottom space for a logo. Do not add unrelated text."
    )
    image_prompt = (
        "Generate a black-and-white, no-text lower cover image matching the title theme. "
        "The image should be cinematic, high contrast, and suitable for a business/AI/technology cover. "
        "Do not include words, labels, logos, UI text, watermarks, or colored accents."
    )
    return {
        "title": title,
        "subtitle": confirmed_title.get("subtitle", ""),
        "line_breaks": line_breaks,
        "highlight_words": highlight_words,
        "cover_prompt": prompt,
        "lower_image_prompt": image_prompt,
        "layout": {
            "ratio": "3:4",
            "preferred_size": "1080x1440",
            "lower_image_ratio": "match_reference_or_16:9",
            "top_reserved_for_tags": True,
            "bottom_reserved_for_logo": True,
        },
    }


def write_cover_prompt_outputs(prompt_data, out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    (out / "cover_prompt.json").write_text(json.dumps(prompt_data, ensure_ascii=False, indent=2), encoding="utf-8")
    (out / "cover_prompt.md").write_text(_to_markdown(prompt_data), encoding="utf-8")
    return out / "cover_prompt.json", out / "cover_prompt.md"


def _to_markdown(data):
    return "\n".join([
        "# Cover Prompt",
        "",
        f"Title: {data['title']}",
        "",
        "Line breaks:",
        "",
        *[f"- {line}" for line in data["line_breaks"]],
        "",
        "Highlight words:",
        "",
        *[f"- {word}" for word in data["highlight_words"]],
        "",
        "Cover prompt:",
        "",
        data["cover_prompt"],
        "",
        "Lower image prompt:",
        "",
        data["lower_image_prompt"],
    ])

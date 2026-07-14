import argparse
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from src.cover_prompt_builder import build_cover_prompt, write_cover_prompt_outputs
from src.image_provider import generate_cover_image
from src.package_builder import build_final_package


def read_json(path, default=None):
    p = Path(path)
    if not p.exists():
        return default
    return json.loads(p.read_text(encoding="utf-8"))


def split_arg(value, sep):
    if not value:
        return []
    return [item.strip() for item in value.split(sep) if item.strip()]


def main():
    parser = argparse.ArgumentParser(description="Run Stage 2: confirmed title -> cover prompt/image -> final package.")
    parser.add_argument("--confirmed-title", default="")
    parser.add_argument("--confirmed-title-json", default="outputs/cover/confirmed_title.json")
    parser.add_argument("--subtitle", default="")
    parser.add_argument("--line-breaks", default="", help="Use | to separate title lines.")
    parser.add_argument("--highlight-words", default="", help="Use comma to separate highlight words.")
    parser.add_argument("--config", default="config/image_api_config.example.json")
    parser.add_argument("--stage1-dir", default="outputs/stage1")
    parser.add_argument("--cover-dir", default="outputs/cover")
    parser.add_argument("--final-dir", default="outputs/final")
    args = parser.parse_args()

    cover_dir = Path(args.cover_dir)
    cover_dir.mkdir(parents=True, exist_ok=True)

    confirmed = read_json(args.confirmed_title_json, default={}) or {}
    if args.confirmed_title:
        confirmed["confirmed_title"] = args.confirmed_title
    if not confirmed.get("confirmed_title"):
        raise SystemExit("Stage 2 requires --confirmed-title or an existing confirmed_title.json.")

    confirmed["title_source"] = confirmed.get("title_source", "human_review")
    confirmed["status"] = "confirmed"
    confirmed["subtitle"] = args.subtitle or confirmed.get("subtitle", "")
    confirmed["line_breaks"] = split_arg(args.line_breaks, "|") if args.line_breaks else confirmed.get("line_breaks") or [confirmed["confirmed_title"]]
    confirmed["highlight_words"] = split_arg(args.highlight_words, ",") if args.highlight_words else confirmed.get("highlight_words") or confirmed.get("suggested_highlight_words", [])

    confirmed_path = cover_dir / "confirmed_title.json"
    confirmed_path.write_text(json.dumps(confirmed, ensure_ascii=False, indent=2), encoding="utf-8")

    prompt_data = build_cover_prompt(confirmed)
    write_cover_prompt_outputs(prompt_data, cover_dir)

    config = read_json(args.config, default={"image_provider": "mock"}) or {"image_provider": "mock"}
    image_result = generate_cover_image(prompt_data, config, cover_dir / "cover_image.png")

    report = "\n".join([
        "# Cover Generation Report",
        "",
        "Status: completed.",
        "",
        f"Provider: {image_result['provider']}",
        f"Cover image: `{image_result['path']}`",
        "",
        "Review Gate 2: inspect the cover image before publishing.",
    ])
    (cover_dir / "cover_generation_report.md").write_text(report, encoding="utf-8")

    package_path, report_path = build_final_package(args.stage1_dir, cover_dir, args.final_dir)

    print("Stage 2 complete. Cover review is required before publishing.")
    print(f"- {confirmed_path}")
    print(f"- {cover_dir / 'cover_prompt.md'}")
    print(f"- {cover_dir / 'cover_image.png'}")
    print(f"- {package_path}")
    print(f"- {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

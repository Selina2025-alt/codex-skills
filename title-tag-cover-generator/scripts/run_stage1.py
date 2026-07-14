import argparse
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from src.article_analyzer import analyze_article
from src.package_builder import write_stage1_outputs
from src.tag_generator import generate_tags
from src.title_generator import generate_titles


def read_text(path):
    file_path = Path(path)
    for encoding in ("utf-8-sig", "utf-16", "gb18030"):
        try:
            return file_path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
    return file_path.read_text(encoding="utf-8-sig", errors="replace")


def main():
    parser = argparse.ArgumentParser(description="Run Stage 1: article analysis, title options, tag strategy, then stop for review.")
    parser.add_argument("--article", default="input/article.txt")
    parser.add_argument("--title-reference", default="input/title_reference.md")
    parser.add_argument("--tag-reference", default="input/tag_reference.md")
    parser.add_argument("--out", default="outputs/stage1")
    args = parser.parse_args()

    article = read_text(args.article)
    title_reference = read_text(args.title_reference)
    tag_reference = read_text(args.tag_reference)

    analysis = analyze_article(article)
    title_options = generate_titles(analysis, title_reference)
    tags = generate_tags(analysis, tag_reference)
    files = write_stage1_outputs(args.out, analysis, title_options, tags)

    print("Stage 1 complete. Human review is required before cover generation.")
    print("Generated files:")
    for name in files:
        print(f"- {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

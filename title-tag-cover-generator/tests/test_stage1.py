import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class Stage1SmokeTest(unittest.TestCase):
    def test_stage1_smoke(self):
        root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            article = temp / "article.txt"
            title_ref = temp / "title_reference.md"
            tag_ref = temp / "tag_reference.md"
            out = temp / "stage1"

            article.write_text(
                "AI工具越来越强，但很多团队把它当许愿池，结果反而丢掉了判断力。真正重要的不是自动生成，而是拿回方向盘。",
                encoding="utf-8",
            )
            title_ref.write_text("不是A而是B；从A到B；A越强B越重要。", encoding="utf-8")
            tag_ref.write_text("5-8个标签；小红书长尾；抖音精准圈层。", encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(root / "scripts" / "run_stage1.py"),
                    "--article",
                    str(article),
                    "--title-reference",
                    str(title_ref),
                    "--tag-reference",
                    str(tag_ref),
                    "--out",
                    str(out),
                ],
                cwd=root,
                text=True,
                capture_output=True,
                check=True,
            )

            self.assertIn("Human review is required", result.stdout)
            self.assertTrue((out / "stage1_report.md").exists())
            self.assertIn("不要继续生成封面", (out / "stage1_report.md").read_text(encoding="utf-8"))
            title_options = (out / "title_options.md").read_text(encoding="utf-8")
            self.assertGreaterEqual(title_options.count("| 小红书 |"), 10)
            self.assertGreaterEqual(title_options.count("| 视频号 / 抖音 |"), 10)
            self.assertGreaterEqual(title_options.count("| 公众号 |"), 10)


if __name__ == "__main__":
    unittest.main()

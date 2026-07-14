import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class Stage2SmokeTest(unittest.TestCase):
    def test_stage2_mock_package(self):
        root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            stage1 = temp / "stage1"
            cover = temp / "cover"
            final = temp / "final"
            config = temp / "image_api_config.json"
            stage1.mkdir()

            (stage1 / "article_analysis.md").write_text(
                "# 文章分析\n\n文章摘要：测试摘要\n\n核心传播角度：测试角度\n",
                encoding="utf-8",
            )
            (stage1 / "title_options.md").write_text(
                "| 平台 | 标题类型 | 标题 | 分数 | 推荐理由 |\n"
                "| --- | --- | --- | ---: | --- |\n"
                "| 小红书 | 认知标题 | 测试标题A | 90 | 好 |\n"
                "| 视频号 / 抖音 | 认知标题 | 测试标题B | 90 | 好 |\n"
                "| 公众号 | 认知标题 | 测试标题C | 90 | 好 |\n",
                encoding="utf-8",
            )
            (stage1 / "selected_title_recommendation.md").write_text(
                "## 小红书\n\n推荐标题：测试标题A\n\n## 视频号 / 抖音\n\n推荐标题：测试标题B\n\n## 公众号\n\n推荐标题：测试标题C\n",
                encoding="utf-8",
            )
            (stage1 / "selected_tags_recommendation.md").write_text(
                "## 小红书\n\n#企业AI #知识干货\n\n## 抖音 / 视频号\n\n#企业AI #商业认知\n",
                encoding="utf-8",
            )
            config.write_text(json.dumps({"image_provider": "mock"}), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(root / "scripts" / "run_stage2.py"),
                    "--confirmed-title",
                    "测试确认标题",
                    "--line-breaks",
                    "测试确认标题|第二行",
                    "--highlight-words",
                    "测试,标题",
                    "--config",
                    str(config),
                    "--stage1-dir",
                    str(stage1),
                    "--cover-dir",
                    str(cover),
                    "--final-dir",
                    str(final),
                ],
                cwd=root,
                text=True,
                capture_output=True,
                check=True,
            )

            self.assertIn("Cover review is required", result.stdout)
            self.assertTrue((cover / "cover_image.png").exists())
            package = json.loads((final / "channel_content_package.json").read_text(encoding="utf-8"))
            self.assertEqual(package["cover"]["title"], "测试确认标题")


if __name__ == "__main__":
    unittest.main()

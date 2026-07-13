import importlib.util
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("extract_glove_source_matrix.py")
SPEC = importlib.util.spec_from_file_location("extract_glove_source_matrix", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class GloveSourceMatrixTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        scene = Path(__file__).parents[1] / "参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/15_添譜來堂_拳頭.tscn"
        cls.nodes = MODULE.parse_nodes(scene.read_text(encoding="utf-8-sig"))

    def test_figure_one_uses_source_anchors(self):
        rows = MODULE.compile_matrix(self.nodes, MODULE.FIGURE_STATES["figure-1"])
        self.assertEqual(rows[15][20], "我")
        self.assertEqual(rows[7][16], "剑")
        self.assertEqual(rows[4][24], "勇")
        self.assertEqual(rows[17][26], "零")
        self.assertEqual(rows[17][18], "一")
        self.assertEqual(rows[2][15:18], "掌掌掌")
        self.assertNotIn("逼退", rows[13])
        self.assertNotEqual(rows[13][21], "线")
        self.assertNotEqual(rows[14][22], "线")

    def test_figure_two_reveals_good_sentence(self):
        rows = MODULE.compile_matrix(self.nodes, MODULE.FIGURE_STATES["figure-2"])
        self.assertEqual(rows[13][12:20], "逼退好手的生命线")


if __name__ == "__main__":
    unittest.main()

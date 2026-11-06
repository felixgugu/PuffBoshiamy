#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tests for tools/make_hints.py."""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import make_hints  # noqa: E402


class TestHints(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = ROOT / "data" / "liu7.cin"
        if not cls.source.exists():
            raise unittest.SkipTest("liu7.cin not present")
        cls.hints, cls.fmt, cls.bad = make_hints.build_hints(cls.source)
        cls.prefixes, cls.pfmt, cls.code_count = make_hints.build_prefixes(cls.source)
        cls.entries, _ = make_hints.read_source(cls.source)
        cls.freq = make_hints.read_essay(ROOT / "data" / "essay.txt")
        cls.completion = make_hints.build_completion(cls.entries, cls.freq)

    def test_counts(self):
        self.assertEqual(self.fmt, "cin")
        self.assertEqual(len(self.hints), 19680)
        self.assertEqual(self.bad, 0)
        self.assertEqual(self.pfmt, "cin")
        self.assertEqual(self.code_count, 22778)

    def test_prefixes(self):
        self.assertIn("ak", self.prefixes)
        self.assertIn("av", self.prefixes)
        self.assertIn("v", self.prefixes)
        self.assertNotIn("akv", self.prefixes)

    def test_known_hints(self):
        self.assertEqual(self.hints["對"], ("a", "feba"))
        self.assertEqual(self.hints["你"], ("pns", "pns"))
        self.assertEqual(self.hints["是"], ("jn", "dez"))
        self.assertEqual(self.hints["的"], ("d", "pdna"))
        self.assertEqual(self.hints["一"], ("e", "e"))

    def test_lengths(self):
        for _char, (short, full) in self.hints.items():
            self.assertGreaterEqual(len(short), 1)
            self.assertLessEqual(len(short), len(full))

    def test_completion_order(self):
        def texts(prefix):
            return "".join(text for text, _code in self.completion[prefix])

        self.assertTrue(texts("i").startswith("我說這讓"))
        self.assertTrue(texts("a").startswith("也會點"))
        self.assertTrue(texts("aa").startswith("錢鋪鑫"))
        self.assertEqual(self.completion["out"], [("嚅", "outr")])

    def test_completion_excludes_exact_codes(self):
        def texts(prefix):
            return {text for text, _code in self.completion[prefix]}

        self.assertNotIn("後", texts("i"))
        self.assertNotIn("對", texts("a"))
        self.assertNotIn("寸", texts("aa"))
        self.assertNotIn("丶", texts("aa"))
        self.assertNotIn("aaa", self.completion)

    def test_completion_prefixes_and_codes(self):
        codes_by_text = {}
        for code, text, _lineno in self.entries:
            codes_by_text.setdefault(text, []).append(code)
        for prefix in ("i", "a", "aa", "ak", "out"):
            for text, code in self.completion[prefix]:
                codes = codes_by_text[text]
                self.assertTrue(code.startswith(prefix))
                self.assertIn(code, codes)
                self.assertNotIn(prefix, codes)
                # The hint is the shortest code for this prefix.
                self.assertEqual(len(code), min(len(c) for c in codes
                                                 if c.startswith(prefix)))

    def test_dist_file_if_built(self):
        dist = ROOT / "dist" / "lua" / "boshiamy_hints.lua"
        if not dist.exists():
            self.skipTest("dist not built")
        text = dist.read_text(encoding="utf-8")
        self.assertIn('["對"] = { short = "a", full = "feba" }', text)
        self.assertIn('["你"] = { short = "pns", full = "pns" }', text)

    def test_completion_file_if_built(self):
        dist = ROOT / "dist" / "lua" / "boshiamy_completion_data.lua"
        if not dist.exists():
            self.skipTest("dist not built")
        text = dist.read_text(encoding="utf-8")
        self.assertIn('["i"] = "我\\tix\\n說\\tir', text)
        self.assertIn('["a"] = "也\\tal\\n會\\tad', text)
        self.assertIn('["out"] = "嚅\\toutr\\n"', text)

    def test_prefix_file_if_built(self):
        dist = ROOT / "dist" / "lua" / "boshiamy_prefixes.lua"
        if not dist.exists():
            self.skipTest("dist not built")
        text = dist.read_text(encoding="utf-8")
        self.assertIn('["ak"] = true', text)
        self.assertNotIn('["akv"] = true', text)


if __name__ == "__main__":
    unittest.main()

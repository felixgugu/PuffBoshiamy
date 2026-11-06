#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build the Trime/Android variants of the shared schema and rime.lua.

The Android package does not include the forgotten-code list, so the
forgotten segmentor/translator/pattern and the Windows icon fields are
removed.  The handwritten schema stays the single source of truth.
"""

import argparse
from pathlib import Path


def filter_schema(text: str) -> str:
    out = []
    skip_forgotten = False
    for line in text.splitlines():
        if line.startswith("forgotten:"):
            skip_forgotten = True
            continue
        if skip_forgotten:
            if line.startswith((" ", "\t")) or not line.strip():
                continue
            skip_forgotten = False

        stripped = line.strip()
        if stripped.startswith("#") and "forgotten" in stripped.lower():
            continue
        if stripped in ("- affix_segmentor@forgotten",
                        "- lua_translator@forgotten"):
            continue
        if stripped.startswith("forgotten: '^,,f"):
            continue
        if stripped == "# Forgotten-code list: ,,fk (prefix ,,f + code k).":
            continue
        if stripped in ("icon: puff.ico", "ascii_icon: puff_ascii.ico"):
            continue
        out.append(line)
    return "\n".join(out).rstrip() + "\n"


def add_zhuyin_key_processor(text: str) -> str:
    if "lua_processor@zhuyin_key" in text:
        return text
    lines = text.splitlines()
    out = []
    inserted = False
    for line in lines:
        out.append(line)
        if not inserted and line.strip() == "- ascii_composer":
            indent = line[:len(line) - len(line.lstrip())]
            out.append(indent + "- lua_processor@zhuyin_key")
            inserted = True
    return "\n".join(out).rstrip() + "\n"


def filter_rime(text: str) -> str:
    lines = [line for line in text.splitlines()
             if "forgotten = require" not in line]
    text = "\n".join(lines).rstrip() + "\n"
    if "zhuyin_key = require" not in text:
        text = text.replace(
            'grave_guard = require("grave_guard")',
            'grave_guard = require("grave_guard")\n'
            'zhuyin_key = require("zhuyin_key")')
    return text


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--schema", type=Path, required=True)
    parser.add_argument("--rime", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)
    schema = filter_schema(args.schema.read_text(encoding="utf-8"))
    schema = add_zhuyin_key_processor(schema)
    rime = filter_rime(args.rime.read_text(encoding="utf-8"))
    (args.out / "puffime.schema.yaml").write_text(schema, encoding="utf-8")
    (args.out / "rime.lua").write_text(rime, encoding="utf-8")

    try:
        import yaml
        loaded = yaml.safe_load(schema)
        assert "forgotten" not in loaded
        assert "icon" not in loaded.get("schema", {})
        assert "affix_segmentor@forgotten" not in loaded["engine"]["segmentors"]
        assert "lua_translator@forgotten" not in loaded["engine"]["translators"]
    except ImportError:
        pass

    print(f"wrote {args.out / 'puffime.schema.yaml'}")
    print(f"wrote {args.out / 'rime.lua'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

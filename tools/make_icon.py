#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate the Weasel schema icons from platforms/windows/icons/puff-source.png.

The source is the red seal image; puff_ascii.ico is a monochrome gray
version used in ASCII mode.  Requires Pillow (PIL).

    python tools/make_icon.py
"""

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow is required: pip install Pillow", file=sys.stderr)
    raise SystemExit(1)

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "platforms" / "windows" / "icons"
SOURCE = ICON_DIR / "puff-source.png"
RED_ICON = ICON_DIR / "puff.ico"
GRAY_ICON = ICON_DIR / "puff_ascii.ico"
SIZES = [16, 20, 24, 32, 40, 48, 64, 128, 256]
ASCII_GRAY = (176, 176, 176)


def main() -> int:
    if not SOURCE.exists():
        print(f"missing source image: {SOURCE}", file=sys.stderr)
        return 1

    im = Image.open(SOURCE).convert("RGBA")
    bbox = im.getchannel("A").getbbox()
    if bbox:
        pad = int(max(bbox[2] - bbox[0], bbox[3] - bbox[1]) * 0.04)
        box = (
            max(0, bbox[0] - pad),
            max(0, bbox[1] - pad),
            min(im.width, bbox[2] + pad),
            min(im.height, bbox[3] + pad),
        )
        im = im.crop(box)

    im.save(RED_ICON, format="ICO", sizes=[(s, s) for s in SIZES])

    gray = Image.new("RGBA", im.size, (*ASCII_GRAY, 0))
    gray.putalpha(im.getchannel("A"))
    gray.save(GRAY_ICON, format="ICO", sizes=[(s, s) for s in SIZES])

    print(f"wrote {RED_ICON} ({RED_ICON.stat().st_size} bytes)")
    print(f"wrote {GRAY_ICON} ({GRAY_ICON.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

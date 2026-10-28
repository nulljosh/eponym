"""Root Sans: Inter 4.1 (Rasmus Andersson, SIL Open Font License 1.1, no reserved name), renamed.

The brief (Joshua, 2026-10-28): a font of our own, close to San Francisco, proportionally spaced. Inter was drawn
in the same spirit as San Francisco and is the nearest open match. Same method as Kernel Sans: pinned release,
renamed, OFL shipped beside the fonts, the Inter authors' copyright kept in the name table. The full files, not
the Latin subset, because roots arrive in Greek and Cyrillic too. Named for the mark, not the app, so a rename
of the app leaves it alone.

    uv run --with fonttools --with brotli python3 scripts/gen_font.py           # fonts/RootSans-*.{ttf,woff2} + OFL.txt
    uv run --with fonttools --with brotli python3 scripts/gen_font.py --check   # named, licensed, proportional, Greek
"""
import io
import os
import sys
import urllib.request

from fontTools.ttLib import TTFont

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "fonts")
SOURCE = "https://cdn.jsdelivr.net/gh/rsms/inter@v4.1/"
WEIGHTS = {"Regular": "Regular", "Medium": "Medium", "Semibold": "SemiBold", "Bold": "Bold"}
COPYRIGHT = "Copyright 2016 The Inter Project Authors (https://github.com/rsms/inter). Root Sans is Inter, renamed."
LICENSE = "This Font Software is licensed under the SIL Open Font License, Version 1.1."


def fetch(path):
    """Bytes of one file from the pinned Inter release."""
    with urllib.request.urlopen(SOURCE + path, timeout=60) as r:
        return r.read()


def rename(font, style):
    """Give the outlines the Root Sans name, with the copyright and the OFL in the name table."""
    names = {0: COPYRIGHT, 13: LICENSE, 14: "https://openfontlicense.org", 1: "Root Sans", 2: style, 3: f"RootSans-{style}",
             4: f"Root Sans {style}", 5: "Version 1.000", 6: f"RootSans-{style}", 16: "Root Sans", 17: style}
    table = font["name"]
    table.names = []
    for nid, text in names.items():
        table.setName(text, nid, 3, 1, 0x409)
        table.setName(text, nid, 1, 0, 0)
    for tag in ("STAT", "fvar"):   # their name ids pointed at Inter's strings, now gone
        if tag in font:
            del font[tag]
    font["head"].created = font["head"].modified = 3_700_000_000   # fixed, so every build is the same bytes
    font["OS/2"].achVendID = "ROOT"


def to_bytes(font, flavor):
    """The font as TTF (flavor None) or WOFF2 bytes."""
    font.flavor = flavor
    buf = io.BytesIO()
    font.save(buf, reorderTables=False)
    return buf.getvalue()


def check():
    """Self-check of the shipped files."""
    assert os.path.exists(os.path.join(OUT, "OFL.txt")), "the OFL must ship with the fonts"
    for style in WEIGHTS:
        for ext in ("ttf", "woff2"):
            f = TTFont(os.path.join(OUT, f"RootSans-{style}.{ext}"))
            assert f["name"].getDebugName(1) == "Root Sans" and f["name"].getDebugName(6) == f"RootSans-{style}"
            assert "Inter Project" in f["name"].getDebugName(0), "the original copyright must stay in the name table"
            assert "Open Font License" in (f["name"].getDebugName(13) or ""), "license text missing"
            assert not any("Inter" == n.toUnicode() for n in f["name"].names), "Inter's name is still in the font"
            cmap, hmtx = f.getBestCmap(), f["hmtx"]
            assert hmtx[cmap[ord("i")]][0] < hmtx[cmap[ord("m")]][0], "letters are not proportional"
            assert hmtx[cmap[ord("1")]][0] < hmtx[cmap[ord("0")]][0], "figures are not proportional"
            for ch in "βίοςжизнь":
                assert ord(ch) in cmap, f"missing {ch}: roots in Greek and Cyrillic need it"
    print(f"font ok: Root Sans (Inter 4.1, OFL), {len(WEIGHTS)} weights, Latin, Greek and Cyrillic")


def main():
    """Fetch Inter, rename it, write every weight and the license; or run the check."""
    if "--check" in sys.argv:
        return check()
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "OFL.txt"), "wb") as f:
        f.write(fetch("LICENSE.txt"))
    for style, src in WEIGHTS.items():
        font = TTFont(io.BytesIO(fetch(f"docs/font-files/Inter-{src}.woff2")))
        rename(font, style)
        for ext, flavor in (("ttf", None), ("woff2", "woff2")):
            with open(os.path.join(OUT, f"RootSans-{style}.{ext}"), "wb") as f:
                f.write(to_bytes(font, flavor))
        print(f"RootSans-{style}: Inter {src}")


if __name__ == "__main__":
    main()

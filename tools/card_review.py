# -*- coding: utf-8 -*-
"""卡面核对工具：把 cardart3 里的图按 30 张一批拼成带卡名的对照图

用法：
  python tools/card_review.py            # 生成全部批次
  python tools/card_review.py 0          # 只生成第 0 批（1-30）
"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from card_subjects_v3a import SUBJECTS_V3_A
from card_subjects_v3b import SUBJECTS_V3_B

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "assets", "art", "cardart3")
if len(sys.argv) > 2:
    ART = sys.argv[2]
OUT_DIR = os.path.join(os.environ.get("TEMP", "."), "card3_review")
FONT = r"C:\Windows\Fonts\msyh.ttc"
CHUNK = 30
COLS = 6
S = 190

SUBJECTS = {}
SUBJECTS.update(SUBJECTS_V3_A)
SUBJECTS.update(SUBJECTS_V3_B)


def build(batch_index):
    names = list(SUBJECTS.keys())
    start = batch_index * CHUNK
    part = names[start:start + CHUNK]
    have = [n for n in part if os.path.exists(os.path.join(ART, n + ".png"))]
    if not have:
        return None
    rows = (len(have) + COLS - 1) // COLS
    sheet = Image.new("RGB", (COLS * S + (COLS + 1) * 6, rows * (S + 40) + (rows + 1) * 6), (14, 18, 24))
    dr = ImageDraw.Draw(sheet)
    font = ImageFont.truetype(FONT, 16)
    small = ImageFont.truetype(FONT, 11)
    for i, n in enumerate(have):
        im = Image.open(os.path.join(ART, n + ".png")).convert("RGB")
        im = im.resize((S, int(S * im.height / im.width)), Image.LANCZOS)
        x = 6 + (i % COLS) * (S + 6)
        y = 6 + (i // COLS) * (S + 40 + 6)
        sheet.paste(im, (x, y))
        dr.text((x + 1, y + S + 1), "%d %s" % (start + i + 1, n), fill=(232, 202, 142), font=font)
        subj = SUBJECTS[n]
        line = subj if len(subj) <= 34 else subj[:33] + "…"
        dr.text((x + 1, y + S + 20), line, fill=(150, 150, 155), font=small)
    os.makedirs(OUT_DIR, exist_ok=True)
    tag = os.path.basename(ART.rstrip("/\\"))
    out = os.path.join(OUT_DIR, "batch_%02d_%s.png" % (batch_index, tag))
    sheet.save(out, "PNG")
    return out


def main():
    only = int(sys.argv[1]) if len(sys.argv) > 1 else None
    total = (len(SUBJECTS) + CHUNK - 1) // CHUNK
    for b in ([only] if only is not None else range(total)):
        r = build(b)
        if r:
            print(r)


main()

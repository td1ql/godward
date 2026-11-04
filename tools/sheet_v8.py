# -*- coding: utf-8 -*-
"""卡面 v8 对照图 / 审阅图

两种用法：
  # 标定矩阵：行=卡，列=方案
  python tools/sheet_v8.py --stage probe --cards 打击,淬毒 --recipes A,B,C,D

  # 平铺目录（试点/全量审阅）
  python tools/sheet_v8.py --dir assets/art/cardart7 --cols 6 --title 试点
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from grade_v8 import stats  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "art", "_src_v8")
OUT = os.path.join(SRC, "sheets")
FONT_PATH = r"C:\Windows\Fonts\msyh.ttc"
TILE_W = 340
LABEL_H = 34


def font(size):
    try:
        return ImageFont.truetype(FONT_PATH, size)
    except Exception:
        return ImageFont.load_default()


def tile(path, w=TILE_W):
    im = Image.open(path).convert("RGB")
    h = int(round(w * im.height / im.width))
    return im.resize((w, h), Image.LANCZOS)


def matrix(stage, cards, recipes, seeds=1, out_name="probe_matrix.png"):
    tiles = []
    for card in cards:
        row = []
        for recipe in recipes:
            p = os.path.join(SRC, stage, card, "%s_s%d_g.png" % (recipe, seeds - 1))
            row.append(p if os.path.exists(p) else None)
        tiles.append((card, row))
    if not any(any(r) for _, r in tiles):
        print("没有可用的图")
        return None
    th = tile(next(p for _, row in tiles for p in row if p), TILE_W).height
    W = TILE_W * len(recipes) + 10 * (len(recipes) + 1)
    H = (th + LABEL_H) * len(cards) + 10 * (len(cards) + 1) + 44
    sheet = Image.new("RGB", (W, H), (12, 15, 20))
    dr = ImageDraw.Draw(sheet)
    f = font(17)
    fs = font(12)
    dr.text((10, 8), "卡面 v8 标定 · 行=卡 · 列=方案", fill=(232, 202, 142), font=f)
    for c, (card, row) in enumerate(tiles):
        y = 44 + 10 + c * (th + LABEL_H + 10)
        for i, p in enumerate(row):
            x = 10 + i * (TILE_W + 10)
            dr.text((x + 2, 22), recipes[i], fill=(200, 200, 205), font=fs)
            if not p:
                dr.text((x + 10, y + th // 2), "缺失", fill=(180, 80, 80), font=f)
                continue
            sheet.paste(tile(p), (x, y))
            st = stats(Image.open(p))
            dr.text((x + 2, y + th + 2), card, fill=(232, 202, 142), font=fs)
            dr.text((x + 2, y + th + 16),
                    "sat %.2f lum %.2f" % (st["saturation"], st["luminance"]),
                    fill=(150, 150, 155), font=fs)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, out_name)
    sheet.save(path, "PNG")
    print(path)
    return path


def flat(paths, cols=6, title="", out_name="flat_sheet.png", tw=300):
    if not paths:
        print("没有可用的图")
        return None
    cols = min(cols, len(paths))
    th = tile(paths[0], tw).height
    rows = (len(paths) + cols - 1) // cols
    W = tw * cols + 8 * (cols + 1)
    H = (th + LABEL_H) * rows + 8 * (rows + 1) + 40
    sheet = Image.new("RGB", (W, H), (12, 15, 20))
    dr = ImageDraw.Draw(sheet)
    dr.text((10, 8), title, fill=(232, 202, 142), font=font(18))
    for i, p in enumerate(paths):
        x = 8 + (i % cols) * (tw + 8)
        y = 40 + 8 + (i // cols) * (th + LABEL_H)
        sheet.paste(tile(p, tw), (x, y))
        name = os.path.splitext(os.path.basename(p))[0]
        st = stats(Image.open(p))
        dr.text((x + 2, y + th + 2), name, fill=(232, 202, 142), font=font(13))
        dr.text((x + 2, y + th + 16), "sat %.2f lum %.2f" % (st["saturation"], st["luminance"]),
                fill=(150, 150, 155), font=font(11))
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, out_name)
    sheet.save(out, "PNG")
    print(out)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", default="probe")
    ap.add_argument("--cards", default="")
    ap.add_argument("--recipes", default="A,B,C,D")
    ap.add_argument("--seeds", type=int, default=1)
    ap.add_argument("--dir", default="")
    ap.add_argument("--glob", default="*.png")
    ap.add_argument("--cols", type=int, default=6)
    ap.add_argument("--title", default="")
    ap.add_argument("--tile", type=int, default=300)
    ap.add_argument("--out", default="")
    args = ap.parse_args()

    if args.dir:
        import glob as _g
        paths = sorted(_g.glob(os.path.join(args.dir, args.glob)))
        flat(paths, args.cols, args.title or args.dir, args.out or "flat_sheet.png", args.tile)
    else:
        cards = [c.strip() for c in args.cards.split(",") if c.strip()]
        recipes = [r.strip() for r in args.recipes.split(",") if r.strip()]
        matrix(args.stage, cards, recipes, args.seeds, args.out or "probe_matrix.png")


if __name__ == "__main__":
    main()

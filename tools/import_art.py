# -*- coding: utf-8 -*-
"""
把一张原始图处理成游戏里能直接用的 WebP。

用法：
  python tools/import_art.py 源图.png --kind vocation --name 阿喀琉斯
  python tools/import_art.py 源图.png --kind enemy --name serpent
  python tools/import_art.py 源图.png --kind battle --name bg_battle_6
  python tools/import_art.py 源图.png --kind node --name wealth
  python tools/import_art.py 源图.png --kind card --name poison
  python tools/import_art.py 源图.png --kind hero --name 西西弗斯

kind 对应：
  vocation 670x893   职业立绘
  hero     670x893   英雄立绘
  enemy     512x682  敌人立绘（透明底）
  battle   2048x1089 战斗背景
  node      128x128  地图图标（透明底）
  card      512x512  卡面插图（透明底）
  story    2072x1113 剧情插图
  map      2048x1089 地图底图
"""
import argparse, os, sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "assets", "art")

SPECS = {
    "vocation": ("vocation", 670, 893, False),
    "hero":     ("hero",     670, 893, False),
    "enemy":    ("enemy",    512, 682,  True),
    "battle":   ("bg",       2048, 1089, False),
    "node":     ("node",     128, 128,  True),
    "card":     ("card",     512, 512,  True),
    "story":    ("story",    2072, 1113, False),
    "map":      ("bg",       2048, 1089, False),
}


def fit(im, w, h, keep_alpha):
    """按 cover 裁切到目标比例，再缩放到目标尺寸。"""
    sw, sh = im.size
    target = w / h
    src = sw / sh
    if src > target:
        # 太宽，切左右
        nw = int(sh * target)
        x = (sw - nw) // 2
        im = im.crop((x, 0, x + nw, sh))
    else:
        # 太高，切上下
        nh = int(sw / target)
        y = (sh - nh) // 2
        im = im.crop((0, y, sw, y + nh))
    resample = Image.LANCZOS
    im = im.resize((w, h), resample)
    if not keep_alpha and im.mode == "RGBA":
        bg = Image.new("RGB", im.size, (29, 49, 67))  # 夜空色兜底
        bg.paste(im, mask=im.split()[-1])
        im = bg
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("--kind", required=True, choices=list(SPECS.keys()))
    ap.add_argument("--name", required=True, help="目标文件名（不含 .webp）")
    ap.add_argument("--quality", type=int, default=88)
    ap.add_argument("--no-crop", action="store_true", help="不裁切，直接拉伸到目标尺寸")
    a = ap.parse_args()

    if not os.path.isfile(a.src):
        sys.exit("找不到源文件: " + a.src)

    sub, w, h, alpha = SPECS[a.kind]
    out_dir = os.path.join(ART, sub)
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, a.name + ".webp")

    im = Image.open(a.src)
    if im.mode not in ("RGB", "RGBA"):
        im = im.convert("RGBA")

    if a.no_crop:
        im = im.resize((w, h), Image.LANCZOS)
    else:
        im = fit(im, w, h, alpha)

    im.save(out, "WEBP", quality=a.quality, method=6)
    kb = os.path.getsize(out) / 1024
    print("✅ %s" % out)
    print("   %d x %d  %.1f KB" % (w, h, kb))
    print()
    print("   回 Godot 会自动导入。如果没变，删掉同名的 .import 再重开。")


main()

# -*- coding: utf-8 -*-
"""画一个骷髅剪影当草图，给 img2img 用（只保留骷髅 + 雾）

用法：
  python tools/sketch_skull.py <输出> [--w 0.34 --cy 0.52]
"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 1024, 576
CREAM = (238, 230, 212, 255)
DARK = (20, 27, 36, 255)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dst")
    ap.add_argument("--w", type=float, default=0.34)
    ap.add_argument("--cy", type=float, default=0.52)
    args = ap.parse_args()

    rng = np.random.default_rng(1)
    base = np.full((H, W, 3), 0.10, np.float32)
    base += (rng.random((H, W, 1)) * 0.03).astype(np.float32)
    im = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8)).convert("RGBA")

    S = 3
    layer = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)
    cx, cy = W * S * 0.5, H * S * args.cy
    rw, rh = W * S * args.w * 0.5, H * S * args.w * 0.62

    # 颅骨
    dr.ellipse([cx - rw, cy - rh * 1.02, cx + rw, cy + rh * 0.62], fill=CREAM)
    # 下颌
    dr.polygon([
        (cx - rw * 0.72, cy + rh * 0.42),
        (cx + rw * 0.72, cy + rh * 0.42),
        (cx + rw * 0.52, cy + rh * 0.92),
        (cx - rw * 0.52, cy + rh * 0.92),
    ], fill=CREAM)
    dr.ellipse([cx - rw * 0.55, cy + rh * 0.62, cx + rw * 0.55, cy + rh * 0.95], fill=CREAM)
    # 眼窝
    for sx in (-1, 1):
        ex = cx + sx * rw * 0.40
        ey = cy - rh * 0.10
        dr.ellipse([ex - rw * 0.26, ey - rh * 0.24, ex + rw * 0.26, ey + rh * 0.26], fill=DARK)
    # 鼻腔
    dr.polygon([(cx, cy + rh * 0.16), (cx - rw * 0.12, cy + rh * 0.40), (cx + rw * 0.12, cy + rh * 0.40)], fill=DARK)
    # 牙
    ty0, ty1 = cy + rh * 0.52, cy + rh * 0.80
    n = 9
    for i in range(n):
        x = cx - rw * 0.44 + i * (rw * 0.88 / n)
        dr.rectangle([x, ty0, x + rw * 0.055, ty1], fill=DARK)
    dr.line([(cx - rw * 0.46, (ty0 + ty1) / 2), (cx + rw * 0.46, (ty0 + ty1) / 2)], fill=DARK, width=int(S * 2))

    layer = layer.resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2))
    out = im.copy()
    out.alpha_composite(layer)
    os.makedirs(os.path.dirname(os.path.abspath(args.dst)), exist_ok=True)
    out.convert("RGB").save(args.dst, "PNG")
    print("skull sketch:", args.dst)


if __name__ == "__main__":
    main()

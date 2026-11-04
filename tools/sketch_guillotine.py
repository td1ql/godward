# -*- coding: utf-8 -*-
"""画一台断头台剪影当草图，给 img2img 用"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 1024, 576
WOOD = (150, 140, 120, 255)
WOOD_D = (90, 84, 72, 255)
STEEL = (225, 228, 230, 255)
STEEL_D = (120, 128, 136, 255)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dst")
    ap.add_argument("--cx", type=float, default=0.5)
    ap.add_argument("--cy", type=float, default=0.62)
    args = ap.parse_args()

    rng = np.random.default_rng(2)
    base = np.full((H, W, 3), 0.10, np.float32)
    base += (rng.random((H, W, 1)) * 0.03).astype(np.float32)
    im = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8)).convert("RGBA")

    S = 2
    layer = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)
    cx, cy = W * S * args.cx, H * S * args.cy
    w = W * S * 0.30          # 总宽
    h = H * S * 0.62          # 总高
    top = cy - h * 0.62
    base_y = cy + h * 0.38
    post_w = w * 0.07

    # 平台
    dr.rectangle([cx - w * 0.62, base_y - h * 0.06, cx + w * 0.62, base_y], fill=WOOD, outline=WOOD_D, width=4)
    # 两根立柱
    dr.rectangle([cx - w * 0.46, top, cx - w * 0.46 + post_w, base_y - h * 0.06], fill=WOOD, outline=WOOD_D, width=4)
    dr.rectangle([cx + w * 0.46 - post_w, top, cx + w * 0.46, base_y - h * 0.06], fill=WOOD, outline=WOOD_D, width=4)
    # 顶梁
    dr.rectangle([cx - w * 0.5, top, cx + w * 0.5, top + h * 0.07], fill=WOOD, outline=WOOD_D, width=4)
    # 铡刀：斜刃
    blade_top = top + h * 0.10
    blade_bot = top + h * 0.40
    dr.polygon([
        (cx - w * 0.42, blade_top),
        (cx + w * 0.42, blade_top),
        (cx + w * 0.42, blade_bot - h * 0.10),
        (cx - w * 0.42, blade_bot),
    ], fill=STEEL, outline=STEEL_D, width=4)
    # 刀刃高光
    dr.line([(cx - w * 0.42, blade_bot), (cx + w * 0.42, blade_bot - h * 0.10)], fill=(255, 255, 255, 240), width=5)
    # 绳
    dr.line([(cx, top + h * 0.02), (cx, blade_top)], fill=WOOD_D, width=4)
    # 颈托
    dr.rectangle([cx - w * 0.18, base_y - h * 0.16, cx + w * 0.18, base_y - h * 0.06], fill=WOOD, outline=WOOD_D, width=4)
    dr.ellipse([cx - w * 0.09, base_y - h * 0.15, cx + w * 0.09, base_y - h * 0.07], fill=(20, 26, 34, 255))

    layer = layer.resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.0))
    out = im.copy()
    out.alpha_composite(layer)
    os.makedirs(os.path.dirname(os.path.abspath(args.dst)), exist_ok=True)
    out.convert("RGB").save(args.dst, "PNG")
    print("guillotine sketch:", args.dst)


if __name__ == "__main__":
    main()

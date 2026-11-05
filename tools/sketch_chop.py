# -*- coding: utf-8 -*-
"""画一个“双手举刀、向下劈”的火柴人草图，给 img2img 用"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 1024, 576
BODY = (170, 165, 155, 255)
BODY_D = (90, 88, 84, 255)
BLADE = (245, 245, 240, 255)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dst")
    ap.add_argument("--cx", type=float, default=0.44)
    args = ap.parse_args()

    rng = np.random.default_rng(4)
    base = np.full((H, W, 3), 0.10, np.float32)
    base += (rng.random((H, W, 1)) * 0.03).astype(np.float32)
    im = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8)).convert("RGBA")

    S = 2
    layer = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)
    cx = W * S * args.cx
    head = (cx, H * S * 0.26, W * S * 0.055)          # x, y, r
    neck_y = H * S * 0.33
    hip_y = H * S * 0.60
    ground = H * S * 0.86

    # 头
    dr.ellipse([head[0] - head[2], head[1] - head[2], head[0] + head[2], head[1] + head[2]], fill=BODY)
    # 躯干
    dr.polygon([
        (cx - W * S * 0.055, neck_y), (cx + W * S * 0.055, neck_y),
        (cx + W * S * 0.045, hip_y), (cx - W * S * 0.045, hip_y),
    ], fill=BODY)
    # 腿（大跨步）
    dr.line([(cx, hip_y), (cx - W * S * 0.11, ground)], fill=BODY, width=int(H * S * 0.055))
    dr.line([(cx, hip_y), (cx + W * S * 0.12, ground)], fill=BODY, width=int(H * S * 0.055))
    # 双臂举过头顶
    hand = (cx + W * S * 0.02, H * S * 0.12)
    dr.line([(cx - W * S * 0.05, neck_y + H * S * 0.02), hand], fill=BODY, width=int(H * S * 0.045))
    dr.line([(cx + W * S * 0.05, neck_y + H * S * 0.02), hand], fill=BODY, width=int(H * S * 0.045))
    # 刀：从手斜向下劈到地面
    tip = (cx + W * S * 0.26, ground)
    dr.line([hand, tip], fill=BLADE, width=int(H * S * 0.022))
    dr.line([hand, tip], fill=(255, 255, 255, 255), width=int(H * S * 0.008))
    # 刀柄
    dr.line([(hand[0] - W * S * 0.03, hand[1] - H * S * 0.005), hand], fill=BODY_D, width=int(H * S * 0.03))

    layer = layer.resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.5))
    out = im.copy()
    out.alpha_composite(layer)
    os.makedirs(os.path.dirname(os.path.abspath(args.dst)), exist_ok=True)
    out.convert("RGB").save(args.dst, "PNG")
    print("chop sketch:", args.dst)


if __name__ == "__main__":
    main()

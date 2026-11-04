# -*- coding: utf-8 -*-
"""在底图上画一个行囊的轮廓，给 img2img 当草图

用法：
  python tools/sketch_pack.py <底图> <输出> [--x 0.04 --y 0.52 --w 0.30 --h 0.40]
坐标/尺寸都是相对值；默认画在左下前景。
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFilter

CREAM = (242, 226, 202, 235)
EDGE = (30, 40, 52, 200)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--x", type=float, default=0.04)
    ap.add_argument("--y", type=float, default=0.50)
    ap.add_argument("--w", type=float, default=0.30)
    ap.add_argument("--h", type=float, default=0.42)
    args = ap.parse_args()

    im = Image.open(args.src).convert("RGB")
    W, H = im.size
    x0, y0 = args.x * W, args.y * H
    w, h = args.w * W, args.h * H
    x1, y1 = x0 + w, y0 + h

    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)

    # 包身：圆角方袋
    dr.rounded_rectangle([x0, y0 + h * 0.22, x1, y1], radius=w * 0.18, fill=CREAM, outline=EDGE, width=3)
    # 袋盖：上面一条弧形
    dr.rounded_rectangle([x0 - w * 0.04, y0 + h * 0.10, x1 + w * 0.04, y1 - h * 0.45],
                         radius=w * 0.14, fill=CREAM, outline=EDGE, width=3)
    # 铺盖卷：顶部横着的圆柱
    dr.rounded_rectangle([x0 - w * 0.06, y0, x1 + w * 0.06, y0 + h * 0.18],
                         radius=h * 0.09, fill=CREAM, outline=EDGE, width=3)
    # 两条竖背带
    for fx in (0.26, 0.70):
        bx = x0 + w * fx
        dr.rectangle([bx - w * 0.03, y0 + h * 0.12, bx + w * 0.03, y1 - h * 0.02],
                     fill=(60, 72, 88, 210), outline=EDGE, width=2)
    # 横扣带
    dr.rectangle([x0 + w * 0.08, y0 + h * 0.52, x1 - w * 0.08, y0 + h * 0.60],
                 fill=(60, 72, 88, 210), outline=EDGE, width=2)

    layer = layer.filter(ImageFilter.GaussianBlur(0.8))
    out = im.convert("RGBA")
    out.alpha_composite(layer)
    os.makedirs(os.path.dirname(os.path.abspath(args.dst)), exist_ok=True)
    out.convert("RGB").save(args.dst, "PNG")
    print("sketch:", args.dst, out.size)


if __name__ == "__main__":
    main()

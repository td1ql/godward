# -*- coding: utf-8 -*-
"""在底图上画一条飘带轮廓，给 img2img 当草图

用法：
  python tools/sketch_ribbon.py <底图> <输出> [起点x,y 控制1x,y 控制2x,y 终点x,y] [--width 40]
坐标用 0-1 的相对值。
"""
import argparse
import math
import os

from PIL import Image, ImageDraw, ImageFilter

RIBBON = (242, 226, 202, 235)


def bezier(p0, p1, p2, p3, t):
    mt = 1 - t
    x = mt**3 * p0[0] + 3 * mt**2 * t * p1[0] + 3 * mt * t**2 * p2[0] + t**3 * p3[0]
    y = mt**3 * p0[1] + 3 * mt**2 * t * p1[1] + 3 * mt * t**2 * p2[1] + t**3 * p3[1]
    return x, y


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("pts", nargs="*", type=float, default=[])
    ap.add_argument("--width", type=float, default=46)
    ap.add_argument("--attached", action="store_true",
                    help="飘带从身上长出来：起点细、中段宽、末端收尖")
    args = ap.parse_args()

    im = Image.open(args.src).convert("RGB")
    W, H = im.size
    if len(args.pts) != 8:
        pts = [(0.24, 0.52), (0.42, 0.78), (0.72, 0.10), (0.99, 0.30)]
    else:
        v = args.pts
        pts = [(v[0], v[1]), (v[2], v[3]), (v[4], v[5]), (v[6], v[7])]
    pts = [(x * W, y * H) for x, y in pts]

    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)
    n = 220
    prev = None
    for i in range(n + 1):
        t = i / n
        p = bezier(pts[0], pts[1], pts[2], pts[3], t)
        if args.attached:
            w = args.width * (0.22 + 0.78 * math.sin(math.pi * t)) * (1.0 - 0.45 * t)
        else:
            # 宽度：起点粗、末端细，中段有一点收放
            w = args.width * (1.0 - 0.75 * t) * (0.75 + 0.25 * math.sin(t * math.pi * 2.2))
        if prev is not None:
            dr.line([prev, p], fill=RIBBON, width=max(2, int(w)))
        dr.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=RIBBON)
        prev = p

    if args.attached:
        # 起点画一个“结”，让飘带像是系在腰上
        kx, ky = pts[0]
        dr.ellipse([kx - 9, ky - 9, kx + 9, ky + 9], fill=RIBBON)

    # 再补两条细的尾丝，让模型有“布”的方向感
    for k in (-1, 1):
        prev = None
        for i in range(n + 1):
            t = i / n
            p = bezier(pts[0], pts[1], pts[2], pts[3], t)
            off = math.sin(t * math.pi) * args.width * 0.9 * k
            p = (p[0], p[1] + off)
            if prev is not None:
                dr.line([prev, p], fill=(242, 226, 202, 120), width=2)
            prev = p

    layer = layer.filter(ImageFilter.GaussianBlur(1.2))
    out = im.convert("RGBA")
    out.alpha_composite(layer)
    out = out.convert("RGB")
    os.makedirs(os.path.dirname(os.path.abspath(args.dst)), exist_ok=True)
    out.save(args.dst, "PNG")
    print("sketch:", args.dst, out.size)


if __name__ == "__main__":
    main()

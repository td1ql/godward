# -*- coding: utf-8 -*-
"""在底图上叠一层可控黑雾（保留脸部）

用法：
  python tools/fog_overlay.py <底图> <输出> --strength 0.5 --face 0.42,0.30 --radius 0.10,0.12

雾由多尺度噪声生成，脸周围用高斯遮罩保护，底部更浓。
"""
import argparse
import os

import numpy as np
from PIL import Image

FOG = np.array([0.34, 0.39, 0.46], np.float32)  # 灰蓝雾，压暗处能看见层次


def smooth_noise(W, H, scale, rng):
    h = max(2, H // scale)
    w = max(2, W // scale)
    small = (rng.random((h, w)) * 255).astype(np.uint8)
    img = Image.fromarray(small).resize((W, H), Image.BICUBIC)
    return np.asarray(img).astype(np.float32) / 255.0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--strength", type=float, default=0.5)
    ap.add_argument("--face", default="0.42,0.30")
    ap.add_argument("--radius", default="0.10,0.12")
    ap.add_argument("--seed", type=int, default=3)
    args = ap.parse_args()

    im = Image.open(args.src).convert("RGB")
    W, H = im.size
    a = np.asarray(im).astype(np.float32) / 255.0
    rng = np.random.default_rng(args.seed)

    n = (0.55 * smooth_noise(W, H, 6, rng)
         + 0.30 * smooth_noise(W, H, 18, rng)
         + 0.15 * smooth_noise(W, H, 48, rng))
    n = (n - n.min()) / max(1e-6, n.max() - n.min())
    n = np.clip((n - 0.22) / 0.78, 0, 1)  # 让雾成团，不要整片灰

    fx, fy = [float(v) for v in args.face.split(",")]
    rx, ry = [float(v) for v in args.radius.split(",")]
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    protect = np.exp(-(((xx - fx * W) / (rx * W)) ** 2 + ((yy - fy * H) / (ry * H)) ** 2))
    protect = np.clip(protect, 0, 1)

    grad = 1.0 - 0.35 * (yy / H)  # 底部更浓
    alpha = args.strength * n * (1.0 - 0.85 * protect) * grad
    alpha = np.clip(alpha, 0, 0.92)[..., None]

    out = a * (1.0 - alpha) + FOG * alpha
    out = np.clip(out, 0, 1)
    os.makedirs(os.path.dirname(os.path.abspath(args.dst)), exist_ok=True)
    Image.fromarray((out * 255).round().astype(np.uint8)).save(args.dst, "PNG")
    print("fog:", args.dst, "strength", args.strength)


if __name__ == "__main__":
    main()

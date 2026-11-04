# -*- coding: utf-8 -*-
"""卡面 v8「墨色」统一调色

把生成图压成参考图那套：深夜蓝黑 #1B2B3B / 奶油 #F2E2CA 双色、暗场、低饱和、
椭圆暗角、纸纹颗粒。

参数说明：
  keep     : 保留原色比例（0=纯双色映射，1=原图）；默认 0.15
  exposure : 映射前整体曝光；默认 0.90
  gamma    : 影调 gamma，>1 压暗中间调；默认 1.12
  crush    : 暗部压黑；默认 0.02
  contrast : 最后对比度；默认 1.12
  vignette : 暗角强度 0~1；默认 0.35
  grain    : 颗粒 sigma（0~255 刻度）；默认 2.0

用法：
  python tools/grade_v8.py <输入图> <输出图>
  python tools/grade_v8.py --selftest
"""
import os
import sys

import numpy as np
from PIL import Image, ImageEnhance

SHADOW = np.array([0x1B / 255.0, 0x2B / 255.0, 0x3B / 255.0], np.float32)  # #1B2B3B
HIGH = np.array([0xF2 / 255.0, 0xE2 / 255.0, 0xCA / 255.0], np.float32)    # #F2E2CA

LUM_W = np.array([0.299, 0.587, 0.114], np.float32)


def _smoothstep(a, b, x):
    t = np.clip((x - a) / max(b - a, 1e-6), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def grade(im, keep=0.15, exposure=0.90, gamma=1.12, crush=0.02,
          contrast=1.12, vignette=0.35, grain=2.0, seed=7):
    im = im.convert("RGB")
    w, h = im.size
    keep = float(keep)
    a = np.asarray(im).astype(np.float32) / 255.0
    lum = (a * LUM_W).sum(-1)

    t = np.clip(lum * exposure, 0.0, 1.0) ** gamma
    mapped = SHADOW * (1.0 - t[..., None]) + HIGH * t[..., None]

    out = a * keep + mapped * (1.0 - keep)
    out = np.clip((out - crush) / (1.0 - crush), 0.0, 1.0)

    if vignette > 0:
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        cx, cy = w * 0.5, h * 0.45
        r = np.sqrt(((xx - cx) / (w * 0.5)) ** 2 + ((yy - cy) / (h * 0.5)) ** 2) / np.sqrt(2.0)
        v = 1.0 - vignette * _smoothstep(0.45, 1.0, r)
        out *= v[..., None]

    if grain > 0:
        rng = np.random.default_rng(seed)
        n = rng.normal(0.0, grain / 255.0, (h, w)).astype(np.float32)
        out = out + n[..., None]

    out = np.clip(out, 0.0, 1.0)
    res = Image.fromarray((out * 255.0).round().astype(np.uint8))
    if contrast and abs(contrast - 1.0) > 1e-3:
        res = ImageEnhance.Contrast(res).enhance(contrast)
    return res


def stats(im):
    a = np.asarray(im.convert("RGB").resize((256, 256), Image.LANCZOS)).astype(np.float32) / 255.0
    px = a.reshape(-1, 3)
    return {
        "saturation": float((px.max(1) - px.min(1)).mean()),
        "luminance": float((px * LUM_W).sum(1).mean()),
    }


def _selftest():
    # 模拟一张「大面积暗底 + 一小块高光」的卡面，而不是均匀渐变
    yy, xx = np.mgrid[0:256, 0:512].astype(np.float32)
    blob = np.exp(-(((xx - 260) / 90.0) ** 2 + ((yy - 110) / 70.0) ** 2))
    lum = 0.16 + 0.72 * blob
    rgb = np.stack([lum * 0.92, lum * 0.96, lum], -1)
    g = (rgb * 255).clip(0, 255).astype(np.uint8)
    out = grade(Image.fromarray(g), grain=0, vignette=0)
    st = stats(out)
    print("selftest:", st)
    assert 0.04 < st["saturation"] < 0.16, st
    assert 0.18 < st["luminance"] < 0.42, st
    print("OK")


def main():
    if "--selftest" in sys.argv:
        return _selftest()
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    src, dst = sys.argv[1], sys.argv[2]
    im = Image.open(src)
    out = grade(im)
    os.makedirs(os.path.dirname(os.path.abspath(dst)), exist_ok=True)
    out.save(dst, "PNG")
    print(os.path.basename(dst), stats(out))


if __name__ == "__main__":
    main()

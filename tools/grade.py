# -*- coding: utf-8 -*-
"""把生成图调成职业立绘那套「青灰单色 + 奶油高光」"""
import numpy as np
from PIL import Image, ImageEnhance

SHADOW = np.array([0.26, 0.33, 0.42], np.float32)   # 深青灰
HIGH = np.array([0.96, 0.93, 0.83], np.float32)     # 奶油


def grade(im, keep=0.38, crush=0.05, contrast=1.08):
    """keep: 保留多少原色（0=纯单色，1=原图）"""
    im = im.convert("RGB")
    a = np.asarray(im).astype(np.float32) / 255.0
    lum = a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114
    gray = np.stack([lum] * 3, axis=-1)
    a = gray * (1.0 - keep) + a * keep
    t = lum[..., None]
    a = a * 0.62 + (SHADOW * (1.0 - t) + HIGH * t) * 0.38
    a = np.clip((a - crush) / (1.0 - crush), 0.0, 1.0)
    out = Image.fromarray((a * 255).clip(0, 255).astype(np.uint8))
    return ImageEnhance.Contrast(out).enhance(contrast)

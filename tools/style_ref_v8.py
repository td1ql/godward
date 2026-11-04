# -*- coding: utf-8 -*-
"""卡面 v8「墨色」参考图预处理

输入：一张竖版参考图（默认用户提供的 锻铁之神 图，右下角有豆包水印）
输出：
  tools/ref/v8_style_ref.png    裁掉底部水印后的风格参考（长边 1024）
  tools/ref/v8_style_tex.png    只取画法/墨色的纹理裁切（无脸无手，防串姿势）
  tools/ref/v8_palette.json     参考色板 + 指标（给调色 / QC 用）
  C:\\ComfyUI\\input\\v8_style_ref.png / v8_style_tex.png   给 LoadImage 用

用法：
  python tools/style_ref_v8.py
  python tools/style_ref_v8.py <源图> [--copy-to-comfy]
"""
import json
import os
import shutil
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF_DIR = os.path.join(ROOT, "tools", "ref")
COMFY_INPUT = r"C:\ComfyUI\input"

DEFAULT_SRC = (
    r"C:\Users\td1ql\.dsh\attachments\v1\objects"
    r"\f3\f39736329e675ead0cec2eac5ba6d5fc29e4267731b95b14d7fd366ee3dc6173"
)

# 参考图里一块「有墨、有衣褶、有溅点」的区域（相对宽高比例），不含脸和手
TEX_BOX = (0.62, 0.20, 1.00, 0.72)
WATERMARK_CUT = 0.085


def kmeans_palette(px, k=8, iters=20, seed=0):
    rng = np.random.default_rng(seed)
    c = px[rng.choice(len(px), k, replace=False)]
    lab = None
    for _ in range(iters):
        d = ((px[:, None, :] - c[None, :, :]) ** 2).sum(-1)
        lab = d.argmin(1)
        for i in range(k):
            m = lab == i
            if m.any():
                c[i] = px[m].mean(0)
    cnt = np.bincount(lab, minlength=k)
    order = np.argsort(-cnt)
    out = []
    for i in order:
        rgb = tuple(int(round(v * 255)) for v in c[i])
        out.append({"hex": "#%02X%02X%02X" % rgb, "ratio": round(float(cnt[i]) / len(px), 4)})
    return out


def stats(im):
    a = np.asarray(im.convert("RGB").resize((256, 256), Image.LANCZOS)).astype(np.float32) / 255.0
    px = a.reshape(-1, 3)
    sat = float((px.max(1) - px.min(1)).mean())
    lum = float((px * np.array([0.299, 0.587, 0.114], np.float32)).sum(1).mean())
    return {"saturation": round(sat, 4), "luminance": round(lum, 4)}


def main():
    src = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else DEFAULT_SRC
    if not os.path.exists(src):
        raise SystemExit("找不到参考图: %s" % src)
    os.makedirs(REF_DIR, exist_ok=True)

    im = Image.open(src).convert("RGB")
    w, h = im.size
    cut = int(round(h * WATERMARK_CUT))
    im = im.crop((0, 0, w, h - cut))
    im = im.resize((1024, int(round(1024 * im.height / im.width))), Image.LANCZOS)

    ref_path = os.path.join(REF_DIR, "v8_style_ref.png")
    im.save(ref_path, "PNG")

    tex = im.crop(
        (
            int(im.width * TEX_BOX[0]),
            int(im.height * TEX_BOX[1]),
            int(im.width * TEX_BOX[2]),
            int(im.height * TEX_BOX[3]),
        )
    )
    tex = tex.resize((768, 768), Image.LANCZOS)
    tex_path = os.path.join(REF_DIR, "v8_style_tex.png")
    tex.save(tex_path, "PNG")

    px = np.asarray(im.resize((256, 256), Image.LANCZOS)).astype(np.float32).reshape(-1, 3) / 255.0
    pal = kmeans_palette(px)
    meta = {
        "source": src,
        "crop": "top %.1f%% (watermark cut)" % ((1 - WATERMARK_CUT) * 100),
        "size": im.size,
        "palette": pal,
        "stats": stats(im),
        "shadow": pal[0]["hex"],
    }
    with open(os.path.join(REF_DIR, "v8_palette.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)

    if "--no-comfy" not in sys.argv:
        os.makedirs(COMFY_INPUT, exist_ok=True)
        shutil.copy2(ref_path, os.path.join(COMFY_INPUT, "v8_style_ref.png"))
        shutil.copy2(tex_path, os.path.join(COMFY_INPUT, "v8_style_tex.png"))

    print("ref  :", ref_path, im.size)
    print("tex  :", tex_path, tex.size)
    print("stats:", meta["stats"])
    print("pal  :", ", ".join("%s %.0f%%" % (p["hex"], p["ratio"] * 100) for p in pal))


if __name__ == "__main__":
    main()

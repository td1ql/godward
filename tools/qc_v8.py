# -*- coding: utf-8 -*-
"""卡面 v8 质检 / 选优 / 落盘

1) 指标：清晰度、对比、亮度、饱和、边缘、高光面积占比
2) 打分：离 v8 目标（暗场水墨、低饱和、亮脸）越近分越低
3) 选优：每张卡从多个 seed 里挑分最低的一版
4) 落盘：中心裁 16:9 → 512x288 → assets/art/cardart7/<卡名>.png

用法：
  python tools/qc_v8.py report --stage pilot
  python tools/qc_v8.py pick  --stage pilot --out assets/art/cardart7
"""
import argparse
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "art", "_src_v8")
GAME = os.path.join(ROOT, "assets", "art", "cardart7")
LUM_W = np.array([0.299, 0.587, 0.114], np.float32)
TARGET = {"sat": 0.09, "lum": 0.30, "contrast": 34.0}


def metrics(path):
    im = Image.open(path).convert("RGB")
    im = im.resize((320, int(320 * im.height / im.width)), Image.LANCZOS)
    a = np.asarray(im).astype(np.float32)
    lum = (a * LUM_W).sum(-1)
    gray = lum

    k = np.array([[0, 1, 0], [1, -4, 1], [0, 1, 0]], dtype=np.float32)
    from numpy.lib.stride_tricks import sliding_window_view
    pad = np.pad(gray, 1, mode="edge")
    win = sliding_window_view(pad, (3, 3))
    lap = (win * k).sum(axis=(2, 3))

    hsv = np.asarray(im.convert("HSV")).astype(np.float32)
    sat = float(hsv[..., 1].mean() / 255.0)
    gx = np.abs(np.diff(gray, axis=1)).mean()
    gy = np.abs(np.diff(gray, axis=0)).mean()

    return {
        "sharp": float(lap.var()),
        "contrast": float(gray.std()),
        "bright": float(gray.mean()),
        "sat": sat,
        "edge": float((gx + gy) / 255.0),
        "hi_frac": float((gray > 205).mean()),
        "dark_frac": float((gray < 18).mean()),
    }


def penalty(m):
    p = 0.0
    p += ((m["sat"] - TARGET["sat"]) / 0.045) ** 2 * 18
    p += ((m["bright"] / 255.0 - TARGET["lum"]) / 0.06) ** 2 * 28
    if m["contrast"] < 30:
        p += (30 - m["contrast"]) / 10.0 * 10
    if m["sharp"] < 110:
        p += (110 - m["sharp"]) / 110.0 * 15
    if m["edge"] < 0.015:
        p += (0.015 - m["edge"]) / 0.015 * 12
    if m["hi_frac"] > 0.10:
        p += (m["hi_frac"] - 0.10) * 90
    if m["dark_frac"] > 0.70:
        p += (m["dark_frac"] - 0.70) * 40
    return p


def scan(stage):
    base = os.path.join(SRC, stage)
    if not os.path.isdir(base):
        raise SystemExit("没有这个阶段目录: %s" % base)
    out = {}
    for card in sorted(os.listdir(base)):
        d = os.path.join(base, card)
        if not os.path.isdir(d):
            continue
        files = sorted(glob.glob(os.path.join(d, "*_g.png")))
        if not files:
            continue
        rows = []
        for f in files:
            m = metrics(f)
            rows.append({"file": f, "penalty": penalty(m), **m})
        rows.sort(key=lambda r: (r["penalty"], -r["sharp"]))
        out[card] = rows
    return out


def to_game(src, dst):
    im = Image.open(src).convert("RGB")
    w, h = im.size
    target_h = int(round(w / (16.0 / 9.0)))
    if target_h < h:
        dy = (h - target_h) // 2
        im = im.crop((0, dy, w, dy + target_h))
    im = im.resize((512, 288), Image.LANCZOS)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    im.save(dst, "PNG")


def report(stage, top=10):
    data = scan(stage)
    total = sum(len(v) for v in data.values())
    print("阶段 %s · %d 张卡 · %d 个版本" % (stage, len(data), total))
    rows = [(r["penalty"], card, r) for card, rs in data.items() for r in rs]
    rows.sort(key=lambda x: -x[0])
    print("\n最可疑 %d 个：" % min(top, len(rows)))
    for p, card, r in rows[:top]:
        print("  %5.1f  %-8s %-24s sharp %5.0f  contrast %4.1f  bright %5.1f  sat %.3f  hi %.3f  edge %.3f"
              % (p, card, os.path.basename(r["file"]),
                 r["sharp"], r["contrast"], r["bright"], r["sat"], r["hi_frac"], r["edge"]))
    best = {c: rs[0] for c, rs in data.items()}
    print("\n每卡最优的平均分：%.1f" % (sum(r["penalty"] for r in best.values()) / max(1, len(best))))
    return data


def pick(stage, out_dir=GAME, overwrite=True):
    data = scan(stage)
    os.makedirs(out_dir, exist_ok=True)
    picked = []
    for card, rows in data.items():
        best = rows[0]
        dst = os.path.join(out_dir, card + ".png")
        if overwrite or not os.path.exists(dst):
            to_game(best["file"], dst)
        picked.append({"card": card, "src": os.path.relpath(best["file"], ROOT),
                       "dst": os.path.relpath(dst, ROOT), "penalty": round(best["penalty"], 2),
                       "variants": len(rows)})
    sel = os.path.join(SRC, stage, "selection.json")
    with open(sel, "w", encoding="utf-8") as f:
        json.dump(picked, f, ensure_ascii=False, indent=2)
    print("选出 %d 张 → %s" % (len(picked), out_dir))
    print("清单:", sel)
    return picked


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["report", "pick"])
    ap.add_argument("--stage", default="pilot")
    ap.add_argument("--out", default=GAME)
    ap.add_argument("--top", type=int, default=12)
    args = ap.parse_args()
    if args.cmd == "report":
        report(args.stage, args.top)
    else:
        pick(args.stage, args.out)


if __name__ == "__main__":
    main()

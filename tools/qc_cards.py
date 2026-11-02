# -*- coding: utf-8 -*-
"""卡面质检工具：先用数值筛出「可疑」的，再人工逐张看

用法：
  python tools/qc_cards.py <素材目录> [输出图]

输出：
  · 一张按「可疑度」排序的对照图（最可疑的在左上）
  · 控制台打印每张的指标

指标：
  sharp  : 拉普拉斯方差（<120 偏糊）
  contrast: 亮度标准差（<28 偏灰/闷）
  bright : 平均亮度（<40 偏暗，>215 偏曝）
  sat    : 平均饱和度（<0.10 偏无彩）
  edge   : 边缘密度（<0.02 可能是大面积色块/崩坏）
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont


def metrics(path):
    im = Image.open(path).convert("RGB")
    im = im.resize((320, int(320 * im.height / im.width)), Image.LANCZOS)
    a = np.asarray(im).astype(np.float32)
    lum = a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114

    # 拉普拉斯方差
    k = np.array([[0, 1, 0], [1, -4, 1], [0, 1, 0]], dtype=np.float32)
    from numpy.lib.stride_tricks import sliding_window_view
    pad = np.pad(lum, 1, mode="edge")
    win = sliding_window_view(pad, (3, 3))
    lap = (win * k).sum(axis=(2, 3))
    sharp = float(lap.var())

    hsv = np.asarray(im.convert("HSV")).astype(np.float32)
    sat = float(hsv[..., 1].mean() / 255.0)

    # 边缘密度
    gx = np.abs(np.diff(lum, axis=1)).mean()
    gy = np.abs(np.diff(lum, axis=0)).mean()
    edge = float((gx + gy) / 255.0)

    return {
        "sharp": sharp,
        "contrast": float(lum.std()),
        "bright": float(lum.mean()),
        "sat": sat,
        "edge": edge,
    }


def score(m):
    """越大越可疑"""
    s = 0.0
    if m["sharp"] < 120:
        s += (120 - m["sharp"]) / 120 * 40
    if m["contrast"] < 28:
        s += (28 - m["contrast"]) / 28 * 30
    if m["bright"] < 40:
        s += (40 - m["bright"]) / 40 * 25
    if m["bright"] > 215:
        s += (m["bright"] - 215) / 40 * 25
    if m["sat"] < 0.10:
        s += (0.10 - m["sat"]) / 0.10 * 15
    if m["edge"] < 0.02:
        s += (0.02 - m["edge"]) / 0.02 * 20
    return s


def main():
    d = sys.argv[1] if len(sys.argv) > 1 else r"C:\Projects\slay-the-tower\assets\art\cardart6"
    out = sys.argv[2] if len(sys.argv) > 2 else r"C:\Users\td1ql\AppData\Local\Temp\qc_sheet.png"
    files = sorted(f for f in os.listdir(d) if f.lower().endswith(".png"))
    if not files:
        print("目录里没有 png:", d)
        return

    rows = []
    for f in files:
        try:
            m = metrics(os.path.join(d, f))
        except Exception as e:
            print("读取失败", f, e)
            continue
        rows.append((score(m), f, m))
    rows.sort(key=lambda r: -r[0])

    print("共 %d 张，可疑度排序（前 30）：" % len(rows))
    for s, f, m in rows[:30]:
        print("  %6.1f  %-10s sharp %6.0f  contrast %5.1f  bright %5.1f  sat %.2f  edge %.3f"
              % (s, os.path.splitext(f)[0], m["sharp"], m["contrast"], m["bright"], m["sat"], m["edge"]))
    n_bad = sum(1 for r in rows if r[0] > 20)
    print("可疑（>20 分）共 %d 张" % n_bad)

    # 画对照图
    S, COLS = 200, 8
    take = rows[: (8 * 5)]
    sheet_rows = (len(take) + COLS - 1) // COLS
    sheet = Image.new("RGB", (COLS * S + (COLS + 1) * 5, sheet_rows * (S + 24) + 5), (14, 18, 24))
    dr = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 13)
    except Exception:
        font = None
    for i, (s, f, m) in enumerate(take):
        im = Image.open(os.path.join(d, f)).convert("RGB")
        im.thumbnail((S, S), Image.LANCZOS)
        x = 5 + (i % COLS) * (S + 5)
        y = 5 + (i // COLS) * (S + 24)
        sheet.paste(im, (x + (S - im.width) // 2, y))
        if font:
            dr.text((x + 1, y + S + 2), "%s  %.0f" % (os.path.splitext(f)[0], s), fill=(230, 200, 140), font=font)
    sheet.save(out, "PNG")
    print("对照图:", out)


main()

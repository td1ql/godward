# -*- coding: utf-8 -*-
"""把生成中的图片持续同步到桌面（每 10 秒一次，直到两个目录都稳定）"""
import os, shutil, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAIRS = [
    (os.path.join(ROOT, "assets", "art", "enemy2"),
     os.path.join(os.path.expanduser("~"), "Desktop", "逐神敌人")),
    (os.path.join(ROOT, "assets", "art", "cardart"),
     os.path.join(os.path.expanduser("~"), "Desktop", "逐神卡面")),
]


def sync_once():
    total = 0
    for src, dst in PAIRS:
        if not os.path.isdir(src):
            continue
        os.makedirs(dst, exist_ok=True)
        for f in os.listdir(src):
            if not f.lower().endswith(".png"):
                continue
            s = os.path.join(src, f)
            d = os.path.join(dst, f)
            try:
                if not os.path.exists(d) or os.path.getsize(d) != os.path.getsize(s):
                    shutil.copy2(s, d)
                    total += 1
            except Exception:
                pass
    return total


def main():
    last = -1
    idle = 0
    while True:
        n = sync_once()
        e = len([f for f in os.listdir(PAIRS[0][0]) if f.endswith(".png")]) if os.path.isdir(PAIRS[0][0]) else 0
        c = len([f for f in os.listdir(PAIRS[1][0]) if f.endswith(".png")]) if os.path.isdir(PAIRS[1][0]) else 0
        print("敌人 %d/51  卡面 %d/214  (本次同步 %d)" % (e, c, n), flush=True)
        if n == 0:
            idle += 1
        else:
            idle = 0
        # 两边都齐了，或者连续 40 次（约 7 分钟）没变化就退出
        if (e >= 51 and c >= 214) or idle >= 40:
            print("同步结束", flush=True)
            break
        time.sleep(10)


main()

# -*- coding: utf-8 -*-
"""方案 A：保留 AI 画出的地面，把它压暗成接触阴影

流程：
  1. 洪水填充抠掉外围白底（跟 cutout.py 一样）
  2. 剩下的「白色区域」里，位于画面下方 45%、且面积不太小的 → 判定为「地面」
  3. 把地面压暗成 #2A323A，并向四周做渐变（越远越透明）
  4. 最后可选再叠一层柔和椭圆投影

用法：
  python tools/ground_shadow.py assets/art/enemy2 -o assets/art/enemy_cut
"""
import argparse, os
from collections import deque
from PIL import Image, ImageDraw, ImageFilter

TOL = 36
GROUND_COLOR = (42, 50, 58)      # #2A323A
GROUND_ALPHA = 200
BOTTOM_RATIO = 0.45              # 只看画面下方 45%


def near(c1, c2, tol):
    return (abs(c1[0] - c2[0]) <= tol and
            abs(c1[1] - c2[1]) <= tol and
            abs(c1[2] - c2[2]) <= tol)


def bg_color(px, w, h):
    cs = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    return tuple(sum(c[i] for c in cs) // 4 for i in range(3))


def flood_border(px, w, h, bg, tol):
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h:
            continue
        idx = y * w + x
        if seen[idx]:
            continue
        c = px[x, y]
        if c[3] == 0 or not near(c, bg, tol):
            continue
        seen[idx] = 1
        px[x, y] = (c[0], c[1], c[2], 0)
        q.append((x + 1, y))
        q.append((x - 1, y))
        q.append((x, y + 1))
        q.append((x, y - 1))


def darken_ground(px, w, h, bg):
    """把下方残留的白色区域改成深色地面"""
    y0 = int(h * (1.0 - BOTTOM_RATIO))
    ground = []
    for y in range(y0, h):
        for x in range(w):
            c = px[x, y]
            if c[3] == 0:
                continue
            if near(c, bg, TOL + 10):
                ground.append((x, y))
    if not ground:
        return 0

    # 找地面的垂直范围，做「上淡下浓」的渐变
    ys = [p[1] for p in ground]
    top, bot = min(ys), max(ys)
    span = max(1, bot - top)

    for x, y in ground:
        t = (y - top) / span                     # 0 = 地面最上沿
        a = int(GROUND_ALPHA * (0.35 + 0.65 * t))
        # 横向也做一点衰减：越靠边缘越淡
        dx = abs((x / max(1, w - 1)) - 0.5) * 2.0
        a = int(a * max(0.15, 1.0 - dx * 0.55))
        px[x, y] = (GROUND_COLOR[0], GROUND_COLOR[1], GROUND_COLOR[2], a)
    return len(ground)


def soften(im, radius=3):
    """对 alpha 做一次轻微模糊，避免地面和角色之间出现硬边"""
    r, g, b, a = im.split()
    a = a.filter(ImageFilter.GaussianBlur(radius))
    return Image.merge("RGBA", (r, g, b, a))


def process(src_path, dst_path):
    im = Image.open(src_path).convert("RGBA")
    w, h = im.size
    px = im.load()
    bg = bg_color(px, w, h)

    flood_border(px, w, h, bg, TOL)
    n = darken_ground(px, w, h, bg)
    im = soften(im, 2)

    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    out_dir = os.path.dirname(dst_path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
    im.save(dst_path, "PNG")
    return im.size, n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("-o", "--out", default="")
    a = ap.parse_args()
    src = a.src.rstrip("/\\")
    out_dir = a.out or (src + "_ground")
    ok = 0
    for f in sorted(os.listdir(src)):
        if not f.lower().endswith(".png"):
            continue
        try:
            size, n = process(os.path.join(src, f), os.path.join(out_dir, f))
            print("  OK   %-26s %dx%d  地面像素 %d" % (f, size[0], size[1], n))
            ok += 1
        except Exception as e:
            print("  FAIL %s: %s" % (f, e))
    print("\n完成 %d 张 -> %s" % (ok, out_dir))


main()

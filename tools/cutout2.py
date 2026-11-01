# -*- coding: utf-8 -*-
"""抠图 v2：连通域分析版

解决 v1 的问题：AI 会画一些「灰色矩形 / 浅色地面」，颜色和背景差得远，
普通洪水填充识别不到，结果图里留一块灰块。

做法：
  1. 从四边洪水填充，去掉外围白底
  2. 把所有「还不透明」的像素做连通域分析
  3. **面积最大的那个连通域 = 角色本体**，保留
  4. 其余连通域，如果**饱和度很低（是灰/白）** 或者 **面积很小** → 视为背景残留 → 变透明
  5. 边缘羽化，可选在脚下加椭圆投影

用法：
  python tools/cutout2.py assets/art/enemy2 -o assets/art/enemy_cut3 --shadow
"""
import argparse, os
from collections import deque
from PIL import Image, ImageDraw, ImageFilter, ImageColor

TOL = 38
FEATHER = 2
MINSAT = 0.16      # 饱和度低于这个值视为灰/白背景残留


def near(a, b, tol):
    return abs(a[0] - b[0]) <= tol and abs(a[1] - b[1]) <= tol and abs(a[2] - b[2]) <= tol


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
        i = y * w + x
        if seen[i]:
            continue
        c = px[x, y]
        if c[3] == 0 or not near(c, bg, tol):
            continue
        seen[i] = 1
        px[x, y] = (c[0], c[1], c[2], 0)
        q.append((x + 1, y))
        q.append((x - 1, y))
        q.append((x, y + 1))
        q.append((x, y - 1))


def components(px, w, h):
    """返回 [(面积, [(x,y), ...]), ...]，按面积从大到小"""
    visited = bytearray(w * h)
    comps = []
    for sy in range(h):
        for sx in range(w):
            idx = sy * w + sx
            if visited[idx]:
                continue
            if px[sx, sy][3] == 0:
                visited[idx] = 1
                continue
            q = deque([(sx, sy)])
            cells = []
            while q:
                x, y = q.popleft()
                if x < 0 or y < 0 or x >= w or y >= h:
                    continue
                i2 = y * w + x
                if visited[i2]:
                    continue
                if px[x, y][3] == 0:
                    visited[i2] = 1
                    continue
                visited[i2] = 1
                cells.append((x, y))
                q.append((x + 1, y))
                q.append((x - 1, y))
                q.append((x, y + 1))
                q.append((x, y - 1))
            if cells:
                comps.append((len(cells), cells))
    comps.sort(key=lambda t: -t[0])
    return comps


def mean_sat(px, cells):
    tot = 0.0
    n = 0
    step = max(1, len(cells) // 400)
    for i in range(0, len(cells), step):
        c = px[cells[i][0], cells[i][1]]
        mx = max(c[0], c[1], c[2])
        mn = min(c[0], c[1], c[2])
        tot += 0.0 if mx == 0 else (mx - mn) / float(mx)
        n += 1
    return tot / max(1, n)


def feather(px, w, h, bg):
    for _ in range(FEATHER):
        todo = []
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                c = px[x, y]
                if c[3] == 0:
                    continue
                a = (px[x - 1, y][3], px[x + 1, y][3], px[x, y - 1][3], px[x, y + 1][3])
                if min(a) < 40 and near(c, bg, TOL + 16):
                    todo.append((x, y))
        for x, y in todo:
            c = px[x, y]
            px[x, y] = (c[0], c[1], c[2], 120)


def add_shadow(path, alpha=140):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    sw = int(w * 0.66)
    sh = max(16, int(sw * 0.14))
    SS = 4
    big = Image.new("RGBA", (sw * SS, sh * SS), (0, 0, 0, 0))
    ImageDraw.Draw(big).ellipse([0, 0, sw * SS - 1, sh * SS - 1], fill=(0, 0, 0, alpha))
    big = big.filter(ImageFilter.GaussianBlur(max(2, sw * SS // 22)))
    shadow = big.resize((sw, sh), Image.LANCZOS)
    canvas = Image.new("RGBA", (w, h + 8), (0, 0, 0, 0))
    canvas.alpha_composite(shadow, ((w - sw) // 2, h - sh // 2))
    canvas.alpha_composite(im, (0, 0))
    canvas.save(path, "PNG")


def process(src, dst, shadow=False):
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()
    bg = bg_color(px, w, h)

    flood_border(px, w, h, bg, TOL)

    comps = components(px, w, h)
    if not comps:
        im.save(dst, "PNG")
        return im.size

    main_area = comps[0][0]
    removed = 0
    for area, cells in comps[1:]:
        sat = mean_sat(px, cells)
        # 灰/白的残留，或者很小的碎片 → 去掉
        if sat < MINSAT or area < main_area * 0.02:
            for x, y in cells:
                c = px[x, y]
                px[x, y] = (c[0], c[1], c[2], 0)
            removed += area

    feather(px, w, h, bg)

    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    d = os.path.dirname(dst)
    if d:
        os.makedirs(d, exist_ok=True)
    im.save(dst, "PNG")
    if shadow:
        add_shadow(dst)
    return Image.open(dst).size


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("-o", "--out", default="")
    ap.add_argument("--shadow", action="store_true")
    ap.add_argument("--only", default="")
    a = ap.parse_args()
    src = a.src.rstrip("/\\")
    out = a.out or (src + "_cut")
    only = set(x.strip() for x in a.only.split(",") if x.strip())
    n = 0
    for f in sorted(os.listdir(src)):
        if not f.lower().endswith(".png"):
            continue
        if only and os.path.splitext(f)[0] not in only:
            continue
        try:
            sz = process(os.path.join(src, f), os.path.join(out, f), a.shadow)
            print("  OK   %-24s %dx%d" % (f, sz[0], sz[1]))
            n += 1
        except Exception as e:
            print("  FAIL %s: %s" % (f, e))
    print("\n完成 %d 张 -> %s" % (n, out))


main()

# -*- coding: utf-8 -*-
"""批量抠图：白底 → 透明 PNG（改进版）

算法（两步，防误伤）：
  1. 从四边向内洪水填充：与角落颜色相近、且与画面边缘连通的像素变透明
  2. 再清掉「没连通到边缘、颜色是背景色、面积又小（<4%）」的封闭区域（比如两腿之间），
     大块的不动，避免吃掉角色身上的浅色部分
  3. 边缘羽化
  4. 可选：脚下加椭圆投影，让角色有「站在地上」的感觉

用法：
  python tools/cutout.py assets/art/enemy2 --shadow
  python tools/cutout.py assets/art/enemy2 -o out/ --shadow
"""
import argparse, os
from collections import deque
from PIL import Image, ImageDraw, ImageFilter

TOL = 36
FEATHER = 2
MAX_ISLAND_RATIO = 0.04


def near(c1, c2, tol):
    return (abs(c1[0] - c2[0]) <= tol and
            abs(c1[1] - c2[1]) <= tol and
            abs(c1[2] - c2[2]) <= tol)


def bg_color(px, w, h):
    cs = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    return tuple(sum(c[i] for c in cs) // 4 for i in range(3))


def flood_from_border(px, w, h, bg, tol):
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


def clear_small_islands(px, w, h, bg, tol):
    visited = bytearray(w * h)
    limit = int(w * h * MAX_ISLAND_RATIO)
    removed = 0
    for sy in range(h):
        for sx in range(w):
            idx = sy * w + sx
            if visited[idx]:
                continue
            c = px[sx, sy]
            if c[3] == 0 or not near(c, bg, tol):
                visited[idx] = 1
                continue
            comp = []
            q = deque([(sx, sy)])
            touched_border = False
            while q:
                x, y = q.popleft()
                if x < 0 or y < 0 or x >= w or y >= h:
                    continue
                i2 = y * w + x
                if visited[i2]:
                    continue
                c2 = px[x, y]
                if c2[3] == 0 or not near(c2, bg, tol):
                    continue
                visited[i2] = 1
                comp.append((x, y))
                if x == 0 or y == 0 or x == w - 1 or y == h - 1:
                    touched_border = True
                q.append((x + 1, y))
                q.append((x - 1, y))
                q.append((x, y + 1))
                q.append((x, y - 1))
            if not touched_border and 0 < len(comp) <= limit:
                for x, y in comp:
                    c3 = px[x, y]
                    px[x, y] = (c3[0], c3[1], c3[2], 0)
                removed += len(comp)
    return removed


def feather(px, w, h, bg):
    for _ in range(FEATHER):
        todo = []
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                c = px[x, y]
                if c[3] == 0:
                    continue
                a = (px[x - 1, y][3], px[x + 1, y][3], px[x, y - 1][3], px[x, y + 1][3])
                if min(a) < 40 and near(c, bg, TOL + 14):
                    todo.append((x, y))
        for x, y in todo:
            c = px[x, y]
            px[x, y] = (c[0], c[1], c[2], 110)


def add_ground_shadow(path, alpha=150):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    sw = int(w * 0.70)
    sh = max(18, int(sw * 0.15))
    SS = 4
    big = Image.new("RGBA", (sw * SS, sh * SS), (0, 0, 0, 0))
    dr = ImageDraw.Draw(big)
    dr.ellipse([0, 0, sw * SS - 1, sh * SS - 1], fill=(0, 0, 0, alpha))
    big = big.filter(ImageFilter.GaussianBlur(max(2, sw * SS // 22)))
    shadow = big.resize((sw, sh), Image.LANCZOS)

    canvas = Image.new("RGBA", (w, h + 8), (0, 0, 0, 0))
    canvas.alpha_composite(shadow, ((w - sw) // 2, h - sh // 2))
    canvas.alpha_composite(im, (0, 0))
    canvas.save(path, "PNG")


def cutout_one(src_path, dst_path, shadow=False, shadow_alpha=150):
    im = Image.open(src_path).convert("RGBA")
    w, h = im.size
    px = im.load()
    bg = bg_color(px, w, h)

    flood_from_border(px, w, h, bg, TOL)
    clear_small_islands(px, w, h, bg, TOL)
    feather(px, w, h, bg)

    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    out_dir = os.path.dirname(dst_path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
    im.save(dst_path, "PNG")
    if shadow:
        add_ground_shadow(dst_path, shadow_alpha)
    im = Image.open(dst_path)
    return im.size


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("-o", "--out", default="")
    ap.add_argument("--shadow", action="store_true")
    ap.add_argument("--shadow-alpha", type=int, default=150)
    a = ap.parse_args()

    src = a.src.rstrip("/\\")
    out_dir = a.out or (src + "_alpha")
    n = 0
    for f in sorted(os.listdir(src)):
        if not f.lower().endswith(".png"):
            continue
        s = os.path.join(src, f)
        d = os.path.join(out_dir, f)
        try:
            size = cutout_one(s, d, a.shadow, a.shadow_alpha)
            print("  OK   %-26s -> %dx%d" % (f, size[0], size[1]))
            n += 1
        except Exception as e:
            print("  FAIL %s: %s" % (f, e))
    print("\n完成 %d 张 -> %s" % (n, out_dir))


main()

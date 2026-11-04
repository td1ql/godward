# -*- coding: utf-8 -*-
"""卡面 v8 实机观感模拟

按 scripts/card_ui.gd 的常量，把 cardart7 的图拼成 150x200 的卡面（再放大 3 倍看细节）：
纸色 #EDE3C9、2px 描边、插画窗口 146x82、顶部 8px 压暗、底部 26px 渐隐、金线一圈、
左上费用圆徽、卡名 / 类型 / 效果文字。

用法：
  python tools/mock_card.py 打击,淬毒,祈祷
  python tools/mock_card.py --stage pilot --top 8
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "assets", "art", "cardart7")
DB = os.path.join(ROOT, "scripts", "card_db.gd")
SERIF = os.path.join(ROOT, "assets", "fonts", "NotoSerifCJKsc-Regular.otf")
OUT = os.path.join(ROOT, "assets", "art", "_src_v8", "sheets")

CARD_W, CARD_H, ART_H = 150, 200, 84
SCALE = 3


def parse_cards():
    text = open(DB, encoding="utf-8").read()
    cards = {}
    for m in re.finditer(r'^\t"([^"]+)": \{(.*?)\},\s*$', text, re.M):
        name, body = m.group(1), m.group(2)
        try:
            import json
            d = json.loads("{" + body + "}")
        except Exception:
            d = {}
            for k, v in re.findall(r'"(\w+)": ("[^"]*"|[\d.]+|true|false)', body):
                d[k] = v.strip('"')
        cards[name] = d
    return cards


def card_text(name, d):
    kind = d.get("kind", "action")
    cost = int(d.get("cost", 0))
    effects = []
    if int(d.get("damage", 0)) > 0:
        effects.append("%d 伤害" % int(d["damage"]))
    if int(d.get("block", 0)) > 0:
        effects.append("%d 格挡" % int(d["block"]))
    if int(d.get("heal", 0)) > 0:
        effects.append("回复 %d" % int(d["heal"]))
    if int(d.get("draw", 0)) > 0:
        effects.append("抽 %d 张" % int(d["draw"]))
    if int(d.get("self_damage", 0)) > 0:
        effects.append("受到 %d 伤害" % int(d["self_damage"]))
    for k, v in (d.get("status") or {}).items():
        effects.append("敌+%d%s" % (v, k) if v >= 0 else "敌-%d%s" % (abs(v), k))
    for k, v in (d.get("damage_per_enemy_status") or {}).items():
        effects.append("伤害 = 敌%s×%d" % (k, v))
    if d.get("clear_enemy_status"):
        effects.append("清空敌%s" % d["clear_enemy_status"])
    for k, v in (d.get("self_status") or {}).items():
        effects.append("我+%d%s" % (v, k) if v >= 0 else "我-%d%s" % (abs(v), k))
    if int(d.get("gain_energy", 0)) > 0:
        effects.append("能量 +%d" % int(d["gain_energy"]))
    if int(d.get("consume", 0)) > 0:
        effects.append("耗 %d 张" % int(d["consume"]))
    if d.get("poison_double"):
        effects.append("中毒翻倍")
    if kind == "encounter":
        tag = "[遭遇·抽到生效]"
    elif kind == "effect":
        tag = "[%d费·耗%d张]" % (cost, int(d.get("consume", 0)))
    else:
        tag = "[%d费]" % cost
    return cost, tag, " / ".join(effects) or "—"


def border_color(d):
    if d.get("divine"):
        return (71, 87, 133)
    if d.get("self_status"):
        return (112, 87, 36)
    if d.get("status"):
        return (87, 51, 112)
    if int(d.get("damage", 0)) > 0:
        return (122, 46, 38)
    return (46, 77, 56)


def rounded(size, radius=8 * SCALE, fill=(237, 227, 201), outline=(0, 0, 0), width=2 * SCALE):
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    dr.rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=fill,
                         outline=outline, width=width)
    return im


def cover(im, w, h):
    r = max(w / im.width, h / im.height)
    nw, nh = int(round(im.width * r)), int(round(im.height * r))
    im = im.resize((nw, nh), Image.LANCZOS)
    x = (nw - w) // 2
    y = (nh - h) // 2
    return im.crop((x, y, x + w, y + h))


def build_card(name, d):
    W, H = CARD_W * SCALE, CARD_H * SCALE
    bc = border_color(d)
    card = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    card.alpha_composite(rounded((W, H), fill=(237, 227, 201) + (255,), outline=bc + (255,)))

    art_path = os.path.join(ART, name + ".png")
    if not os.path.exists(art_path):
        return None
    art = Image.open(art_path).convert("RGB")
    ax0, ay0, ax1, ay1 = 2 * SCALE, 2 * SCALE, (CARD_W - 2) * SCALE, ART_H * SCALE
    aw, ah = ax1 - ax0, ay1 - ay0
    art = cover(art, aw, ah)
    card.paste(art, (ax0, ay0))

    # 顶部压暗 8px
    shade = Image.new("RGBA", (aw, 8 * SCALE), (10, 13, 18, int(0.38 * 255)))
    card.alpha_composite(shade, (ax0, ay0))

    # 底部 26px 渐隐到深色
    fade_h = 26 * SCALE
    fade = Image.new("RGBA", (aw, fade_h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fade)
    for i in range(fade_h):
        a = int(255 * (i / max(1, fade_h - 1)) ** 1.2)
        fd.line([(0, i), (aw, i)], fill=(10, 13, 18, a))
    card.alpha_composite(fade, (ax0, ay1 - fade_h))

    dr = ImageDraw.Draw(card)
    # 金线外框 + 下沿金线
    dr.rectangle([ax0, ay0, ax1 - 1, ay1 - 1], outline=(158, 133, 87, 190), width=SCALE)
    dr.line([(ax0, ay1), (ax1, ay1)], fill=(201, 168, 107, 140), width=SCALE)
    # 卡名分隔线
    dr.line([(30 * SCALE, 109 * SCALE), ((CARD_W - 30) * SCALE, 109 * SCALE)],
            fill=(184, 150, 92, 150), width=SCALE)

    cost, tag, body = card_text(name, d)
    bs = 29 * SCALE
    dr.ellipse([4 * SCALE, 4 * SCALE, 4 * SCALE + bs, 4 * SCALE + bs],
               fill=tuple(int(c * 0.82) for c in bc) + (255,))
    try:
        f_cost = ImageFont.truetype(SERIF, 18 * SCALE)
        f_name = ImageFont.truetype(SERIF, 18 * SCALE)
        f_tag = ImageFont.truetype(SERIF, 14 * SCALE)
        f_body = ImageFont.truetype(SERIF, 15 * SCALE)
    except Exception:
        f_cost = f_name = f_tag = f_body = ImageFont.load_default()

    def center(text, font, y0, y1, fill=(36, 28, 20, 255)):
        bbox = dr.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        dr.text(((W - tw) / 2, (y0 + y1) / 2 - th / 2 - bbox[1]), text, font=font, fill=fill)

    bbox = dr.textbbox((0, 0), str(cost), font=f_cost)
    dr.text(((4 * SCALE + bs / 2) - (bbox[2] - bbox[0]) / 2 - bbox[0],
             (4 * SCALE + bs / 2) - (bbox[3] - bbox[1]) / 2 - bbox[1]),
            str(cost), font=f_cost, fill=(246, 235, 209, 255))
    center(name, f_name, 88 * SCALE, 109 * SCALE)
    center(tag, f_tag, 110 * SCALE, 124 * SCALE, fill=(107, 92, 69, 255))
    # 正文自动缩字号，避免长效果文字撑出卡面（和游戏里的逻辑一致）
    size = 15
    while size > 9:
        fb = ImageFont.truetype(SERIF, size * SCALE)
        bbox = dr.textbbox((0, 0), body, font=fb)
        if bbox[2] - bbox[0] <= W - 14 * SCALE:
            break
        size -= 1
    center(body, ImageFont.truetype(SERIF, size * SCALE), 124 * SCALE, 196 * SCALE)
    return card


def main():
    global ART
    ap = argparse.ArgumentParser()
    ap.add_argument("cards", nargs="*", default=[])
    ap.add_argument("--stage", default="")
    ap.add_argument("--art-dir", default="")
    ap.add_argument("--top", type=int, default=8)
    ap.add_argument("--out", default="mock_cards.png")
    args = ap.parse_args()

    if args.art_dir:
        ART = args.art_dir
    db = parse_cards()
    names = args.cards or [n for n in db if os.path.exists(os.path.join(ART, n + ".png"))]
    if args.top:
        names = names[: args.top]
    tiles = []
    for n in names:
        c = build_card(n, db.get(n, {}))
        if c:
            tiles.append((n, c))
    if not tiles:
        raise SystemExit("cardart7 里还没有图")

    tw, th = tiles[0][1].size
    cols = min(4, len(tiles))
    rows = (len(tiles) + cols - 1) // cols
    pad = 14
    sheet = Image.new("RGB", (cols * tw + pad * (cols + 1), rows * (th + 34) + pad * (rows + 1)),
                      (24, 31, 42))
    dr = ImageDraw.Draw(sheet)
    f = ImageFont.truetype(SERIF, 20)
    for i, (n, c) in enumerate(tiles):
        x = pad + (i % cols) * (tw + pad)
        y = pad + (i // cols) * (th + 34 + pad)
        sheet.paste(c, (x, y), c)
        dr.text((x, y + th + 4), n, font=f, fill=(232, 202, 142))
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, args.out)
    sheet.save(out, "PNG")
    print(out)


if __name__ == "__main__":
    main()

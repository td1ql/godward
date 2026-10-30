# -*- coding: utf-8 -*-
"""把对话分支画成一张 PNG 思维导图（阿喀琉斯 × 16 职业）"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = r"C:\Projects\slay-the-tower"
OUT = os.path.join(ROOT, "docs", "dialogue-map.png")

# 游戏里的字体是子集化的，缺各种符号；这里直接用系统宋体
FONT_PATH = r"C:\Windows\Fonts\simsun.ttc"
if not os.path.exists(FONT_PATH):
    FONT_PATH = r"C:\Windows\Fonts\msyh.ttc"
if not os.path.exists(FONT_PATH):
    FONT_PATH = os.path.join(ROOT, "assets", "fonts", "NotoSerifCJKsc-Regular.otf")

BG = (18, 23, 30)
GOLD = (201, 168, 106)
CREAM = (233, 223, 198)
DIM = (168, 158, 136)
FAINT = (128, 120, 102)
LINE = (96, 84, 62)


def F(size):
    return ImageFont.truetype(FONT_PATH, size)


# 统一的节点结构：(文字, 子节点列表, 层级)
def N(text, *children):
    return {"t": text, "c": list(children)}


BRIDE = N(
    "等待丈夫的新娘（已写）",
    N("① t1 初见",
      N("他看见你身上的什么痕迹"),
      N("「这位小姐好像也有着一段守望的过往」"),
      N("「我能看见你眼神中的思念。」")),
    N("② 三个回答",
      N("「守望？」 → +1"),
      N("（不说话，一同守望） → +5"),
      N("「为什么？」 → +3")),
    N("③ t2 深入",
      N("「呼~」"),
      N("「我们都为一个无法放下的人而背起了一段过去」"),
      N("「我的守望或许只是片刻休憩。」")),
    N("④ 分叉",
      N("「那人是我的丈夫」 → +5 → t3a",
        N("「女士，寒冬是最无情的季节。」"),
        N("「我为你丈夫的离去而悲伤。」"),
        N("「但四季轮转…在春天继续向前吧」"),
        N("回答：「思念是风…」「再见。」"),
        N("→ 结束 · +20 好感 · +5 生命")),
      N("「那人是你的爱人吗」 → +1 → t3b（待写）"),
      N("「那人是你的亲人吗」 → +2 → t3b（待写）")),
    N("⑤ t3b 荣耀线",
      N("「唉——无妨」"),
      N("「曾经的我将荣耀视作生命」"),
      N("「而荣耀是危险的高台」"),
      N("「向荣耀与曾经发问？」 → +8"),
      N("「向他的挚友发问？」 → +10")),
)

VOCS = [
    BRIDE,
    N("失明的守钟人（待写）"), N("饥饿的朝圣者（待写）"), N("沉默的执剑人（待写）"),
    N("疯癫的先知（待写）"), N("褴褛的记账人（待写）"), N("断臂的旗手（待写）"),
    N("无名的旅人（待写）"), N("溺水的小公主（待写）"), N("焚书的疯子（待写）"),
    N("守夜的哨兵（待写）"), N("数星星的瞎子（待写）"), N("磨刀的哑巴（待写）"),
    N("收尸的妇人（待写）"), N("执棋未落的妙手（待写）"), N("等死的病人（待写）"),
]

ROW = 30           # 每行高
INDENT = 300       # 每层缩进
PAD_TOP = 132


def height(n):
    if not n["c"]:
        return ROW
    return max(ROW, sum(height(c) for c in n["c"]))


def draw(d, n, x, y, depth):
    # 文字
    if depth == 0:
        fnt, col = F(20), CREAM
    elif depth == 1:
        fnt, col = F(18), (215, 205, 180)
    elif depth == 2:
        fnt, col = F(16), DIM
    else:
        fnt, col = F(15), FAINT
    d.text((x, y + 4), n["t"], font=fnt, fill=col)

    if not n["c"]:
        return ROW

    # 子节点总高
    hs = [height(c) for c in n["c"]]
    total = sum(hs)
    # 竖线：从自己这行中点，到最后一个子节点中点
    x_line = x + INDENT - 26
    y_start = y + ROW // 2
    cy = y
    last_mid = y_start
    for c, h in zip(n["c"], hs):
        mid = cy + h // 2
        last_mid = mid
        cy += h
    d.line([(x_line, y_start), (x_line, last_mid)], fill=LINE, width=1)

    # 每个子节点：横线 + 递归
    cy = y
    for c, h in zip(n["c"], hs):
        mid = cy + h // 2
        d.line([(x_line, mid), (x + INDENT - 8, mid)], fill=LINE, width=1)
        draw(d, c, x + INDENT, cy, depth + 1)
        cy += h
    return total


def main():
    total = sum(height(v) for v in VOCS)
    W = 40 + INDENT * 5 + 40
    H = PAD_TOP + total + 50

    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)

    # 标题
    d.text((40, 22), "逐神 · 阿喀琉斯 × 16 职业", font=F(32), fill=GOLD)
    d.text((40, 70), "（已写）= 样例   ｜   （待写）= 等你填", font=F(17), fill=DIM)
    d.line([(40, 102), (W - 40, 102)], fill=LINE, width=1)

    # 根：英雄
    root = N("阿喀琉斯", *VOCS)
    root["t"] = "阿喀琉斯"
    d.text((40, PAD_TOP + 4), "阿喀琉斯", font=F(26), fill=GOLD)

    # 根到 16 个职业的竖线
    hs = [height(v) for v in VOCS]
    total_h = sum(hs)
    x_line = 40 + 150
    d.line([(x_line, PAD_TOP + 18), (x_line, PAD_TOP + total_h - ROW // 2)], fill=LINE, width=2)

    cy = PAD_TOP
    for v, h in zip(VOCS, hs):
        mid = cy + h // 2
        d.line([(x_line, mid), (40 + 160, mid)], fill=LINE, width=1)
        draw(d, v, 40 + 170, cy, 1)
        cy += h

    im.save(OUT, "PNG")
    print("✅ %s  %dx%d  %d KB" % (OUT, W, H, os.path.getsize(OUT)//1024))


main()

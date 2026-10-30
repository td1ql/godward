# -*- coding: utf-8 -*-
"""生成 XMind 原生格式 .xmind + 通用 .opml + 修好的 .mm"""
import io, os, json, zipfile, uuid, html

ROOT = r"C:\Projects\slay-the-tower"
DOCS = os.path.join(ROOT, "docs")

HEROES = ["阿喀琉斯", "赫克托耳", "奥德修斯", "赫拉克勒斯", "珀尔修斯", "忒修斯", "伊阿宋", "俄耳甫斯",
          "卡珊德拉", "美狄亚", "阿塔兰忒", "普罗米修斯", "西西弗斯", "齐格弗里德", "布伦希尔德",
          "洛基", "海姆达尔", "提尔"]

VOCATIONS = ["等待丈夫的新娘", "失明的守钟人", "饥饿的朝圣者", "沉默的执剑人",
             "疯癫的先知", "褴褛的记账人", "断臂的旗手", "无名的旅人",
             "溺水的小公主", "焚书的疯子", "守夜的哨兵", "数星星的瞎子",
             "磨刀的哑巴", "收尸的妇人", "执棋未落的妙手", "等死的病人"]

FILLED = {
    ("阿喀琉斯", "等待丈夫的新娘"): [
        ("① t1 初见", [
            "他看见你身上的什么痕迹",
            "「这位小姐好像也有着一段守望的过往」",
            "「我能看见你眼神中的思念。」",
        ]),
        ("② 三个回答", [
            "「守望？」 → +1",
            "（不说话，一同守望） → +5",
            "「为什么？」 → +3",
        ]),
        ("③ t2 深入", [
            "「呼~」",
            "「我们都为一个无法放下的人而背起了一段过去」",
            "「我的守望或许只是片刻休憩。」",
        ]),
        ("④ 分叉", [
            ("「那人是我的丈夫」 → +5 → t3a", [
                "「女士，寒冬是最无情的季节。」",
                "「我为你丈夫的离去而悲伤。」",
                "「但四季轮转…在春天继续向前吧」",
                "回答：「思念是风…」「再见。」",
                "→ 结束 · +20 好感 · +5 生命",
            ]),
            ("「那人是你的爱人吗」 → +1 → t3b（待写）", []),
            ("「那人是你的亲人吗」 → +2 → t3b（待写）", []),
        ]),
        ("⑤ t3b 荣耀线", [
            "「唉——无妨」",
            "「曾经的我将荣耀视作生命」",
            "「而荣耀是危险的高台」",
            "「向荣耀与曾经发问？」 → +8",
            "「向他的挚友发问？」 → +10",
        ]),
    ],
}

TEMPLATE = [
    "① t1 初见：他看见你身上的什么痕迹？",
    "② 三个回答：顺着问 / 沉默 / 追问原因",
    "③ t2 深入：他把哪件事说给你听？",
    "④ 分叉：一条通向专属结局，两条通向通用追问",
    "⑤ 专属结局：好感 +15~20，附带回血 / 给牌 / 掉落",
]


def build_tree():
    """返回 (label, children) 树"""
    root = ("逐神 · 英雄对话分支", [])
    for h in HEROES:
        hc = []
        for v in VOCATIONS:
            filled = FILLED.get((h, v))
            if filled:
                vc = []
                for sec, kids in filled:
                    vc.append((sec, [(k[0], [(x[0], []) for x in k[1]]) if isinstance(k, tuple) else (k, []) for k in kids]))
                hc.append((v + "（已写）", vc))
            else:
                hc.append((v + "（待写）", [(t, []) for t in TEMPLATE]))
        root[1].append((h, hc))
    return root


# ---------------- XMind 2021+ -----------------
def uid():
    return uuid.uuid4().hex[:26]


def to_xmind_topic(label, children):
    t = {"id": uid(), "class": "topic", "title": label}
    if children:
        t["children"] = {"attached": [to_xmind_topic(c[0], c[1]) for c in children]}
    if label.endswith("（已写）"):
        t["style"] = {"id": uid(), "properties": {"svg:fill": "#2b3a2f"}}
    elif label.endswith("（待写）"):
        t["style"] = {"id": uid(), "properties": {"svg:fill": "#2a2f38"}}
    return t


def write_xmind(path):
    root = build_tree()
    content = [{
        "id": uid(),
        "class": "sheet",
        "title": "对话分支",
        "rootTopic": to_xmind_topic(root[0], root[1]),
    }]
    manifest = {"file-entries": {"content.json": {}, "metadata.json": {}, "Thumbnails/thumbnail.png": {}}}
    metadata = {"creator": {"name": "Godward", "version": "1.0"}}
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("content.json", json.dumps(content, ensure_ascii=False))
        z.writestr("metadata.json", json.dumps(metadata, ensure_ascii=False))
        z.writestr("manifest.json", json.dumps(manifest, ensure_ascii=False))


# ---------------- OPML -----------------
def to_opml(label, children, depth):
    ind = "  " * depth
    if not children:
        return '%s<outline text="%s"/>' % (ind, html.escape(label, quote=True))
    out = ['%s<outline text="%s">' % (ind, html.escape(label, quote=True))]
    for c in children:
        out.append(to_opml(c[0], c[1], depth + 1))
    out.append("%s</outline>" % ind)
    return "\n".join(out)


def write_opml(path):
    root = build_tree()
    body = to_opml(root[0], root[1], 3)
    doc = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head>
    <title>逐神 · 英雄对话分支</title>
  </head>
  <body>
%s
  </body>
</opml>
''' % body
    with io.open(path, "w", encoding="utf-8") as f:
        f.write(doc)


# ---------------- FreeMind -----------------
def to_mm(label, children, depth):
    ind = "  " * depth
    esc = html.escape(label, quote=True)
    if not children:
        return '%s<node TEXT="%s"/>' % (ind, esc)
    out = ['%s<node TEXT="%s">' % (ind, esc)]
    for c in children:
        out.append(to_mm(c[0], c[1], depth + 1))
    out.append("%s</node>" % ind)
    return "\n".join(out)


def write_mm(path):
    root = build_tree()
    body = to_mm(root[0], root[1], 1)
    doc = '<?xml version="1.0" encoding="UTF-8"?>\n<map version="1.0.1">\n%s\n</map>\n' % body
    with io.open(path, "w", encoding="utf-8") as f:
        f.write(doc)


def main():
    os.makedirs(DOCS, exist_ok=True)
    p1 = os.path.join(DOCS, "dialogue-map.xmind")
    p2 = os.path.join(DOCS, "dialogue-map.opml")
    p3 = os.path.join(DOCS, "dialogue-map.mm")
    write_xmind(p1)
    write_opml(p2)
    write_mm(p3)
    for p in (p1, p2, p3):
        print("✅ %s  %d KB" % (p, os.path.getsize(p) // 1024))


main()

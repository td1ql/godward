# -*- coding: utf-8 -*-
"""生成对话分支思维导图：.mm (FreeMind/XMind) + .html (markmap 预览)"""
import io, os, html

ROOT = r"C:\Projects\slay-the-tower"
OUT_MM = os.path.join(ROOT, "docs", "dialogue-map.mm")
OUT_HTML = os.path.join(ROOT, "docs", "dialogue-map.html")

HEROES = ["阿喀琉斯", "赫克托耳", "奥德修斯", "赫拉克勒斯", "珀尔修斯", "忒修斯", "伊阿宋", "俄耳甫斯",
          "卡珊德拉", "美狄亚", "阿塔兰忒", "普罗米修斯", "西西弗斯", "齐格弗里德", "布伦希尔德",
          "洛基", "海姆达尔", "提尔"]

VOCATIONS = ["等待丈夫的新娘", "失明的守钟人", "饥饿的朝圣者", "沉默的执剑人",
             "疯癫的先知", "褴褛的记账人", "断臂的旗手", "无名的旅人",
             "溺水的小公主", "焚书的疯子", "守夜的哨兵", "数星星的瞎子",
             "磨刀的哑巴", "收尸的妇人", "执棋未落的妙手", "等死的病人"]

# 阿喀琉斯 × 等待丈夫的新娘 —— 用户原作，已填好
FILLED = {
    ("阿喀琉斯", "等待丈夫的新娘"): {
        "t1": ["初见（他看见你身上的什么痕迹）",
               "他说：「这位小姐好像也有着一段守望的过往」",
               "他说：「我能看见你眼神中的思念。」"],
        "answers": [
            "「守望？」 → +1",
            "（不说话，尝试与他一同守望） → +5",
            "「为什么？」 → +3",
        ],
        "t2": ["深入（他把哪件事说给你听）",
               "他说：「呼~」",
               "他说：「我们都为一个无法放下的人而背起了一段过去」",
               "他说：「我的守望或许只是片刻休憩。」"],
        "branch": [
            ("「那人是我的丈夫」 → +5 → t3a",
             ["t3a 他说：「女士，寒冬是最无情的季节。」",
              "他说：「我为你丈夫的离去而悲伤。」",
              "他说：「但四季轮转，就让这痛苦深埋于风雪…」",
              "回答：「思念是风，我无法令它停止」「再见。」",
              "→ 结束，+20 好感，+5 生命"]),
            ("「那人是你的爱人吗」 → +1 → t3b", []),
            ("「那人是你的亲人吗」 → +2 → t3b", []),
        ],
        "t3b": ["t3b 他说：「唉——无妨」",
                "他说：「曾经的我将荣耀视作生命」",
                "他说：「而荣耀是危险的高台」",
                "回答：「向荣耀与曾经发问？」 → +8",
                "回答：「向他的挚友发问？」 → +10"],
    },
}


def build_mm() -> str:
    """FreeMind XML"""
    def node(text, children=None, extra=""):
        s = '      <node TEXT="%s"%s' % (html.escape(text, quote=True), extra)
        if not children:
            return s + "/>"
        out = [s + ">"]
        for c in children:
            out.append("        " + c)
        out.append("      </node>")
        return "\n".join(out)

    heroes_nodes = []
    for h in HEROES:
        voc_nodes = []
        for v in VOCATIONS:
            filled = FILLED.get((h, v))
            if filled:
                kids = []
                kids.append(node("① t1 初见"))
                for ln in filled["t1"]:
                    kids.append(node(ln))
                kids.append(node("② 三个回答"))
                for a in filled["answers"]:
                    kids.append(node(a))
                kids.append(node("③ t2 深入"))
                for ln in filled["t2"]:
                    kids.append(node(ln))
                kids.append(node("④ 分叉（t2 的回答）"))
                for lab, sub in filled["branch"]:
                    if sub:
                        kids.append(node(lab, [node(x) for x in sub]))
                    else:
                        kids.append(node(lab + "（待写）"))
                if "t3b" in filled:
                    kids.append(node("⑤ t3b 荣耀线"))
                    for ln in filled["t3b"]:
                        kids.append(node(ln))
                voc_nodes.append(node(v + " ✅", kids, ' FOLDED="false"'))
            else:
                voc_nodes.append(node(v + "（待写）", [
                    node("① t1 初见：他看见你身上的什么痕迹？（写在这里）"),
                    node("② 三个回答：顺着问 / 沉默 / 追问原因"),
                    node("③ t2 深入：他把哪件事说给你听？"),
                    node("④ 分叉：一条通向专属结局，两条通向通用追问"),
                    node("⑤ 专属结局：好感 +15~20，附带回血 / 给牌 / 掉落"),
                ], ' FOLDED="true"'))
        heroes_nodes.append(node(h, voc_nodes, ' FOLDED="true"'))

    body = "\n".join("    " + n for n in heroes_nodes)
    return '''<map version="1.0.1">
  <node TEXT="逐神 · 英雄对话分支（16 职业 × 18 英雄）" FOLDED="false">
    <node TEXT="使用说明" POSITION="left" FOLDED="false">
      <node TEXT="每个英雄下面有 16 个职业分支"/>
      <node TEXT="阿喀琉斯 · 等待丈夫的新娘 是已填好的样例"/>
      <node TEXT="其余写着「待写」的，点开按 ①②③④⑤ 填"/>
      <node TEXT="引擎支持：next 跳转 / end 结束 / heal 回血 / cards 给牌 / moral 道德"/>
    </node>
    <node TEXT="18 位英雄" POSITION="right" FOLDED="false">
%s
    </node>
  </node>
</map>
''' % body


def build_html() -> str:
    """markmap 预览版"""
    lines = ["# 逐神 · 英雄对话分支", ""]
    for h in HEROES:
        lines.append("- %s" % h)
        for v in VOCATIONS:
            filled = FILLED.get((h, v))
            if filled:
                lines.append("  - **%s** ✅" % v)
                lines.append("    - t1 初见")
                for ln in filled["t1"]:
                    lines.append("      - %s" % ln)
                lines.append("    - 三个回答")
                for a in filled["answers"]:
                    lines.append("      - %s" % a)
                lines.append("    - t2 深入")
                for ln in filled["t2"]:
                    lines.append("      - %s" % ln)
                lines.append("    - 分叉")
                for lab, sub in filled["branch"]:
                    lines.append("      - %s" % lab)
                    for x in sub:
                        lines.append("        - %s" % x)
                lines.append("    - t3b 荣耀线")
                for ln in filled["t3b"]:
                    lines.append("      - %s" % ln)
            else:
                lines.append("  - %s（待写）" % v)
                lines.append("    - t1 初见：他看见你身上的什么痕迹？")
                lines.append("    - 三个回答")
                lines.append("    - t2 深入")
                lines.append("    - 分叉：一条专属结局 / 两条通用")
    md = "\n".join(lines)
    return '''<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<title>逐神 · 对话分支</title>
<style>
  html,body{height:100%%;margin:0;background:#12171e}
  .markmap{width:100%%;height:100%%}
  .markmap-node text{fill:#e9dfc6}
</style>
<script src="https://cdn.jsdelivr.net/npm/markmap-autoloader@0.18"></script>
</head>
<body>
<div class="markmap">
<script type="text/template">
%s
</script>
</div>
</body>
</html>
''' % md


def main():
    os.makedirs(os.path.join(ROOT, "docs"), exist_ok=True)
    with io.open(OUT_MM, "w", encoding="utf-8") as f:
        f.write(build_mm())
    with io.open(OUT_HTML, "w", encoding="utf-8") as f:
        f.write(build_html())
    print("✅ %s" % OUT_MM)
    print("✅ %s" % OUT_HTML)


main()

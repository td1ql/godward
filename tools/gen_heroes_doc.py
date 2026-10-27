# -*- coding: utf-8 -*-
"""生成 docs/HEROES.md —— 18 位英雄的全部文案（含神话参考）"""
import re, io, os

ROOT = r"C:\Projects\slay-the-tower"
CD = os.path.join(ROOT, "scripts", "contestant_data.gd")
ND = os.path.join(ROOT, "scripts", "npc_db.gd")
OUT = os.path.join(ROOT, "docs", "HEROES.md")

HEROES = ["阿喀琉斯","赫克托耳","奥德修斯","赫拉克勒斯","珀尔修斯","忒修斯","伊阿宋","俄耳甫斯",
          "卡珊德拉","美狄亚","阿塔兰忒","普罗米修斯","西西弗斯","齐格弗里德","布伦希尔德","洛基","海姆达尔","提尔"]

MYTH = {
"阿喀琉斯": "《伊利亚特》。海洋女神忒提斯之子，出生时被浸入冥河，唯有脚踝未沾水。特洛伊战争中杀死了赫克托耳，后被帕里斯射中脚踝而死。他知道自己会早死，还是去了。",
"赫克托耳": "《伊利亚特》。特洛伊王子，守城的英雄。明知城必破，仍出城迎战阿喀琉斯。他绕城跑了三圈才停下。死后尸体被拖在战车后面。",
"奥德修斯": "《奥德赛》。伊萨卡王，献木马计攻破特洛伊。归途漂泊十年，见过独眼巨人、塞壬、冥府。最后扮成乞丐回到家里，只有老狗认得他。",
"赫拉克勒斯": "完成了十二项不可能的任务：杀涅墨亚狮、斩九头蛇、清理牛圈、取金苹果。每一件都是别人要他做的。死后升为神，但妻子误给他毒衣，他是在火堆上自己躺下的。",
"珀尔修斯": "杀美杜莎的人。借了雅典娜的盾和赫尔墨斯的镰刀，靠盾面倒影避开石化之眼。归途救下被绑在礁石上的安德洛墨达。他一生都在替别人办事。",
"忒修斯": "雅典王子。杀弥诺陶洛斯，靠阿里阿德涅的线团走出迷宫——然后把她丢在岛上。父亲见他船上挂黑帆，以为他死了，跳海而亡。那海叫爱琴海。",
"伊阿宋": "阿尔戈号船长，取金羊毛。美狄亚为他背叛父亲、杀死弟弟、杀了他的新欢和自己的孩子。他晚年孤身一人，坐在船骸下，被掉落的木头砸死。",
"俄耳甫斯": "琴声能让石头流泪。妻子欧律狄刻死后，他下冥府求情，得到允许带回她——条件是不许回头。他回头了。",
"卡珊德拉": "特洛伊公主。阿波罗爱上她，赐她预言，她不从，于是被诅咒：说真话，但没人信。她预言了城破、预言了木马，没人听。城破后被杀。",
"美狄亚": "科尔基斯公主，太阳神的后裔。为伊阿宋背叛一切，最后被他抛弃。她杀了自己的两个儿子让他痛苦。欧里庇得斯写她时，观众哭了。",
"阿塔兰忒": "弃婴，被母熊养大。跑得比任何人都快，求婚者必须跑赢她。希波墨涅斯用金苹果让她分心。她停下来捡了三次，就输了。",
"普罗米修斯": "盗火给人类，被锁在高加索山上。白天鹰来吃他的肝，夜里肝长回来。第二天鹰再来。他从不求饶，也从不闭嘴。",
"西西弗斯": "科林斯王。欺骗过死神两次，被罚推石上山。石头到顶就滚下来。他走下去，再推。加缪说：要想象西西弗斯是幸福的。",
"齐格弗里德": "《尼伯龙根之歌》。屠龙者，用龙血沐浴变得刀枪不入，但背上落了一片叶子。他忘了妻子布伦希尔德，娶了别人。最后被一枪刺在叶子落下的地方。",
"布伦希尔德": "女武神。被奥丁罚沉睡在火圈里，只有不怕火的人能唤醒她。齐格弗里德来了，又忘了她。她最后导致了整个勃艮第的灭亡。",
"洛基": "诡计之神，奥丁的结义兄弟。杀了光明神巴德尔，在诸神黄昏时掌舵冥船。他被绑在山洞里，毒蛇的毒液滴在脸上，妻子举着碗接。碗满了，他抽搐，大地就震。",
"海姆达尔": "彩虹桥的守望者。不吃不睡，能看见百里外，能听见草生长的声音。诸神黄昏时吹响号角，然后与洛基同归于尽。",
"提尔": "战神，唯一敢给巨狼芬里尔喂食的神。为了绑住狼，他把手放进狼嘴里作保。狼发现被骗，咬掉了他的手。他剩下一只手，继续当战神。",
}


def parse_contestants():
    src = open(CD, encoding="utf-8").read()
    out = {}
    for name in HEROES:
        m = re.search(r'\n\t"' + re.escape(name) + r'": \{(.*?)\n\t\},', src, re.S)
        if not m:
            out[name] = {}
            continue
        body = m.group(1)
        d = {}
        for key in ["trait", "desc", "desc3", "ally_line"]:
            mm = re.search(r'"' + key + r'": "((?:[^"\\]|\\.)*)"', body)
            if mm:
                d[key] = mm.group(1)
        # choices
        chs = []
        for cm in re.finditer(r'\{"label": "((?:[^"\\]|\\.)*)", "text": "((?:[^"\\]|\\.)*)"', body):
            chs.append((cm.group(1), cm.group(2)))
        if chs:
            d["choices"] = chs
        for k in ["kill", "spare"]:
            km = re.search(r'"' + k + r'": \{"text": "((?:[^"\\]|\\.)*)"', body)
            if km:
                d[k] = km.group(1)
        out[name] = d
    # MEET_LINES
    meet = {}
    mm = re.search(r"const MEET_LINES := \{(.*?)\n\}", src, re.S)
    if mm:
        for hm in re.finditer(r'\n\t"([^"]+)": \{(.*?)\n\t\},', mm.group(1), re.S):
            name, block = hm.group(1), hm.group(2)
            tiers = []
            for tm in re.finditer(r'"([^"]+)": \[(.*?)\]', block, re.S):
                lines = re.findall(r'"((?:[^"\\]|\\.)*)"', tm.group(2))
                tiers.append((tm.group(1), lines))
            meet[name] = tiers
    return out, meet


def parse_npcs():
    src = open(ND, encoding="utf-8").read()
    out = {}
    start = src.find("const NPCS := {")
    end = src.find("\n}\n\n\n# 按好感度")
    blk = src[start:end]
    for name in HEROES:
        m = re.search(r'\n\t"' + re.escape(name) + r'": \{(.*?)\n\t\},', blk, re.S)
        if not m:
            out[name] = {}
            continue
        body = m.group(1)
        d = {}
        for key in ["title", "greeting", "portrait"]:
            mm = re.search(r'"' + key + r'": "((?:[^"\\]|\\.)*)"', body)
            if mm:
                d[key] = mm.group(1)
        bf = re.search(r'"bond_favor": (\d+)', body)
        d["bond_favor"] = int(bf.group(1)) if bf else 45
        topics = []
        for tm in re.finditer(r'\n\t\t\t\{(.*?)\n\t\t\t\},', body, re.S):
            tb = tm.group(1)
            t = {}
            for key in ["id", "label", "action", "text"]:
                mm = re.search(r'"' + key + r'": "((?:[^"\\]|\\.)*)"', tb)
                if mm:
                    t[key] = mm.group(1)
            req = re.search(r'"requires": \{([^}]*)\}', tb)
            if req:
                t["requires"] = req.group(1)
            vl = {}
            vlm = re.search(r'"vocation_lines": \{(.*?)\n\t\t\t\t\}', tb, re.S)
            if vlm:
                for vm in re.finditer(r'"([^"]+)": "((?:[^"\\]|\\.)*)"', vlm.group(1)):
                    vl[vm.group(1)] = vm.group(2)
            t["vocations"] = vl
            resps = []
            for rm in re.finditer(r'\{"label": "((?:[^"\\]|\\.)*)", "text": "((?:[^"\\]|\\.)*)", "favor": (-?\d+)\}', tb):
                resps.append((rm.group(1), rm.group(2), int(rm.group(3))))
            t["responses"] = resps
            topics.append(t)
        d["topics"] = topics
        out[name] = d
    return out


def esc(s):
    return s.replace("\n", " ⏎ ")


def main():
    cs, meet = parse_contestants()
    ns = parse_npcs()

    L = []
    L.append("# 十八位英雄 · 文案总表")
    L.append("")
    L.append("每位英雄：**神话参考** → 现有文案 → NPC 对话数据。")
    L.append("")
    L.append("改完发我，我按这里的 **key** 反写回代码。")
    L.append("")
    L.append("| 记号 | 含义 |")
    L.append("|------|------|")
    L.append("| `⏎` | 换行 |")
    L.append("| `t1` `t2` | NPC 话题 id（存档记这个，别改）|")
    L.append("| `bond_favor` | 好感多少才能结盟 |")
    L.append("| `requires` | 话题出现条件 |")
    L.append("")

    L.append("---")
    L.append("")
    L.append("## 总览")
    L.append("")
    L.append("| 英雄 | 称号 | 神话出处 | NPC 话题数 |")
    L.append("|------|------|----------|-----------|")
    for n in HEROES:
        myth_src = MYTH.get(n, "").split("。")[0]
        L.append("| %s | %s | %s | %d |" % (n, cs.get(n, {}).get("trait", ""), myth_src, len(ns.get(n, {}).get("topics", []))))
    L.append("")

    for idx, n in enumerate(HEROES, 1):
        c = cs.get(n, {})
        x = ns.get(n, {})
        L.append("---")
        L.append("")
        L.append("## %d. %s" % (idx, n))
        L.append("")
        L.append("**称号**：%s" % c.get("trait", "（未设）"))
        L.append("")

        L.append("### 神话（参考）")
        L.append("")
        L.append(MYTH.get(n, "（待补）"))
        L.append("")

        if "desc" in c:
            L.append("### 第一幕三行（contestant_data.desc）")
            L.append("")
            L.append("```")
            L.append(c["desc"].replace("\\n", "\n"))
            L.append("```")
            L.append("")

        if "desc3" in c:
            L.append("### 第三幕三行（contestant_data.desc3）")
            L.append("")
            L.append("```")
            L.append(c["desc3"].replace("\\n", "\n"))
            L.append("```")
            L.append("")

        if "ally_line" in c:
            L.append("**决战时盟友台词**：「%s」" % c["ally_line"])
            L.append("")

        if meet.get(n):
            L.append("### 遇见台词（MEET_LINES）")
            L.append("")
            L.append("| 档 | 台词 |")
            L.append("|----|------|")
            for tier, lines in meet[n]:
                L.append("| %s | %s |" % (tier, " ／ ".join(esc(l) for l in lines)))
            L.append("")

        if c.get("choices"):
            L.append("### 第一幕选项")
            L.append("")
            L.append("| 选项 | 结果 |")
            L.append("|------|------|")
            for lab, txt in c["choices"]:
                L.append("| %s | %s |" % (lab, esc(txt)))
            L.append("")

        if "kill" in c:
            L.append("**杀死他**：%s" % esc(c["kill"]))
            L.append("")
        if "spare" in c:
            L.append("**放过他**：%s" % esc(c["spare"]))
            L.append("")

        # ---- NPC ----
        L.append("### NPC 对话（npc_db.gd）")
        L.append("")
        if not x.get("topics"):
            L.append("（还没有 NPC 数据）")
            L.append("")
            continue
        L.append("**NPC 标题**：%s" % x.get("title", ""))
        L.append("")
        L.append("**开场白**：%s" % esc(x.get("greeting", "")))
        L.append("")
        L.append("**结盟好感门槛**：`bond_favor = %d`" % x.get("bond_favor", 45))
        L.append("")

        for t in x["topics"]:
            L.append("#### `%s` %s" % (t.get("id", "?"), t.get("label", "")))
            L.append("")
            if t.get("requires"):
                L.append("**出现条件**：`%s`" % t["requires"])
                L.append("")
            L.append("**动作**：%s" % t.get("action", "（未设）"))
            L.append("")
            L.append("**默认台词**：")
            L.append("")
            L.append("```")
            L.append(t.get("text", "").replace("\\n", "\n"))
            L.append("```")
            L.append("")

            if t.get("vocations"):
                L.append("**职业专属开场白**：")
                L.append("")
                L.append("| 职业 | 台词 |")
                L.append("|------|------|")
                for v, txt in t["vocations"].items():
                    L.append("| %s | %s |" % (v, esc(txt)))
                L.append("")

            if t.get("responses"):
                L.append("**回答**：")
                L.append("")
                L.append("| 回答 | 他的回应 | 好感 |")
                L.append("|------|----------|------|")
                for lab, txt, f in t["responses"]:
                    L.append("| %s | %s | %+d |" % (lab, esc(txt), f))
                L.append("")

    with io.open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    print("写出 %s（%d 行）" % (OUT, len(L)))


main()

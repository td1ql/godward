# -*- coding: utf-8 -*-
"""生成 docs/SKILLS.md —— 16 个职业技能的总表"""
import io, os, re

ROOT = r"C:\Projects\slay-the-tower"
SRC = os.path.join(ROOT, "scripts", "skill_db.gd")
OUT = os.path.join(ROOT, "docs", "SKILLS.md")

COND_CN = {
    "no_attack_3": "连续 3 回合没有打出过攻击牌",
    "turn_min_5": "第 5 回合之后",
    "hp_below_30": "生命低于 30%",
    "block_zero": "格挡被打到 0（第 2 回合起）",
    "hand_min_6": "手牌 6 张以上",
    "damage_taken": "本场累计受过 20 点以上伤害",
    "energy_zero": "能量用完（第 2 回合起）",
    "enemy_poison": "敌人中毒 5 层以上",
}

COND_WHY = {
    "no_attack_3": "逼你走另一条路——防守、抽牌、蓄力",
    "turn_min_5": "拖到中局才给，不能开局就爆",
    "hp_below_30": "濒死时的一张底牌",
    "block_zero": "被打穿之后的反打窗口",
    "hand_min_6": "手牌攒满了才有得烧、有得选",
    "damage_taken": "挨够打之后才有的冷静",
    "energy_zero": "能量见底时的那一口气",
    "enemy_poison": "毒流成型后的收线",
}

FX_CN = {
    "guard": "护盾 / 金光",
    "bell": "钟声 / 波纹",
    "slash": "刀痕 / 斜光",
    "heal": "光点上升",
    "mind": "乱线 / 波纹",
    "ledger": "翻页 / 数字",
    "flag": "旗面 / 竖光柱",
    "water": "水波 / 下沉",
    "fire": "火焰 / 上窜",
    "star": "星点 / 连线",
    "blade": "反光 / 磨刀声",
    "chess": "落子 / 格子",
    "end": "静默 / 一黑",
    "step": "脚步 / 轻影",
}



def extract_braces(text, key):
    """从 text 里找 key 后面的 { ... }，用括号配对处理嵌套"""
    i = text.find(key)
    if i < 0:
        return ""
    j = text.find("{", i)
    if j < 0:
        return ""
    depth = 0
    for k in range(j, len(text)):
        if text[k] == "{":
            depth += 1
        elif text[k] == "}":
            depth -= 1
            if depth == 0:
                return text[j + 1:k]
    return ""


def parse():
    src = open(SRC, encoding="utf-8").read()
    start = src.find("const SKILLS := {")
    end = src.find("\n}\n\n\nfunc has")
    block = src[start:end]

    out = []
    for m in re.finditer(r'\n\t"([^"]+)": \{\n(.*?)\n\t\},', block, re.S):
        voc, body = m.group(1), m.group(2)
        d = {"voc": voc}
        for k in ["name", "en", "cond", "hint", "line", "fx"]:
            mm = re.search(r'"' + k + r'": "((?:[^"\\]|\\.)*)"', body)
            if mm:
                d[k] = mm.group(1)
        d["effect_raw"] = extract_braces(body, '"effect":')
        out.append(d)
    return out


def effect_cn(raw):
    """把 effect 字典翻译成人话（先抽掉嵌套的 status 字典，免得重复解析）"""
    import copy
    txt = raw

    def pull(field):
        nonlocal txt
        m = re.search(r'"' + field + r'": \{([^}]*)\}', txt)
        if not m:
            return ""
        inner = m.group(1)
        txt = txt.replace(m.group(0), "")
        return "、".join("%s %s" % (a, b)
                        for a, b in re.findall(r'"([^"]+)":\s*(-?\d+)', inner))

    st_all = pull("status_all")
    st_self = pull("status_self")

    parts = []
    for k, v in re.findall(r'"(\w+)":\s*([^,}]+)', txt):
        v = v.strip()
        if k == "block":
            parts.append("+%s 格挡" % v)
        elif k == "heal":
            parts.append("回复 %s 生命" % v)
        elif k == "energy":
            parts.append("+%s 能量" % v)
        elif k == "draw":
            parts.append("抽 %s 张" % v)
        elif k == "damage_all":
            parts.append("%s 伤害（全体）" % v)
        elif k == "damage_per_poison":
            parts.append("每层中毒 %s 伤害" % v)
        elif k == "damage_per_card":
            parts.append("每张手牌 %s 伤害" % v)
        elif k == "damage_self_hp_pct":
            parts.append("已损失生命的 %d%% 转伤害" % (float(v) * 100))
        elif k == "mult_next":
            parts.append("本回合攻击 ×%s" % v)
        elif k in ("burn_hand", "true"):
            if k == "burn_hand":
                parts.append("**烧掉全部手牌**")
    if st_all:
        parts.append("敌人 +" + st_all)
    if st_self:
        parts.append("自己 +" + st_self)
    return "、".join(parts)


def main():
    skills = parse()

    L = []
    L.append("# 职业技能总表")
    L.append("")
    L.append("16 个职业，每个一个专属技能。**战斗中满足条件才能用，每场一次。**")
    L.append("")
    L.append("使用时会播放演出：全屏压暗 → 金色光带掠过 → 英文大字滑入 → 中文名 → 台词逐字 → 白闪 + 抖动。")
    L.append("")

    L.append("---")
    L.append("")
    L.append("## 总览")
    L.append("")
    L.append("| 职业 | 技能 | 英文 | 触发条件 | 效果 |")
    L.append("|------|------|------|----------|------|")
    for s in skills:
        L.append("| %s | **%s** | `%s` | %s | %s |" % (
            s["voc"], s.get("name", ""), s.get("en", ""),
            COND_CN.get(s.get("cond", ""), s.get("cond", "")),
            effect_cn(s["effect_raw"])))
    L.append("")

    L.append("---")
    L.append("")
    L.append("## 逐个说明")
    L.append("")

    for i, s in enumerate(skills, 1):
        L.append("### %d. %s · %s" % (i, s["voc"], s.get("name", "")))
        L.append("")
        L.append("```")
        L.append(str(s.get("en", "")))
        L.append("```")
        L.append("")
        L.append("| 项 | 内容 |")
        L.append("|----|------|")
        L.append("| **触发** | %s |" % COND_CN.get(s.get("cond", ""), ""))
        L.append("| **为什么这样设计** | %s |" % COND_WHY.get(s.get("cond", ""), ""))
        L.append("| **效果** | %s |" % effect_cn(s["effect_raw"]))
        L.append("| **演出** | %s |" % FX_CN.get(s.get("fx", ""), s.get("fx", "")))
        L.append("")
        L.append("台词：")
        L.append("")
        L.append("> %s" % s.get("line", ""))
        L.append("")

    L.append("---")
    L.append("")
    L.append("## 触发条件的分布")
    L.append("")
    from collections import Counter
    c = Counter(s.get("cond", "") for s in skills)
    L.append("| 条件 | 数量 | 职业 |")
    L.append("|------|------|------|")
    for cond, n in c.most_common():
        who = "、".join(s["voc"] for s in skills if s.get("cond") == cond)
        L.append("| %s | %d | %s |" % (COND_CN.get(cond, cond), n, who))
    L.append("")

    L.append("---")
    L.append("")
    L.append("## 加新技能 / 改技能")
    L.append("")
    L.append("改 `scripts/skill_db.gd` 的 `SKILLS` 字典：")
    L.append("")
    L.append("```gdscript")
    L.append('"职业名": {')
    L.append('\t"name": "技能名",           // 中文，2~3 字')
    L.append('\t"en": "EN NAME",            // 英文，全大写')
    L.append('\t"cond": "no_attack_3",      // 触发条件，见下表')
    L.append('\t"hint": "连续三回合不曾出手", // 条件提示（给玩家看）')
    L.append('\t"line": "她把手放在胸口，站住了。", // 演出时的台词')
    L.append('\t"effect": {"block": 28},   // 效果')
    L.append('\t"fx": "guard",              // 演出类型')
    L.append("},")
    L.append("```")
    L.append("")
    L.append("### 可用的触发条件")
    L.append("")
    L.append("| kind | 意思 |")
    L.append("|------|------|")
    for k, v in COND_CN.items():
        L.append("| `%s` | %s |" % (k, v))
    L.append("")
    L.append("### 可用的效果字段")
    L.append("")
    L.append("| 字段 | 意思 |")
    L.append("|------|------|")
    for k, v in [
        ("block", "加格挡"), ("heal", "回血"), ("energy", "加能量"), ("draw", "抽牌"),
        ("damage_all", "对敌人造成伤害"), ("damage_per_poison", "每层中毒造成伤害"),
        ("damage_per_card", "每张手牌造成伤害"), ("damage_self_hp_pct", "按已损失生命比例造成伤害"),
        ("burn_hand", "烧掉全部手牌"), ("mult_next", "本回合攻击倍率"),
        ("status_all", "给敌人上状态"), ("status_self", "给自己上状态"),
    ]:
        L.append("| `%s` | %s |" % (k, v))
    L.append("")

    with io.open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    print("✅ %s（%d 个技能）" % (OUT, len(skills)))


main()

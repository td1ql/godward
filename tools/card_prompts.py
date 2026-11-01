# -*- coding: utf-8 -*-
"""从 card_db.gd 解析全部卡牌，按效果自动推导卡面象征物，输出 card_prompts.json

推导规则（优先级从高到低）：
  status 里有 中毒     → 毒液
  status 里有 流血     → 血
  status 里有 易伤     → 裂开的护甲
  status 里有 虚弱     → 崩塌的石像
  self_status 力量     → 握拳
  self_status 嗜血     → 染血的刀
  heal > 0            → 光 / 花
  draw > 0            → 浮空的牌
  block > 0 且 damage > 0 → 盾与刀并列
  block > 0           → 盾墙
  damage >= 20        → 重击剪影
  damage > 0          → 刀锋
  其他                → 烛火
"""
import io, json, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "scripts", "card_db.gd")
OUT = os.path.join(ROOT, "tools", "card_prompts.json")

OBJ = "obj"
SIL = "sil"

# 每张卡的额外意象（按卡名关键词补充，让同名类别的卡不完全一样）
NAME_FLAVOR = {
    "光": "faint golden light",
    "辉": "radiant golden light",
    "晨": "dawn light over cold stone",
    "夜": "moonlight through iron bars",
    "血": "dark red blood",
    "火": "rising embers and orange flame",
    "骨": "old bone fragments",
    "铁": "rusted iron chains",
    "风": "wind blown dust",
    "雨": "falling rain",
    "钟": "a cracked bronze bell",
    "镜": "a shattered mirror",
    "花": "a pale flower",
    "树": "a bare tree branch",
    "影": "a long shadow",
    " silence": "silence",
}


def parse_cards(text: str) -> dict:
    """把 CARDS 字典解析成 {卡名: {字段}}"""
    i = text.find("const CARDS := {")
    if i < 0:
        return {}
    j = text.find("{", i)
    depth = 0
    end = len(text)
    for k in range(j, len(text)):
        if text[k] == "{":
            depth += 1
        elif text[k] == "}":
            depth -= 1
            if depth == 0:
                end = k
                break
    block = text[j + 1:end]

    cards = {}
    # 只取深度 1 的 "key": {...}（status / self_status 是深度 2，要排除）
    def depth_at(pos):
        d = 0
        for k in range(0, pos):
            if block[k] == "{":
                d += 1
            elif block[k] == "}":
                d -= 1
        return d

    for m in re.finditer(r'"([^"]+)":\s*\{', block):
        if depth_at(m.start()) != 0:
            continue
        name = m.group(1)
        start = m.end() - 1
        depth = 0
        stop = len(block)
        for k in range(start, len(block)):
            if block[k] == "{":
                depth += 1
            elif block[k] == "}":
                depth -= 1
                if depth == 0:
                    stop = k
                    break
        body = block[start:stop + 1]
        d = {}
        for f in ["cost", "damage", "block", "heal", "draw", "self_damage", "consume", "hits", "price"]:
            mm = re.search(r'"' + f + r'":\s*(-?\d+)', body)
            if mm:
                d[f] = int(mm.group(1))
        for f in ["status", "self_status"]:
            mm = re.search(r'"' + f + r'":\s*\{([^}]*)\}', body)
            if mm:
                inner = {}
                for a, b in re.findall(r'"([^"]+)":\s*(-?\d+)', mm.group(1)):
                    inner[a] = int(b)
                d[f] = inner
        mm = re.search(r'"kind":\s*"([^"]+)"', body)
        if mm:
            d["kind"] = mm.group(1)
        cards[name] = d
    return cards


def build_prompt(name: str, c: dict) -> dict:
    st = c.get("status", {})
    ss = c.get("self_status", {})
    dmg = c.get("damage", 0)
    blk = c.get("block", 0)
    heal = c.get("heal", 0)
    draw = c.get("draw", 0)
    flavor = ""
    for k, v in NAME_FLAVOR.items():
        if k in name:
            flavor = ", " + v
            break

    if "中毒" in st:
        return {"kind": OBJ, "prompt": "a glass vial of black venom tipping over, dark green liquid spreading on stone" + flavor}
    if "流血" in st:
        return {"kind": OBJ, "prompt": "a thin dagger with blood dripping from the tip, dark red glow" + flavor}
    if "易伤" in st:
        return {"kind": OBJ, "prompt": "a suit of armor with a deep crack across the chest plate, dark and dented" + flavor}
    if "虚弱" in st:
        return {"kind": OBJ, "prompt": "a crumbling stone statue, half broken, dust falling" + flavor}
    if "力量" in ss:
        return {"kind": SIL, "prompt": "silhouette of a fighter clenching a fist, golden light leaking between the fingers" + flavor}
    if "嗜血" in ss:
        return {"kind": OBJ, "prompt": "a blood-stained curved blade resting on wet stone" + flavor}
    if heal > 0 and draw > 0:
        return {"kind": OBJ, "prompt": "a glowing white flower and floating pages of paper, pale light" + flavor}
    if heal > 0:
        return {"kind": OBJ, "prompt": "a small white flower blooming out of cracked ash, soft warm light" + flavor}
    if draw > 0:
        return {"kind": OBJ, "prompt": "three glowing cards floating in a spiral, edges catching fire" + flavor}
    if blk > 0 and dmg > 0:
        return {"kind": OBJ, "prompt": "a shield and a sword crossed on dark ground, faint gold glow" + flavor}
    if blk >= 20:
        return {"kind": OBJ, "prompt": "a massive wall of stacked stone blocks, glowing protective sigil" + flavor}
    if blk > 0:
        return {"kind": OBJ, "prompt": "an ancient round shield, cracked, runes glowing along the rim" + flavor}
    if dmg >= 20:
        return {"kind": SIL, "prompt": "silhouette of a warrior delivering a heavy overhead strike, dust and debris flying" + flavor}
    if dmg > 0:
        return {"kind": OBJ, "prompt": "a long curved blade slashing through the air, sparks along the edge" + flavor}
    return {"kind": OBJ, "prompt": "a single candle flame in darkness, faint smoke" + flavor}


def main():
    text = io.open(SRC, encoding="utf-8").read()
    cards = parse_cards(text)
    print("解析到 %d 张卡" % len(cards))
    out = {}
    counts = {"obj": 0, "sil": 0}
    for name, c in cards.items():
        p = build_prompt(name, c)
        out[name] = p
        counts[p["kind"]] += 1
    with io.open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print("物体 %d 张 / 剪影 %d 张" % (counts["obj"], counts["sil"]))
    print("写入", OUT)


main()

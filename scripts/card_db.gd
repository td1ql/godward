extends Node

# ===== 卡牌数据结构说明 =====
# 每张卡写法： "卡名": { 属性... }
#
# 必填字段：
#   kind   : "action"    行动牌，只消耗能量
#            "effect"    效果牌，消耗能量 + 消耗 N 张其他手牌
#            "encounter" 遭遇牌，抽到立即生效，不进手牌
#   cost   : 费用（消耗多少能量）
#   damage : 对敌人造成的伤害（0 = 不造成伤害）
#   block  : 获得的格挡（0 = 不获得）
#
# 可选字段（不写就默认 0）：
#   price       : 商店售价
#   status      : 给敌人挂的状态，如 {"中毒": 3}
#   self_status : 给自己挂的状态，如 {"力量": 2}
#   hits        : 连击段数（默认 1，2 = 伤害×2）
#   heal        : 回复 HP
#   draw        : 立刻抽牌张数
#   self_damage : 对自己造成的伤害（遭遇牌/诅咒）
#   consume     : 效果牌额外消耗的手牌数
#
# 示例：
#   "打击": {"kind": "action", "cost": 1, "damage": 6, "block": 0, "price": 30}
#   "终结": {"kind": "effect", "cost": 1, "consume": 2, "damage": 18, "block": 0, "price": 80}
#   "祝福": {"kind": "encounter", "cost": 0, "damage": 0, "block": 8, "price": 0}
# =============================

const DEFAULT_PRICE := 40

const CARDS := {
	# ===== 行动牌：只消耗能量 =====
	"打击": {"kind": "action", "cost": 1, "damage": 5, "block": 0, "price": 30},
	"防御": {"kind": "action", "cost": 1, "damage": 0, "block": 5, "price": 30},
	"重击": {"kind": "action", "cost": 1, "damage": 8, "block": 0, "price": 50},
	"铁壁": {"kind": "action", "cost": 2, "damage": 0, "block": 14, "price": 50},
	"疾风斩": {"kind": "action", "cost": 0, "damage": 4, "block": 0, "price": 55},
	"毒刃": {"kind": "action", "cost": 1, "damage": 3, "block": 0, "status": {"中毒": 3}, "price": 50},
	"力量药剂": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "self_status": {"力量": 3}, "price": 60},
	"双重打击": {"kind": "action", "cost": 1, "damage": 4, "block": 0, "hits": 2, "price": 50},
	"急救": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "heal": 6, "price": 40},
	"天降横牌": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "draw": 2, "price": 50},
	"火球": {"kind": "action", "cost": 2, "damage": 12, "block": 0, "price": 70},
	"突刺": {"kind": "action", "cost": 1, "damage": 6, "block": 0, "price": 60, "status": {"流血": 5}},
	"连斩": {"kind": "action", "cost": 1, "damage": 4, "block": 0, "hits": 2, "price": 55},
	"疾风连击": {"kind": "action", "cost": 2, "damage": 6, "block": 0, "draw": 1, "hits": 3, "price": 75},
	"血刃": {"kind": "action", "cost": 1, "damage": 12, "block": 0, "self_damage": 3, "price": 60},
	"重压": {"kind": "action", "cost": 2, "damage": 7, "block": 0, "self_damage": 5, "hits": 3, "price": 65},
	"反击": {"kind": "action", "cost": 1, "damage": 0, "block": 6, "self_status": {"力量": 2}, "price": 55},
	"蓄力": {"kind": "action", "cost": 0, "damage": 0, "block": 0, "self_status": {"力量": 3}, "self_damage": 5, "price": 55},
	"破甲": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "status": {"易伤": 2}, "price": 50},
	"破防斩": {"kind": "action", "cost": 2, "damage": 10, "block": 0, "status": {"易伤": 1}, "price": 65},
	"守护": {"kind": "action", "cost": 2, "damage": 0, "block": 14, "price": 55},
	"战吼": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "self_status": {"力量": 1}, "draw": 1, "price": 60},
	"毒牙": {"kind": "action", "cost": 1, "damage": 3, "block": 0, "status": {"中毒": 4}, "price": 55},
	"虚弱打击": {"kind": "action", "cost": 1, "damage": 5, "block": 0, "status": {"虚弱": 1}, "price": 50},
	"吸血": {"kind": "action", "cost": 1, "damage": 6, "block": 0, "heal": 6, "price": 70},
	"过载": {"kind": "action", "cost": 0, "damage": 0, "block": 0, "gain_energy": 1, "self_damage": 4, "price": 55},
	"撤退": {"kind": "action", "cost": 1, "damage": 0, "block": 10, "draw": 1, "price": 60},
	"乱击": {"kind": "action", "cost": 1, "damage": 3, "block": 0, "hits": 3, "price": 55},
	# ===== 效果牌：消耗能量 + 消耗 N 张其他手牌 =====
	"快速思考": {"kind": "effect", "cost": 0, "damage": 0, "consume": 1, "block": 0, "draw": 2, "price": 50},
	"削弱": {"kind": "effect", "cost": 0, "consume": 1, "damage": 0, "block": 0, "status": {"虚弱": 2}, "price": 50},
	"终结": {"kind": "effect", "cost": 1, "consume": 2, "damage": 18, "block": 0, "price": 80},
	"大盾": {"kind": "effect", "cost": 1, "consume": 2, "damage": 0, "block": 18, "price": 80},
	"终结技": {"kind": "effect", "cost": 2, "consume": 2, "damage": 24, "block": 0, "price": 90},
	"献身": {"kind": "effect", "cost": 1, "consume": 1, "damage": 0, "block": 12, "heal": 6, "price": 70},
	"吞噬": {"kind": "effect", "cost": 1, "consume": 2, "damage": 8, "block": 0, "heal": 8, "price": 75},
	"掘墓者": {"kind": "effect", "cost": 0, "consume": 1, "damage": 0, "block": 0, "gain_energy": 1, "retrieve_top": true, "price": 70},
	"毒雾": {"kind": "effect", "cost": 1, "consume": 1, "damage": 0, "block": 0, "status": {"中毒": 2, "虚弱": 1}, "price": 60},
	"冥想": {"kind": "effect", "cost": -1, "consume": 1, "damage": 0, "block": 0, "draw": 3, "price": 55},
	"祈祷": {"kind": "effect", "cost": 0, "consume": 1, "damage": 0, "block": 8, "heal": 4, "draw": 2, "price": 55},
	"处决": {"kind": "effect", "cost": 3, "consume": 3, "damage": 40, "block": 0, "price": 110},
	"净化": {"kind": "effect", "cost": 0, "damage": 2, "block": 0, "heal": 10, "self_damage": 0, "price": 55},
	"万钧": {"kind": "effect", "cost": 1, "consume": 3, "damage": 30, "block": 0, "price": 100},
	"壁垒": {"kind": "effect", "cost": 1, "consume": 2, "damage": 0, "block": 24, "price": 85},
	"血祭": {"kind": "effect", "cost": 0, "consume": 1, "damage": 0, "block": 0, "self_status": {"力量": 2}, "self_damage": 6, "price": 65},
	"回响": {"kind": "effect", "cost": 1, "consume": 2, "damage": 10, "block": 0, "draw": 2, "price": 80},
		# ===== 神国卡（只在妄想神国出现）=====
	"圣言": {"kind": "action", "cost": 1, "damage": 9, "block": 0, "divine": true, "price": 55},
	"神谕": {"kind": "action", "cost": 0, "damage": 0, "block": 0, "draw": 2, "divine": true, "price": 60},
	"圣痕": {"kind": "action", "cost": 2, "damage": 16, "block": 0, "divine": true, "price": 80},
	"审判": {"kind": "effect", "cost": 1, "consume": 1, "damage": 0, "block": 0, "status": {"易伤": 2}, "divine": true, "price": 65},
	"献祭": {"kind": "effect", "cost": 0, "consume": 2, "damage": 0, "block": 18, "divine": true, "price": 70},
	"苦修": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "self_damage": 5, "self_status": {"力量": 3}, "divine": true, "price": 60},
	"圣光弹": {"kind": "action", "cost": 1, "damage": 10, "block": 0, "divine": true, "price": 60},
	"信仰": {"kind": "action", "cost": 1, "damage": 0, "block": 10, "heal": 5, "divine": true, "price": 65},
	
	# ===== 遭遇牌：抽到立即生效 =====
	"陷阱": {"kind": "encounter", "max_uses": 1, "cost": 0, "damage": 0, "block": 0, "self_damage": 5, "price": 0},
	"灵感": {"kind": "encounter", "max_uses": 2, "cost": 0, "damage": 0, "block": 0, "draw": 2, "self_damage": 3, "price": 0},
	"霉运": {"kind": "encounter", "max_uses": 5, "cost": 0, "damage": 0, "block": 0, "self_damage": 4, "price": 0},
	"启示": {"kind": "encounter", "max_uses": 2, "gain_energy": 1, "cost": 0, "damage": 0, "block": 0, "draw": 1, "self_damage": 2, "price": 0},
	"惊梦": {"kind": "encounter", "max_uses": 2, "cost": 0, "damage": 0, "draw": 1, "block": 0, "self_damage": 6, "price": 0},
	"圣光": {"kind": "encounter", "max_uses": 3, "gain_energy": 1, "damage": 0, "block": 8, "price": 0},
	"纠缠": {"kind": "encounter", "max_uses": 0, "cost": 1, "gain_energy":0,"damage": 0, "self_damage": 6, "block": 0, "price": 0},

	# ===== 遗骸专属卡（只在遗骸事件里出现）=====
	"守夜": {"kind": "action", "cost": 1, "damage": 0, "block": 33, "remnant": true, "price": 0},
	"断章": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "status": {"中毒": 9, "易伤": 6}, "remnant": true, "price": 0},
	"未竟": {"kind": "action", "cost": 0, "damage": 0, "block": 0, "draw": 3, "gain_energy": 1, "remnant": true, "price": 0},
	"旧誓": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "self_status": {"力量": 12}, "self_damage": 5, "remnant": true, "price": 0},
	"回望": {"kind": "action", "cost": 1, "damage": 0, "block": 27, "draw": 2, "remnant": true, "price": 0},
	"遗志": {"kind": "action", "cost": 1, "damage": 18, "block": 0, "heal": 10, "remnant": true, "price": 0},
	"残响": {"kind": "effect", "cost": 1, "consume": 1, "damage": 28, "block": 0, "remnant": true, "price": 0},
	"灯": {"kind": "action", "cost": 1, "damage": 0, "block": 18, "heal": 12, "remnant": true, "price": 0},
	"最后一击": {"kind": "action", "cost": 3, "damage": 80, "block": 0, "remnant": true, "price": 0},
	"遗忘": {"kind": "action", "cost": 0, "damage": 0, "block": 0, "draw": 4, "self_damage": 1, "remnant": true, "price": 0},
	"遗恨": {"kind": "effect", "cost": 2, "consume": 2, "damage": 55, "block": 0, "remnant": true, "price": 0},
	"执念": {"kind": "effect", "cost": 1, "consume": 2, "damage": 0, "block": 39, "remnant": true, "price": 0},
	"旧伤": {"kind": "effect", "cost": 1, "consume": 1, "damage": 0, "block": 0, "status": {"流血": 12}, "remnant": true, "price": 0},
	"余烬": {"kind": "effect", "cost": 0, "consume": 1, "damage": 15, "block": 0, "self_damage": 3, "remnant": true, "price": 0},
	"长夜": {"kind": "effect", "cost": 2, "consume": 3, "damage": 0, "block": 39, "heal": 25, "remnant": true, "price": 0},
	"遗言": {"kind": "effect", "cost": 1, "consume": 1, "damage": 0, "block": 10, "draw": 5, "gain_energy": 1, "remnant": true, "price": 0},

	# ===== 事件专属卡（只在事件里出现）=====
	"誓约": {"kind": "action", "cost": 1, "damage": 0, "block": 12, "heal": 5, "event": true, "price": 0},
	"圣约": {"kind": "effect", "cost": 2, "consume": 2, "damage": 20, "block": 0, "heal": 10, "event": true, "price": 0},
	"赎罪": {"kind": "action", "cost": 0, "damage": 0, "block": 20, "self_damage": 8, "event": true, "price": 0},
	"忏悔": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "heal": 12, "draw": 1, "event": true, "price": 0},
	"妄念": {"kind": "action", "cost": 1, "damage": 14, "block": 0, "self_damage": 4, "event": true, "price": 0},
	"神国余晖": {"kind": "effect", "cost": 1, "consume": 1, "damage": 0, "block": 15, "draw": 1, "event": true, "price": 0},
	"血约": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "self_status": {"力量": 3}, "self_damage": 4, "event": true, "price": 0},
	"余火": {"kind": "action", "cost": 1, "damage": 7, "block": 0, "status": {"中毒": 3}, "event": true, "price": 0},
	"拾遗": {"kind": "action", "cost": 0, "damage": 0, "block": 3, "draw": 2, "event": true, "price": 0},
	"哑歌": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "heal": 8, "draw": 1, "event": true, "price": 0},
	"断刃": {"kind": "effect", "cost": 1, "consume": 1, "damage": 18, "block": 0, "event": true, "price": 0},
	"传说": {"kind": "effect", "cost": 1, "consume": 1, "damage": 8, "block": 5, "status": {"再生": 2}, "self_status": {"力量": 2}, "event": true, "price": 0},
}

const STARTER := ["打击", "防御", "重击", "铁壁", "疾风斩"]

func kind_of(id: String) -> String:
	return CARDS[id].get("kind", "action")

func consume_count(id: String) -> int:
	return int(CARDS[id].get("consume", 0))

func price_of(id: String) -> int:
	return int(CARDS[id].get("price", DEFAULT_PRICE))

func all_ids() -> Array:
	return CARDS.keys()

func reward_pool() -> Array:
	var result := []
	for id in CARDS.keys():
		if CARDS[id].get("kind", "action") != "encounter":
			result.append(id)
	return result

func get_card(id: String) -> Dictionary:
	return CARDS[id]

func card_text(id: String) -> String:
	var d: Dictionary = CARDS[id]
	var kind: String = d.get("kind", "action")
	var effects: Array[String] = []
	var hits: int = d.get("hits", 1)
	if d["damage"] > 0:
		if hits > 1:
			effects.append("%d 伤害×%d" % [d["damage"], hits])
		else:
			effects.append("%d 伤害" % d["damage"])
	if d["block"] > 0:
		effects.append("%d 格挡" % d["block"])
	if d.get("heal", 0) > 0:
		effects.append("回复 %d" % d["heal"])
	if d.get("draw", 0) > 0:
		effects.append("抽 %d 张" % d["draw"])
	if d.get("self_damage", 0) > 0:
		effects.append("受到 %d 伤害" % d["self_damage"])
	if d.get("gain_energy", 0) > 0:
		effects.append("能量 +%d" % d["gain_energy"])
	if d.get("retrieve_top", false):
		effects.append("取回弃牌堆顶")
	if d.has("status"):
		for key in d["status"]:
			effects.append("敌+%d%s" % [d["status"][key], key])
	if d.has("self_status"):
		for key in d["self_status"]:
			effects.append("我+%d%s" % [d["self_status"][key], key])
	var effect := ""
	for p in effects:
		if effect != "":
			effect += " / "
		effect += p
	var tag := ""
	if kind == "effect":
		tag = "[%d费·耗%d张]" % [d["cost"], d.get("consume", 0)]
	elif kind == "encounter":
		tag = "[遭遇·抽到生效]"
	elif d["cost"] < 0:
		tag = "[能量 +%d]" % (-d["cost"])
	else:
		tag = "[%d费]" % d["cost"]
	return "%s\n%s\n%s" % [id, tag, effect]

func starter_deck(size: int = 20) -> Array[String]:
	var result: Array[String] = []
	for i in range(size):
		result.append(STARTER[i % STARTER.size()])
	return result

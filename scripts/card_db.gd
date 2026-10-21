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
	"力量药剂": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "self_status": {"力量": 2}, "price": 60},
	"双重打击": {"kind": "action", "cost": 1, "damage": 4, "block": 0, "hits": 2, "price": 50},
	"急救": {"kind": "action", "cost": 1, "damage": 0, "block": 0, "heal": 6, "price": 40},
	"快速思考": {"kind": "action", "cost": 0, "damage": 0, "block": 0, "draw": 2, "price": 50},
	"火球": {"kind": "action", "cost": 2, "damage": 12, "block": 0, "price": 70},

	# ===== 效果牌：消耗能量 + 消耗 N 张其他手牌 =====
	"削弱": {"kind": "effect", "cost": 0, "consume": 1, "damage": 0, "block": 0, "status": {"虚弱": 2}, "price": 50},
	"终结": {"kind": "effect", "cost": 1, "consume": 2, "damage": 18, "block": 0, "price": 80},
	"大盾": {"kind": "effect", "cost": 1, "consume": 2, "damage": 0, "block": 18, "price": 80},

	# ===== 遭遇牌：抽到立即生效 =====
	"陷阱": {"kind": "encounter", "cost": 0, "damage": 0, "block": 0, "self_damage": 5, "price": 0},
	"圣光": {"kind": "encounter", "cost": -1, "damage": 0, "block": 8, "price": 0},
}

const STARTER := ["打击", "防御", "重击", "铁壁", "疾风斩", "圣光", "陷阱"]

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

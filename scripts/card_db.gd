extends Node

const DEFAULT_PRICE := 40

const CARDS := {
	"打击": {"cost": 1, "damage": 6, "block": 0, "price": 30},
	"防御": {"cost": 1, "damage": 0, "block": 5, "price": 30},
	"重击": {"cost": 2, "damage": 10, "block": 0, "price": 50},
	"铁壁": {"cost": 2, "damage": 0, "block": 10, "price": 50},
	"疾风斩": {"cost": 1, "damage": 8, "block": 0, "price": 45},
	"毒刃": {"cost": 1, "damage": 0, "block": 0, "status": {"中毒": 3}, "price": 55},
	"削弱": {"cost": 1, "damage": 0, "block": 0, "status": {"虚弱": 2}, "price": 45},
	"力量药剂": {"cost": 1, "damage": 0, "block": 0, "self_status": {"力量": 2}, "price": 60},
	"双重打击": {"cost": 1, "damage": 4, "block": 0, "hits": 2, "price": 45},
	"急救": {"cost": 1, "damage": 0, "block": 0, "heal": 6, "price": 40},
	"快速思考": {"cost": 0, "damage": 0, "block": 0, "draw": 2, "price": 50},
	"火球": {"cost": 2, "damage": 12, "block": 0, "price": 70},
}

const STARTER := ["打击", "防御", "重击", "铁壁", "疾风斩"]

func all_ids() -> Array:
	return CARDS.keys()

func get_card(id: String) -> Dictionary:
	return CARDS[id]

func price_of(id: String) -> int:
	return int(CARDS[id].get("price", DEFAULT_PRICE))

func card_text(id: String) -> String:
	var d: Dictionary = CARDS[id]
	var parts: Array[String] = []
	var hits: int = d.get("hits", 1)
	if d["damage"] > 0:
		if hits > 1:
			parts.append("%d 伤害×%d" % [d["damage"], hits])
		else:
			parts.append("%d 伤害" % d["damage"])
	if d["block"] > 0:
		parts.append("%d 格挡" % d["block"])
	if d.get("heal", 0) > 0:
		parts.append("回复 %d" % d["heal"])
	if d.get("draw", 0) > 0:
		parts.append("抽 %d 张" % d["draw"])
	if d.has("status"):
		for key in d["status"]:
			parts.append("敌 +%d%s" % [d["status"][key], key])
	if d.has("self_status"):
		for key in d["self_status"]:
			parts.append("我 +%d%s" % [d["self_status"][key], key])
	var effect := ""
	for p in parts:
		if effect != "":
			effect += " / "
		effect += p
	return "%s\n[%d费] %s" % [id, d["cost"], effect]

func starter_deck(size: int = 20) -> Array[String]:
	var result: Array[String] = []
	for i in range(size):
		result.append(STARTER[i % STARTER.size()])
	return result

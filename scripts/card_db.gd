extends Node

const CARDS := {
	"打击": {"cost": 1, "damage": 6, "block": 0},
	"防御": {"cost": 1, "damage": 0, "block": 5},
	"重击": {"cost": 2, "damage": 10, "block": 0},
	"铁壁": {"cost": 2, "damage": 0, "block": 10},
	"疾风斩": {"cost": 1, "damage": 8, "block": 0},
	"毒刃": {"cost": 1, "damage": 0, "block": 0, "poison": 3},
	"双重打击": {"cost": 1, "damage": 4, "block": 0, "hits": 2},
	"急救": {"cost": 1, "damage": 0, "block": 0, "heal": 6},
	"快速思考": {"cost": 0, "damage": 0, "block": 0, "draw": 2},
}

const STARTER := ["打击", "防御", "重击", "铁壁", "疾风斩"]

func all_ids() -> Array:
	return CARDS.keys()

func get_card(id: String) -> Dictionary:
	return CARDS[id]

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
	if d.get("poison", 0) > 0:
		parts.append("%d 中毒" % d["poison"])
	if d.get("heal", 0) > 0:
		parts.append("回复 %d" % d["heal"])
	if d.get("draw", 0) > 0:
		parts.append("抽 %d 张" % d["draw"])
	var effect := ""
	for p in parts:
		if effect != "":
			effect += " / "
		effect += p
	return "%s\n[%d费] %s" % [id, d["cost"], effect]

func starter_deck() -> Array[String]:
	var result: Array[String] = []
	for i in range(20):
		result.append(STARTER[i % STARTER.size()])
	return result

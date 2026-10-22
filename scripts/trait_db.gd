extends Node

const TRAITS := {
	"强健": {"desc": "最大生命 +15", "hp": 15},
	"富裕": {"desc": "初始金币 +30", "gold": 30},
	"敏锐": {"desc": "初始手牌 +1", "hand": 1},
	"残躯": {"desc": "最大生命 -10", "hp": -10},
	"健忘": {"desc": "初始手牌 -1", "hand": -1},
	"神眷": {"desc": "开局获得一张「火球」", "card": "火球"},
}

func roll() -> Array[String]:
	var pool: Array = TRAITS.keys()
	pool.shuffle()
	var count: int = randi_range(2, 3)
	var result: Array[String] = []
	for i in range(min(count, pool.size())):
		result.append(pool[i])
	return result

func text_of(traits: Array[String]) -> String:
	var s := ""
	for t in traits:
		if s != "":
			s += " / "
		s += "%s（%s）" % [t, TRAITS[t]["desc"]]
	return s

func total_hp(traits: Array[String]) -> int:
	var v := 0
	for t in traits:
		v += int(TRAITS[t].get("hp", 0))
	return v

func total_gold(traits: Array[String]) -> int:
	var v := 0
	for t in traits:
		v += int(TRAITS[t].get("gold", 0))
	return v

func total_hand(traits: Array[String]) -> int:
	var v := 0
	for t in traits:
		v += int(TRAITS[t].get("hand", 0))
	return v

func bonus_cards(traits: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for t in traits:
		if TRAITS[t].has("card"):
			result.append(str(TRAITS[t]["card"]))
	return result

extends Node

const TRAITS := {
	"强健": {"desc": "最大生命 +15", "hp": 15},
	"富裕": {"desc": "初始金币 +30", "gold": 30},
	"敏锐": {"desc": "初始手牌 +1", "hand": 1},
	"残躯": {"desc": "最大生命 -10", "hp": -10},
	"健忘": {"desc": "初始手牌 -1", "hand": -1},
	"神眷": {"desc": "开局获得一张「火球」", "card": "火球"},
}

const VOCATIONS := {
	"等待丈夫的新娘": {"desc": "她在神域尽头等了太久。", "traits": ["敏锐", "神眷", "残躯"]},
	"失明的守钟人": {"desc": "他听不见钟声，却一直在敲。", "traits": ["健忘", "强健", "敏锐"]},
	"饥饿的朝圣者": {"desc": "他走了很远，胃里空空。", "traits": ["残躯", "富裕", "健忘"]},
	"沉默的执剑人": {"desc": "剑比话多。", "traits": ["强健", "健忘", "神眷"]},
	"疯癫的先知": {"desc": "她看见了不该看见的东西。", "traits": ["神眷", "残躯", "敏锐"]},
	"褴褛的记账人": {"desc": "他记着每一笔债。", "traits": ["富裕", "健忘", "残躯"]},
	"断臂的旗手": {"desc": "旗还在，手没了。", "traits": ["强健", "残躯", "富裕"]},
	"无名的旅人": {"desc": "你记不住他的脸。", "traits": ["敏锐", "富裕", "强健"]},
}

func roll_vocation() -> String:
	var pool: Array = VOCATIONS.keys()
	return str(pool[randi() % pool.size()])

func traits_of(vocation: String) -> Array[String]:
	var result: Array[String] = []
	if VOCATIONS.has(vocation):
		for t in VOCATIONS[vocation]["traits"]:
			result.append(str(t))
	return result

func vocation_text(vocation: String) -> String:
	if not VOCATIONS.has(vocation):
		return ""
	return "%s（%s）" % [vocation, VOCATIONS[vocation]["desc"]]

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

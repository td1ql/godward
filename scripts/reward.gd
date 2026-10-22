# ============================================================
# Reward —— 统一的「奖励应用」工具
# ------------------------------------------------------------
# 支持字段：
#   "gold"         : int   金币变化（负数是花费）
#   "hp"           : int   生命变化（负数是受伤）
#   "cards"        : Array 直接获得这些卡
#   "random_cards" : int   从奖励池随机抽这么多张
#   "ally"         : bool  是否让 contestant_id 成为盟友
# ============================================================

class_name Reward

static func can_apply(data: Dictionary) -> bool:
	if data.has("gold") and int(data["gold"]) < 0 and GameState.gold + int(data["gold"]) < 0:
		return false
	return true

static func apply(data: Dictionary, contestant_id: String = "") -> String:
	var parts: Array[String] = []

	if data.has("gold"):
		var g: int = int(data["gold"])
		GameState.gold = max(0, GameState.gold + g)
		parts.append("金币 %s%d" % ["+" if g >= 0 else "", g])

	if data.has("hp"):
		var h: int = int(data["hp"])
		GameState.player_hp = clamp(GameState.player_hp + h, 1, GameState.player_max_hp)
		parts.append("生命 %s%d" % ["+" if h >= 0 else "", h])

	if data.has("cards"):
		for c in data["cards"]:
			GameState.deck.append(str(c))
			parts.append("获得「%s」" % str(c))

	if data.has("random_cards"):
		var count: int = int(data["random_cards"])
		var pool: Array = CardDB.reward_pool()
		for i in range(count):
			var card: String = str(pool[randi() % pool.size()])
			GameState.deck.append(card)
			parts.append("获得「%s」" % card)

	if contestant_id != "" and data.get("ally", false) and not GameState.allies.has(contestant_id):
		GameState.allies.append(contestant_id)
		parts.append("「%s」成为盟友" % ContestantDB.name_of(contestant_id))

	var s := ""
	for p in parts:
		if s != "":
			s += "　"
		s += p
	return s

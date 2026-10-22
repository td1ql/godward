# ============================================================
# Reward —— 统一的「奖励应用」工具
# ------------------------------------------------------------
# 用途：把「金币 / 生命 / 卡牌 / 随机卡牌 / 结盟」这类奖励，
#       用同一套代码应用到 GameState，并返回一份「获得明细」文本。
#
# 谁在用：
#   - map.gd       事件选择 / 参赛者交谈 / 收下遗骸
#   - battle_demo  参赛者「杀死 / 饶恕」结算
#
# 奖励字典支持这些字段（都是可选的）：
#   "gold"         : int   金币变化（负数是花费）
#   "hp"           : int   生命变化（负数是受伤）
#   "cards"        : Array 直接获得这些卡，如 ["打击", "火球"]
#   "random_cards" : int   从奖励池随机抽这么多张
#   "ally"         : bool  是否让 contestant_id 成为盟友
#
# 以后要加新奖励类型（比如"获得能量"）：
#   1. 在 apply() 里加一个分支
#   2. 在 parts.append(...) 里补一句提示文字
#   3. 所有调用点自动生效，不用改
# ============================================================

class_name Reward

# 检查奖励是否"付得起"（目前只检查金币不足）
# 返回 false 时，调用方应该提示玩家并中止
static func can_apply(data: Dictionary) -> bool:
	if data.has("gold") and int(data["gold"]) < 0 and GameState.gold + int(data["gold"]) < 0:
		return false
	return true

# 应用奖励，返回「获得明细」字符串（用于 Toast 提示）
# contestant_id：结盟时传入参赛者 id，一般奖励传空字符串
static func apply(data: Dictionary, contestant_id: String = "") -> String:
	var parts: Array[String] = []

	# ---- 金币 ----
	if data.has("gold"):
		var g: int = int(data["gold"])
		GameState.gold = max(0, GameState.gold + g)   # 金币不会变负
		parts.append("金币 %s%d" % ["+" if g >= 0 else "", g])

	# ---- 生命 ----
	if data.has("hp"):
		var h: int = int(data["hp"])
		GameState.player_hp = clamp(GameState.player_hp + h, 1, GameState.player_max_hp)  # 至少留 1 血
		parts.append("生命 %s%d" % ["+" if h >= 0 else "", h])

	# ---- 指定卡牌 ----
	if data.has("cards"):
		for c in data["cards"]:
			GameState.deck.append(str(c))
			parts.append("获得「%s」" % str(c))

	# ---- 随机卡牌 ----
	if data.has("random_cards"):
		var count: int = int(data["random_cards"])
		var pool: Array = CardDB.reward_pool()
		for i in range(count):
			var card: String = str(pool[randi() % pool.size()])
			GameState.deck.append(card)
			parts.append("获得「%s」" % card)

	# ---- 结盟 ----
	if contestant_id != "" and data.get("ally", false) and not GameState.allies.has(contestant_id):
		GameState.allies.append(contestant_id)
		parts.append("「%s」成为盟友" % ContestantDB.name_of(contestant_id))

	# ---- 拼成一行提示 ----
	var s := ""
	for p in parts:
		if s != "":
			s += "　"
		s += p
	return s

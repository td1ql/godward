extends Node

# ============================================================
# Inventory —— 背包（掉落物 + 物品）
# ------------------------------------------------------------
# 数据存在 GameState 上，跟着存档走：
#   GameState.drops      : { 掉落物id : 数量 }
#   GameState.items      : { 物品id : 数量 }
#   GameState.item_uses  : { 物品id : 已经用掉几次 }（给 multi 型记次数）
#   GameState.item_perms : { 效果键 : 数值 }（perm 型物品挂上的永久效果）
#
# 这一层只做「有没有 / 加减 / 合成 / 能不能用」，不画任何界面。
# ============================================================


# ---------- 掉落物 ----------

func drop_count(id: String) -> int:
	return int(GameState.drops.get(id, 0))


func add_drop(id: String, n: int = 1) -> void:
	if id == "" or n <= 0:
		return
	GameState.drops[id] = drop_count(id) + n


func take_drop(id: String, n: int = 1) -> bool:
	if drop_count(id) < n:
		return false
	var left := drop_count(id) - n
	if left <= 0:
		GameState.drops.erase(id)
	else:
		GameState.drops[id] = left
	return true


# 一次加一批（胜利掉落用）
func add_drops(list: Array) -> void:
	for id in list:
		add_drop(str(id), 1)


# ---------- 物品 ----------

func item_count(id: String) -> int:
	return int(GameState.items.get(id, 0))


func add_item(id: String, n: int = 1) -> void:
	if id == "" or n <= 0:
		return
	GameState.items[id] = item_count(id) + n
	# perm 型：拿到就自动挂上永久效果
	if ItemDB.use_mode_of(id) == "perm":
		_apply_perm(id)


func take_item(id: String, n: int = 1) -> bool:
	if item_count(id) < n:
		return false
	var left := item_count(id) - n
	if left <= 0:
		GameState.items.erase(id)
		GameState.item_uses.erase(id)
	else:
		GameState.items[id] = left
	return true


func forget_item(id: String) -> void:
	GameState.items.erase(id)
	GameState.item_uses.erase(id)


# ---------- multi 型的使用次数 ----------

func uses_left(id: String) -> int:
	if ItemDB.use_mode_of(id) != "multi":
		return 1 if item_count(id) > 0 else 0
	var used := int(GameState.item_uses.get(id, 0))
	return maxi(0, ItemDB.max_uses_of(id) * item_count(id) - used)


# 记一次使用；multi 型用满就销毁那一件
func consume_use(id: String) -> void:
	if ItemDB.use_mode_of(id) == "multi":
		var used := int(GameState.item_uses.get(id, 0)) + 1
		GameState.item_uses[id] = used
		if used >= ItemDB.max_uses_of(id) * item_count(id):
			take_item(id, 1)
			var rest := int(GameState.item_uses.get(id, 0)) - ItemDB.max_uses_of(id)
			if rest > 0:
				GameState.item_uses[id] = rest
			else:
				GameState.item_uses.erase(id)
	else:
		take_item(id, 1)


# ---------- 永久效果 ----------

func _apply_perm(id: String) -> void:
	var p: Dictionary = ItemDB.perm_of(id)
	for k in p:
		GameState.item_perms[k] = int(GameState.item_perms.get(k, 0)) + int(p[k])


func perm_total(key: String) -> int:
	return int(GameState.item_perms.get(key, 0))


# ---------- 合成 ----------

func can_combine(item_id: String) -> bool:
	if not ItemDB.has(item_id):
		return false
	var recipe: Dictionary = ItemDB.recipe_of(item_id)
	if recipe.is_empty():
		return false
	for mat in recipe:
		if drop_count(str(mat)) < int(recipe[mat]):
			return false
	return true


# 能凑齐配方的所有物品（休息处的「可合成」列表）
func combinable() -> Array:
	var out: Array = []
	for id in ItemDB.RECIPES.keys():
		if can_combine(str(id)):
			out.append(str(id))
	return out


func combine(item_id: String) -> bool:
	if not can_combine(item_id):
		return false
	var recipe: Dictionary = ItemDB.recipe_of(item_id)
	for mat in recipe:
		take_drop(str(mat), int(recipe[mat]))
	add_item(item_id, 1)
	return true


# ---------- 战斗可用 ----------

func battle_usable() -> Array:
	var out: Array = []
	for id in GameState.items.keys():
		if ItemDB.can_use_in_battle(str(id)) and uses_left(str(id)) > 0:
			out.append(str(id))
	return out


# ---------- 清理（新的一局 / 转生）----------

func clear_all() -> void:
	GameState.drops.clear()
	GameState.items.clear()
	GameState.item_uses.clear()
	GameState.item_perms.clear()


# ---------- 给界面用的一行摘要 ----------

func drop_summary() -> String:
	if GameState.drops.is_empty():
		return ""
	var parts: Array[String] = []
	for id in GameState.drops:
		parts.append("%s×%d" % [DropDB.name_of(str(id)), int(GameState.drops[id])])
	return "、".join(parts)


func item_summary() -> String:
	if GameState.items.is_empty():
		return ""
	var parts: Array[String] = []
	for id in GameState.items:
		parts.append("%s×%d" % [ItemDB.name_of(str(id)), int(GameState.items[id])])
	return "、".join(parts)

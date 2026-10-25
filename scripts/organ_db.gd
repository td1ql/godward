class_name OrganDB
extends RefCounted

# ============================================================
# OrganDB —— 第三幕的神骸器官
# ------------------------------------------------------------
# 拿到就永久生效，没有副作用。
# 四个全拿到 = 质变。
# 数据存在 GameState.organs（存档里）。
# ============================================================

const ORGANS := {
	"神之眼": {"desc": "每回合多抽 2 张。", "draw": 2},
	"神之舌": {"desc": "每回合能量 +1。", "energy": 1},
	"神之心": {"desc": "最大生命 +30，每场战斗开始回复 10。", "hp": 30, "start_heal": 10},
	"神之手": {"desc": "每回合第一张牌费用 -2。", "first_discount": 2},
}

const ALL := ["神之眼", "神之舌", "神之心", "神之手"]


static func owned(id: String) -> bool:
	return GameState.organs.has(id)


static func remaining() -> Array:
	var out: Array = []
	for id in ALL:
		if not GameState.organs.has(id):
			out.append(id)
	return out


static func desc_of(id: String) -> String:
	return str(ORGANS.get(id, {}).get("desc", ""))


# 汇总某个字段的总加成
static func total(field: String) -> int:
	var n := 0
	for id in GameState.organs:
		n += int(ORGANS.get(id, {}).get(field, 0))
	return n


# 拿一个器官
static func take(id: String) -> void:
	if id == "" or GameState.organs.has(id):
		return
	GameState.organs.append(id)
	GameState.divinity = clampi(GameState.divinity + 15, 0, 100)
	GameState.recompute_max_hp()
	GameState.save_game()

extends Node

# ===== 地图长度与分支 =====
const MAX_DEPTH := 13          # 总层数（中心 → 4 步 → 首领）
const ROOT_BRANCHES := 5      # 起点连出的分支数
const MIN_BRANCHES := 4       # 每层最少分支
const MAX_BRANCHES := 6       # 每层最多分支

# ===== 每层可出现的节点类型（重复写 = 提高权重）=====
const LAYER_POOLS := {
	1: ["battle", "battle"],
	2: ["battle", "battle", "event"],
	3: ["elite", "shop", "rest", "event"],
	4: ["battle", "battle", "event", "shop"],
	5: ["elite", "battle", "rest", "event"],
	6: ["battle", "battle", "shop", "event", "contestant"],
	7: ["elite", "elite", "rest", "shop"],
	8: ["battle", "battle", "shop", "event", "contestant"],
	9: ["battle", "battle", "shop", "event", "contestant"],
	10: ["battle", "battle", "shop", "event", "contestant"],
	11: ["shop", "contestant", "contestant"],
	12: ["elite", "elite", "shop", "event", "contestant"],
	13: ["shop", "event", "shop", "event", "contestant"],
}

# 最后一层固定类型
const FINAL_TYPE := "boss"

# ===== 节点类型 → 显示名 / 颜色 =====
const TYPE_INFO := {
	"start": {"label": "起点", "color": Color(0.85, 0.85, 0.85)},
	"battle": {"label": "战斗", "color": Color(0.95, 0.45, 0.45)},
	"elite": {"label": "精英", "color": Color(0.75, 0.45, 0.95)},
	"shop": {"label": "商店", "color": Color(0.95, 0.85, 0.35)},
	"event": {"label": "事件", "color": Color(0.45, 0.75, 0.95)},
	"rest": {"label": "休息", "color": Color(0.45, 0.9, 0.55)},
	"boss": {"label": "首领", "color": Color(1.0, 0.25, 0.25)},
	"contestant": {"label": "参赛者", "color": Color(0.95, 0.6, 0.3)},
}

func pick_type(depth: int) -> String:
	if depth >= MAX_DEPTH:
		return FINAL_TYPE
	var pool: Array = LAYER_POOLS.get(depth, ["battle"])
	return pool[randi() % pool.size()]

func info_of(type: String) -> Dictionary:
	return TYPE_INFO[type]

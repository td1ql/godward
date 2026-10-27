extends Node

# ===== 地图长度与分支 =====
const MAX_DEPTH := 20        # 总层数 → 首领）
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
	6: ["battle", "battle", "shop", "event", "npc"],
	7: ["elite", "elite", "rest", "shop"],
	8: ["battle", "battle", "shop", "event", "npc"],
	9: ["battle", "battle", "shop", "event", "npc"],
	10: ["battle", "battle", "shop", "event", "npc"],
	11: ["shop", "npc", "npc"],
	12: ["elite", "elite", "shop", "event", "npc"],
	13: ["shop", "event", "shop", "event", "npc"],
	14: ["battle", "battle", "shop", "event", "npc"],
	15: ["elite", "elite", "rest", "shop"],
	16: ["battle", "battle", "shop", "event", "npc"],
	17: ["shop", "event", "shop", "event", "npc"],
	18: ["elite", "elite", "shop", "npc"],
	19: ["shop",  "rest"],
}

# 最后一层固定类型
const FINAL_TYPE := "boss"

# ===== 第二幕：教皇的妄想神国 =====
const ACT2_DEPTH := 9

const ACT2_POOLS := {
	1: ["divine", "divine"],
	2: ["divine", "divine", "event", "remnant"],
	3: ["divine_elite", "shop", "rest", "event"],
	4: ["divine", "divine", "event", "remnant", "shop"],
	5: ["divine_elite", "divine", "rest", "event"],
	6: ["divine", "divine", "event", "remnant"],
	7: ["divine_elite", "shop", "rest", "event"],
	8: ["divine", "divine_elite", "remnant", "event"],
}

const ACT2_FINAL := "pope"


# ===== 第三幕：神明降临人间 =====
const ACT3_DEPTH := 20

const ACT3_POOLS := {
	1: ["battle", "battle"],
	2: ["battle", "shell", "event"],
	3: ["god", "battle"],
	4: ["npc", "battle", "shell"],
	5: ["battle", "wealth", "battle"],
	6: ["shell", "npc", "battle"],
	7: ["battle", "battle", "event"],
	8: ["god", "npc", "battle"],
	9: ["battle", "wealth", "shell"],
	10: ["npc", "battle", "battle"],
	11: ["shell", "battle", "event"],
	12: ["battle", "wealth", "npc"],
	13: ["god", "battle", "shell"],
	14: ["npc", "battle", "battle"],
	15: ["battle", "battle", "shell"],
	16: ["wealth", "npc", "battle"],
	17: ["shell", "battle", "battle"],
	18: ["god", "npc", "battle"],
	19: ["battle", "wealth", "shell"],
}

const ACT3_FINAL := "serpent"

const TYPE_INFO := {
	"start": {"label": "起点", "color": Color(0.85, 0.85, 0.85)},
	"battle": {"label": "战斗", "color": Color(0.95, 0.45, 0.45)},
	"elite": {"label": "精英", "color": Color(0.75, 0.45, 0.95)},
	"shop": {"label": "商店", "color": Color(0.95, 0.85, 0.35)},
	"event": {"label": "事件", "color": Color(0.45, 0.75, 0.95)},
	"rest": {"label": "休息", "color": Color(0.45, 0.9, 0.55)},
	"boss": {"label": "守门人", "color": Color(1.0, 0.25, 0.25)},
	"divine": {"label": "造物", "color": Color(0.75, 0.8, 1.0)},
	"divine_elite": {"label": "守卫", "color": Color(0.85, 0.65, 1.0)},
	"remnant": {"label": "过去的遗骸", "color": Color(0.55, 0.95, 0.9)},
	"npc": {"label": "同行的英雄", "color": Color(0.95, 0.85, 0.55)},
	"pope": {"label": "教皇", "color": Color(1.0, 0.85, 0.3)},
	"god": {"label": "疯狂的神", "color": Color(0.95, 0.45, 0.75)},
	"shell": {"label": "空壳", "color": Color(0.75, 0.62, 0.52)},
	"wealth": {"label": "财富之神", "color": Color(1.0, 0.85, 0.35)},
	"serpent": {"label": "耶梦加得", "color": Color(0.45, 0.95, 0.55)},
}

func max_depth_of(act: int) -> int:
	if act == 3:
		return ACT3_DEPTH
	return ACT2_DEPTH if act == 2 else MAX_DEPTH

func final_type_of(act: int) -> String:
	if act == 3:
		return ACT3_FINAL
	return ACT2_FINAL if act == 2 else FINAL_TYPE

func pick_type(depth: int, act: int = 1) -> String:
	if act == 3:
		if depth >= ACT3_DEPTH:
			return ACT3_FINAL
		var pool3: Array = ACT3_POOLS.get(depth, ["battle"])
		return pool3[randi() % pool3.size()]
	if act == 2:
		if depth >= ACT2_DEPTH:
			return ACT2_FINAL
		var pool2: Array = ACT2_POOLS.get(depth, ["divine"])
		return pool2[randi() % pool2.size()]
	if depth >= MAX_DEPTH:
		return FINAL_TYPE
	var pool: Array = LAYER_POOLS.get(depth, ["battle"])
	return pool[randi() % pool.size()]

func info_of(type: String) -> Dictionary:
	return TYPE_INFO[type]

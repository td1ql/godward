extends Node

# 遇见的开场：三行一个停顿
const OPENINGS := [
	"你走到这里，看见一具尸首。\n它穿着你的衣服。\n它比你先到。",
	"有东西靠在墙边。\n你走近，它抬起头。\n那是你。",
	"地上有一摊血。\n血是干透的。\n是你自己的。",
	"它坐在那里，像在等谁。\n看见你的时候，它笑了一下。\n它认得你。",
	"你不记得来过这里。\n但地上有你的脚印。\n一路都是。",
]

# 兜底遗骸：没有职业史时使用
const REMNANTS := [
	{"name": "第 2 次转生的你", "text": "它背对着你，还在等一个不会回来的人。", "cards": ["回望"], "hp": 10},
	{"name": "第 3 次转生的你", "text": "它握着断掉的剑，眼睛却还亮着。", "cards": ["灯"], "hp": 8},
	{"name": "第 5 次转生的你", "text": "它把护符塞进你手里，什么也没说。", "cards": ["守夜"], "hp": 8},
	{"name": "第 7 次转生的你", "text": "它笑了笑：「这次别死在门口。」", "gold": 60},
	{"name": "第 8 次转生的你", "text": "它靠坐在墙边，像睡着了一样。", "cards": ["旧伤"], "gold": 20},
	{"name": "第 9 次转生的你", "text": "它只剩一只手，却还攥着东西。", "cards": ["未竟"], "hp": 12},
]

func opening() -> String:
	return str(OPENINGS[randi() % OPENINGS.size()])

func pick() -> Dictionary:
	if not GameState.vocation_history.is_empty():
		var idx: int = randi() % GameState.vocation_history.size()
		var v: String = GameState.vocation_history[idx]
		var info: Dictionary = TraitDB.VOCATIONS.get(v, {})
		var card: String = str(info.get("card", "守夜"))
		var line: String = str(info.get("remnant", "它什么也没说。"))
		return {
			"name": "第 %d 次转生的你" % (idx + 1),
			"open": opening(),
			"text": "%s\n\n——%s" % [line, v],
			"cards": [card],
		}
	var r: Dictionary = REMNANTS[randi() % REMNANTS.size()].duplicate(true)
	r["open"] = opening()
	return r

extends Node

const EVENTS := [
	{
		"text": "你发现一眼清澈的神秘泉水。",
		"choices": [
			{"label": "喝一口（回复 15 HP）", "hp": 15},
			{"label": "不喝，离开", "hp": 0},
		],
	},
	{
		"text": "一个路过的商人想和你玩个赌局。",
		"choices": [
			{"label": "赌一把（失去 8 HP，得到 60 金币）", "hp": -8, "gold": 60},
			{"label": "拒绝", "hp": 0},
		],
	},
	{
		"text": "地上有个破旧的箱子，似乎还能用。",
		"choices": [
			{"label": "撬开（得到 40 金币）", "gold": 40},
			{"label": "无视它", "hp": 0},
		],
	},
]

func pick() -> Dictionary:
	return EVENTS[randi() % EVENTS.size()]

extends Node

const EVENTS := [
	{
		"text": "你发现一眼清澈的神秘泉水。",
		"choices": [
			{"label": "喝一口（回复 15 HP）", "hp": 15},
			{"label": "不喝，离开"},
		],
	},
	{
		"text": "一个路过的商人想和你玩个赌局。",
		"choices": [
			{"label": "赌一把（失去 8 HP，得到 60 金币）", "hp": -8, "gold": 60},
			{"label": "拒绝"},
		],
	},
	{
		"text": "地上有个破旧的箱子，似乎还能用。",
		"choices": [
			{"label": "撬开（得到 40 金币）", "gold": 40},
			{"label": "无视它"},
		],
	},
	{
		"text": "一个流浪者摊开他的包袱，里面是几张奇特的牌。",
		"choices": [
			{"label": "偷走金币（+50 金币），获得「陷阱」", "gold": +50, "cards": ["陷阱"]},
			{"label": "买下「圣光」牌（-50 金币）", "gold": -50, "cards": ["圣光"]},
			{"label": "离开"},
		],
	},
	{
		"text": "祭坛上摆着两件供品，空气中飘着低语。",
		"choices": [
			{"label": "献上生命（-10 HP，获得「圣光」）", "hp": -10, "cards": ["圣光"]},
			{"label": "献上金币（-80 金币，获得 2 张「打击」）", "gold": -80, "cards": ["打击", "打击"]},
			{"label": "离开"},
		],
	},
	{
		"text": "路边有个受伤的旅人。",
		"choices": [
			{"label": "给他 20 金币", "gold": -20},
			{"label": "抢走他的钱（得到 30 金币）", "gold": 30},
			{"label": "无视"},
		],
	},
	{
		"text": "一处被遗忘的营地，灰烬还没有完全冷却。",
		"choices": [
			{"label": "翻找（-5 HP，得到 30 金币）", "hp": -5, "gold": 30},
			{"label": "生火休息（回复 10 HP）", "hp": 10},
			{"label": "离开"},
		],
	},
]

func pick() -> Dictionary:
	return EVENTS[randi() % EVENTS.size()]

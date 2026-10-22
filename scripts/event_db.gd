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
			{"label": "偷走金币（+50 金币），获得「陷阱」", "gold": 50, "cards": ["陷阱"]},
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

const DIVINE_EVENTS := [
	{
		"text": "无面的唱诗班在废墟里唱着歌。\n歌声让你想起一个已经忘记的名字。",
		"choices": [
			{"label": "跟着唱（回复 15 HP）", "hp": 15},
			{"label": "捂住耳朵走开（-5 HP）", "hp": -5},
		],
	},
	{
		"text": "一尊倒悬的圣像悬在半空，脚下是深不见底的裂口。",
		"choices": [
			{"label": "把它扶正（得到 40 金币）", "gold": 40},
			{"label": "砸碎它（-8 HP，获得「圣痕」）", "hp": -8, "cards": ["圣痕"]},
			{"label": "绕开"},
		],
	},
	{
		"text": "一本空白的圣典摊开在祭坛上，纸页在无风自动。",
		"choices": [
			{"label": "读下去（-10 HP，获得「神谕」）", "hp": -10, "cards": ["神谕"]},
			{"label": "合上它（回复 8 HP）", "hp": 8},
		],
	},
	{
		"text": "忏悔室的门虚掩着，里面传来你自己的声音。",
		"choices": [
			{"label": "忏悔（回复 20 HP）", "hp": 20},
			{"label": "说谎（得到 50 金币，-12 HP）", "gold": 50, "hp": -12},
			{"label": "离开"},
		],
	},
	{
		"text": "一幅巨大的教皇画像挂在墙上。画里的眼睛跟着你转动。",
		"choices": [
			{"label": "与它对视（-6 HP，获得「苦修」）", "hp": -6, "cards": ["苦修"]},
			{"label": "用刀划破画布（得到 30 金币）", "gold": 30},
			{"label": "低头走过"},
		],
	},
	{
		"text": "彩窗碎了一地，每一片都映着不同的你。",
		"choices": [
			{"label": "拼合碎片（获得「献祭」）", "cards": ["献祭"]},
			{"label": "捡起最大的那片（得到 35 金币，-5 HP）", "gold": 35, "hp": -5},
			{"label": "不碰它"},
		],
	},
	{
		"text": "长廊尽头坐着一个身影，和你穿一样的衣服。\n它没有抬头，只是把一张牌推了过来。",
		"choices": [
			{"label": "收下那张牌（获得「审判」，-4 HP）", "hp": -4, "cards": ["审判"]},
			{"label": "问它是谁（得到 25 金币）", "gold": 25},
			{"label": "离开"},
		],
	},
]

func pick(act: int = 1) -> Dictionary:
	var pool: Array = DIVINE_EVENTS if act == 2 else EVENTS
	return pool[randi() % pool.size()]

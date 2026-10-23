extends Node

const EVENTS := [
	{
		"text": "一眼泉水。\n看上去很清澈。",
		"choices": [
			{"label": "喝一口（回复 15 生命）", "hp": 15},
			{"label": "不喝，走开"},
		],
	},
	{
		"text": "一个商人在路边坐下，摆开三枚骨质骰子。\n「赌一把？」他说，「财富之神会祝福我们的。」",
		"choices": [
			{"label": "赌一把（-8 生命，+60 金币）", "hp": -8, "gold": 60, "sin": 5},
			{"label": "拒绝", "moral": 2},
		],
	},
	{
		"text": "一只箱子埋在土里，锁已经锈死了。",
		"choices": [
			{"label": "撬开（+40 金币）", "gold": 40, "sin": 3},
			{"label": "不碰它"},
		],
	},
	{
		"text": "披着斗篷的人背着包袱坐在路边。\n包袱口露出半张纸，上面画着看不懂的纹路。",
		"choices": [
			{"label": "偷走他的钱（+50 金币，习得「陷阱」）", "gold": 50, "cards": ["陷阱"], "sin": 10, "moral": -5},
			{"label": "买下那张纸（-50 金币，习得「圣光」）", "gold": -50, "cards": ["圣光"]},
			{"label": "走开"},
		],
	},
	{
		"text": "祭坛上摆着两样东西。\n一小截骨头，和一枚很旧的币。\n低语从坛下浮上来。",
		"choices": [
			{"label": "献上血（-10 生命，习得「圣光」）", "hp": -10, "cards": ["圣光"], "moral": 5},
			{"label": "献上金币（-80 金币，习得两张「打击」）", "gold": -80, "cards": ["打击", "打击"], "moral": 3},
			{"label": "离开"},
		],
	},
	{
		"text": "一处熄灭的营地。\n灰还是温的，人不知道去哪了。",
		"choices": [
			{"label": "翻找（-5 生命，+30 金币）", "hp": -5, "gold": 30, "sin": 3},
			{"label": "生火休息（回复 10 生命）", "hp": 10},
			{"label": "离开"},
		],
	},
	{
		"text": "一张纸从天上落下来，落在你脚边。\n上面的字你不认识。\n但你看它们的时候，它们也在看你。",
		"choices": [
			{"label": "收下它（习得「灵感」）", "cards": ["灵感"]},
			{"label": "撕掉它（回复 5 生命）", "hp": 5},
			{"label": "不碰"},
		],
	},
	{
		"text": "你靠着废墟的墙休息了一会。\n醒来时，手心里多了一样东西。\n没有人来过的痕迹。",
		"choices": [
			{"label": "收下它（-20 生命，习得「惊梦」）", "hp": -20, "cards": ["惊梦"], "sin": 5},
			{"label": "直接离开（+15 生命）", "hp": 5},
		],
	},
	{
		"text": "一阵风把你的行李吹散了。\n你捡回来的时候，发现多了一件。\n那不是你的。",
		"choices": [
			{"label": "去换成钱（+35 金币，习得「霉运」）", "gold": 35, "cards": ["霉运"], "sin": 3},
			{"label": "尝试丢掉它（-3 生命）", "hp": -3, "moral": 2},
			{"label": "不管它 (习得「霉运」)", "cards": ["霉运"], "sin": 3},
		],
	},
	{
		"text": "地上裂开一道缝。\n缝里有光。\n光照在你空着的手上。",
		"choices": [
			{"label": "把手伸进去（习得「启示」）", "cards": ["启示"]},
			{"label": "遮住眼睛（回复 6 生命）", "hp": 6, "moral": -2},
			{
		"text": "{name}拦住了你。\n「帮我一把，」他说，「我快撑不住了。」",
		"pick_contestant": true,
		"choices": [
			{"label": "分他一半的水（-5 生命）", "hp": -5, "moral": 8, "meet_picked": true},
			{"label": "问他能拿什么换", "next": {
				"text": "他想了很久。\n从怀里掏出一张纸。",
				"choices": [
					{"label": "收下（习得「誓约」）", "cards": ["誓约"], "meet_picked": true},
					{"label": "走开", "moral": -2},
				],
			}},
			{"label": "推开他", "sin": 5, "meet_picked": true},
			{"label": "（罪恶≥40）杀了他", "sin": 10, "moral": -5, "kill_picked": true, "min_sin": 40},
		],
	},
	{
		"text": "{name}在磨刀。\n看见你，他没有停。\n「你也想动手？」",
		"pick_contestant": true,
		"choices": [
			{"label": "在他对面坐下", "next": {
				"text": "他把刀放下。\n「先说好，我不欠你什么。」",
				"choices": [
					{"label": "结盟", "moral": 5, "ally_picked": true},
					{"label": "交易（+40 金币）", "gold": 40, "meet_picked": true},
					{"label": "起身离开"},
				],
			}},
			{"label": "先动手（-6 生命）", "hp": -6, "sin": 8, "meet_picked": true},
			{"label": "离开"},
		],
	},
	{
		"text": "你走了一段路，才发现身后有人。\n是{name}。\n他一直跟着，不说话。",
		"pick_contestant": true,
		"choices": [
			{"label": "回头问他", "next": {
				"text": "「前面有埋伏。」他说。\n「我只是不想一个人走。」",
				"choices": [
					{"label": "让他跟着", "moral": 5, "ally_picked": true},
					{"label": "让他走开", "moral": -3},
				],
			}},
			{"label": "不管他", "meet_picked": true},
			{"label": "（罪恶≥50）趁他不备", "sin": 12, "moral": -8, "kill_picked": true, "min_sin": 50},
		],
	},
	{
		"text": "{name}蹲在地上，面前摊着一堆东西。\n他没抬头。\n「见者有份。」",
		"pick_contestant": true,
		"choices": [
			{"label": "拿走一半（+30 金币）", "gold": 30, "sin": 3, "meet_picked": true},
			{"label": "什么都不要", "moral": 5, "meet_picked": true},
			{"label": "全都拿走（+60 金币，-5 生命）", "gold": 60, "hp": -5, "sin": 8, "meet_picked": true},
		],
	},	{
		"text": "一个人跪在路边。\n他划开了自己的手掌。\n「把手给我，」他说，「我们一起活。」",
		"choices": [
			{"label": "伸出手", "next": {
				"text": "他握住你的手。\n很凉。\n「这样就行了。」",
				"choices": [
					{"label": "收下他的血（-4 生命，习得「血约」）", "cards": ["血约"], "hp": -4, "moral": 3},
					{"label": "抽回手（-2 生命）", "hp": -2},
				],
			}},
			{"label": "（罪恶≥40）割开他的喉咙", "gold": 40, "sin": 10, "moral": -5, "min_sin": 40},
			{"label": "走开"},
		],
	},
	{
		"text": "一辆车翻在路边，还在烧。\n车里有人。\n他没有喊。",
		"choices": [
			{"label": "冲进去", "next": {
				"text": "你把他拖出来的时候，他手里还攥着东西。\n他把它塞给你，然后闭上了眼睛。",
				"choices": [
					{"label": "收下（-8 生命，习得「余火」）", "cards": ["余火"], "hp": -8, "moral": 8},
					{"label": "放下他，走开", "moral": 3},
				],
			}},
			{"label": "看着它烧完", "moral": -3},
		],
	},
	{
		"text": "这里打过一场。\n地上有很多东西。\n都没人要了。",
		"choices": [
			{"label": "慢慢翻找（+30 金币）", "gold": 30, "sin": 3},
			{"label": "只捡能用的（习得「拾遗」）", "cards": ["拾遗"], "moral": 2},
			{"label": "什么都不碰"},
		],
	},
	{
		"text": "一个女人坐在井边。\n她张着嘴，却没有声音。\n但你能听见。",
		"choices": [
			{"label": "坐下来听完", "next": {
				"text": "她唱完，看了你很久。\n然后把一样东西放在你手边。",
				"choices": [
					{"label": "收下（习得「哑歌」）", "cards": ["哑歌"], "moral": 5},
					{"label": "还给她", "moral": 8, "hp": 5},
				],
			}},
			{"label": "捂住耳朵走开", "moral": -2},
		],
	},
	{
		"text": "一具尸首靠在墙上。\n他的刀断了半截。\n断口很新。",
		"choices": [
			{"label": "拿走断刃（习得「断刃」）", "cards": ["断刃"], "sin": 3},
			{"label": "把他放平", "moral": 5},
			{"label": "（罪恶≥50）在他身上翻找（+40 金币）", "gold": 40, "sin": 5, "min_sin": 50},
		],
	},
		],
	},
]

const DIVINE_EVENTS := [
	{
		"text": "无面的唱诗班在废墟里唱。\n它们没有嘴。\n但歌声很齐。",
		"choices": [
			{"label": "跟着唱（回复 15 生命）", "hp": 15, "moral": 3},
			{"label": "捂住耳朵走开（-5 生命）", "hp": -5},
		],
	},
	{
		"text": "一尊圣像倒挂在半空。\n它脚下是裂口。\n裂口下面还有裂口。",
		"choices": [
			{"label": "扶正它（+40 金币）", "gold": 40, "moral": 5},
			{"label": "砸碎它（-8 生命，习得「圣痕」）", "hp": -8, "cards": ["圣痕"], "sin": 5},
			{"label": "绕开"},
		],
	},
	{
		"text": "一本圣典摊在祭坛上。\n纸是空的。\n风翻着它，翻到某一页就停了。",
		"choices": [
			{"label": "读下去（-10 生命，习得「神谕」）", "hp": -10, "cards": ["神谕"]},
			{"label": "合上它（回复 8 生命）", "hp": 8, "moral": 2},
		],
	},
	{
		"text": "忏悔室的门虚掩着。\n里面有人在小声说话。\n用的是你的声音。",
		"choices": [
			{"label": "忏悔（回复 20 生命）", "hp": 20, "moral": 5},
			{"label": "说谎（+50 金币，-12 生命）", "gold": 50, "hp": -12, "sin": 8},
			{"label": "离开"},
		],
	},
	{
		"text": "墙上挂着一幅巨大的画像。\n画里的人没有脸。\n但你知道他在看你。",
		"choices": [
			{"label": "与他对视（-6 生命，习得「苦修」）", "hp": -6, "cards": ["苦修"]},
			{"label": "划破画布（+30 金币）", "gold": 30, "sin": 5},
			{"label": "低下头走过去"},
		],
	},
	{
		"text": "彩窗碎了满地。\n每一片里都有一个你。\n穿着不同的衣服。",
		"choices": [
			{"label": "拼起来（习得「献祭」）", "cards": ["献祭"], "moral": 3},
			{"label": "捡最大的那片（+35 金币，-5 生命）", "gold": 35, "hp": -5, "sin": 3},
			{"label": "不碰"},
		],
	},
	{
		"text": "长廊尽头坐着一个人。\n穿的是你的衣服。\n他没有抬头，把一样东西推了过来。",
		"choices": [
			{"label": "收下（习得「审判」，-4 生命）", "hp": -4, "cards": ["审判"]},
			{"label": "问他是谁（+25 金币）", "gold": 25},
			{"label": "离开"},
		],
	},
	{
		"text": "忏悔室的门虚掩着。\n里面有人在说话。\n用的是你的声音。",
		"choices": [
			{"label": "跪下", "next": {
				"text": "「你悔什么？」\n那个声音问。",
				"choices": [
					{"label": "悔恨（回复 20 生命）", "hp": 20, "moral": 5},
					{"label": "悔罪（习得「赎罪」）", "cards": ["赎罪"], "moral": 8},
					{"label": "什么都不说"},
				],
			}},
			{"label": "推开门", "next": {
				"text": "里面空着。\n只有一面镜子。",
				"choices": [
					{"label": "看镜子（习得「妄念」）", "cards": ["妄念"]},
					{"label": "砸碎镜子（+40 金币，-8 生命）", "gold": 40, "hp": -8, "sin": 6},
					{"label": "离开"},
				],
			}},
			{"label": "离开"},
		],
	},
	{
		"text": "一段石阶浮在半空。\n往上没有尽头。",
		"choices": [
			{"label": "爬上去", "next": {
				"text": "阶尽头是一扇门。\n门后传来歌声。",
				"choices": [
					{"label": "推门（习得「圣约」，-10 生命）", "cards": ["圣约"], "hp": -10, "moral": 5},
					{"label": "转身回去（回复 8 生命）", "hp": 8},
				],
			}},
			{"label": "绕开"},
		],
	},
	{
		"text": "一个人蹲在墙边，向你伸出手。\n「给我一点，」他说，「神会还你更多。」",
		"choices": [
			{"label": "给他 30 金币", "gold": -30, "next": {
				"text": "他笑了。\n「好孩子。」\n然后就不见了。",
				"choices": [
					{"label": "捡起地上的东西（习得「誓约」）", "cards": ["誓约"], "moral": 10},
					{"label": "离开", "moral": 5},
				],
			}},
			{"label": "抢他的碗（+20 金币，-6 生命）", "gold": 20, "hp": -6, "sin": 10, "moral": -5},
			{"label": "连他一起抢（+60 金币，-10 生命）", "gold": 60, "hp": -10, "sin": 15, "min_sin": 50},
			{"label": "离开"},
		],
	},
	{
		"text": "一个人跪在神像前。\n嘴唇在动，没有声音。",
		"choices": [
			{"label": "在他旁边跪下", "next": {
				"text": "他终于开口。\n「替我把它说出去。」",
				"choices": [
					{"label": "答应他（习得「忏悔」，-5 生命）", "cards": ["忏悔"], "hp": -5, "moral": 8},
					{"label": "拒绝（+25 金币）", "gold": 25, "sin": 3},
				],
			}},
			{"label": "离开"},
		],
	},
	{
		"text": "一摞经卷在火里烧。\n火是冷的。",
		"choices": [
			{"label": "伸手取出（-12 生命，习得「神国余晖」）", "hp": -12, "cards": ["神国余晖"], "moral": 3},
			{"label": "把手烤暖（回复 10 生命）", "hp": 10},
			{"label": "看它烧完", "next": {
				"text": "灰里剩下一个符号。",
				"choices": [
					{"label": "记下它（习得「圣约」）", "cards": ["圣约"]},
					{"label": "离开"},
				],
			}},
		],
	},
	{
		"text": "门前站着一个残影。\n像在等谁。",
		"choices": [
			{"label": "问他是谁", "next": {
				"text": "「我是你上一次死在这里的样子。」",
				"choices": [
					{"label": "收下他递来的东西（习得「妄念」）", "cards": ["妄念"]},
					{"label": "问他怎么死的（-6 生命，+30 金币）", "gold": 30, "hp": -6, "sin": 3},
					{"label": "沉默地走开"},
				],
			}},
			{"label": "直接穿过去", "hp": -4},
		],
	},
]

func pick(act: int = 1) -> Dictionary:
	var pool: Array = DIVINE_EVENTS if act == 2 else EVENTS
	return pool[randi() % pool.size()]

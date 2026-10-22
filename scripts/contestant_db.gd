extends Node

const CONTESTANTS := {
	"血手": {
		"name": "血手",
		"trait": "好战",
		"desc": "一个只相信刀锋的佣兵。他看你的眼神，像在估量一件武器。",
		"hostile": true,
		"hp": 45, "attack": 7, "pattern": [1, 1, 2],
		"choices": [
			{"label": "「我不想和你打。」", "result": "leave", "text": "他盯了你两秒，让开了路。"},
			{"label": "「你的刀不错。」", "result": "fight"},
			{"label": "「一起走到最后？」", "result": "talk", "text": "「……活着到终点再说。」他把一柄短刃丢给你。", "cards": ["打击"], "ally": true},
		],
		"kill": {"text": "你收起了刀。名册上少了一个名字。", "gold": 50},
		"spare": {"text": "「……记住这次。」他站起来，成了你的盟友。", "ally": true, "cards": ["打击"]},
	},
	"静默者": {
		"name": "静默者",
		"trait": "沉默",
		"desc": "一个从不开口的参赛者，兜帽压得很低。",
		"hostile": false,
		"hp": 40, "attack": 6, "pattern": [1, 1],
		"choices": [
			{"label": "静静站在他旁边", "result": "talk", "text": "他看了你很久，递来一面旧盾。", "cards": ["防御"]},
			{"label": "试探性地靠近", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "你从他身边走过，他没有反应。"},
		],
		"kill": {"text": "他没有发出任何声音。", "gold": 30},
		"spare": {"text": "他向你点了点头，把盾留给了你。", "cards": ["铁壁"]},
	},
	"赌徒": {
		"name": "赌徒",
		"trait": "狡诈",
		"desc": "他手里转着一枚硬币，笑得让人不安。",
		"hostile": true,
		"hp": 42, "attack": 8, "pattern": [1, 2],
		"choices": [
			{"label": "陪他赌一把", "result": "talk", "random": [
				{"text": "「运气不错。」他抛来一袋金币。", "gold": 40},
				{"text": "「愿赌服输。」你的口袋轻了一些。", "gold": -30},
			]},
			{"label": "掀了他的桌子", "result": "fight"},
			{"label": "走开", "result": "leave", "text": "他没有拦你。"},
		],
		"kill": {"text": "他的硬币滚进了缝隙里。", "gold": 70},
		"spare": {"text": "「你会后悔的。」他笑着走了。", "cards": ["快速思考"]},
	},
	"苦修者": {
		"name": "苦修者",
		"trait": "虔诚",
		"desc": "他跪在地上，对着没有神智的雕像祈祷。",
		"hostile": false,
		"hp": 38, "attack": 5, "pattern": [1],
		"choices": [
			{"label": "与他一同祈祷", "result": "talk", "text": "他为你诵了一段祷文，伤口不再疼痛。", "hp": 12},
			{"label": "打断他的祈祷", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "你不想打扰他。"},
		],
		"kill": {"text": "他的祈祷声停了。", "gold": 20},
		"spare": {"text": "他为你祈祷了很久。", "hp": 20},
	},
	"疯女": {
		"name": "疯女",
		"trait": "疯狂",
		"desc": "她哼着不成调的歌，眼睛亮得吓人。",
		"hostile": true,
		"hp": 35, "attack": 9, "pattern": [2, 1, 2],
		"choices": [
			{"label": "听她唱歌", "result": "talk", "random": [
				{"text": "她塞给你一张写满符文的纸。", "cards": ["火球"]},
				{"text": "她突然尖叫着扑上来，你受了伤。", "hp": -10},
			]},
			{"label": "让她闭嘴", "result": "fight"},
			{"label": "悄悄走开", "result": "leave", "text": "她的歌声跟着你走了很远。"},
		],
		"kill": {"text": "歌声终于停了。", "gold": 35},
		"spare": {"text": "她把那张符文纸塞进了你手里，笑着跑了。", "cards": ["火球"]},
	},
	"收藏家": {
		"name": "收藏家",
		"trait": "贪婪",
		"desc": "他背着一整袋卡牌，像背着一座山。",
		"hostile": true,
		"hp": 48, "attack": 6, "pattern": [1, 1, 1],
		"choices": [
			{"label": "出钱买一张牌（-40 金币）", "result": "talk", "text": "「成交。」他抽出一张牌。", "gold": -40, "random_cards": 1},
			{"label": "抢他的袋子", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "你护紧了钱袋。"},
		],
		"kill": {"text": "他的袋子散了一地。", "random_cards": 2},
		"spare": {"text": "他把一袋金币推给你，求你别再看他。", "gold": 40},
	},
	"猎手": {
		"name": "猎手",
		"trait": "冷静",
		"desc": "她蹲在阴影里，擦拭着一支箭。",
		"hostile": true,
		"hp": 44, "attack": 8, "pattern": [1, 2, 1],
		"choices": [
			{"label": "「前面有什么？」", "result": "talk", "text": "「埋伏。」她指了个方向，又塞给你些钱。", "gold": 25, "ally": true},
			{"label": "从背后接近她", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "你避开了她的视线。"},
		],
		"kill": {"text": "她的箭没能射出去。", "gold": 45},
		"spare": {"text": "「你走前面，我掩护。」", "ally": true},
	},
	"无名者": {
		"name": "无名者",
		"trait": "神秘",
		"desc": "他的脸像被雾气抹去了，你记不住他的样子。",
		"hostile": false,
		"hp": 50, "attack": 10, "pattern": [1, 1, 2],
		"choices": [
			{"label": "「你是谁？」", "result": "talk", "text": "「你会需要这个。」声音从很远的地方传来。", "gold": 15, "hp": 8},
			{"label": "伸手去抓他的兜帽", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "你没有回头。"},
		],
		"kill": {"text": "雾气散了，什么也没留下。", "gold": 60},
		"spare": {"text": "「……谢谢。」你第一次听清他的声音。", "hp": 15, "gold": 15},
	},
}

func get_contestant(id: String) -> Dictionary:
	return CONTESTANTS[id]

func name_of(id: String) -> String:
	return CONTESTANTS[id]["name"]

func resolve_cards(reward: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if reward.has("cards"):
		for c in reward["cards"]:
			result.append(str(c))
	if reward.has("random_cards"):
		var count: int = int(reward["random_cards"])
		var pool: Array = CardDB.reward_pool()
		for i in range(count):
			result.append(str(pool[randi() % pool.size()]))
	return result

func pick_roster(count: int) -> Array[String]:
	var pool: Array = CONTESTANTS.keys()
	pool.shuffle()
	var result: Array[String] = []
	for i in range(min(count, pool.size())):
		result.append(pool[i])
	return result

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
		"ally_effect": {"type": "fighter", "damage": 6},
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
		"ally_effect": {"type": "buff", "cards": ["铁壁"]},
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
		"ally_effect": {"type": "buff", "cards": ["快速思考"]},
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
		"ally_effect": {"type": "buff", "hp": 15},
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
		"ally_effect": {"type": "buff", "cards": ["火球"]},
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
		"ally_effect": {"type": "buff", "cards": ["重击"]},
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
		"ally_effect": {"type": "fighter", "damage": 4},
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
		"ally_effect": {"type": "buff", "hp": 10, "gold": 10},
	},
	"断剑客": {
		"name": "断剑客",
		"trait": "好战",
		"desc": "他的剑断了半截，眼神却还完整。",
		"hostile": true,
		"hp": 46, "attack": 8, "pattern": [1, 1, 2],
		"choices": [
			{"label": "把捡到的剑递给他", "result": "talk", "text": "「……算我欠你一次。」", "cards": ["打击"], "ally": true},
			{"label": "嘲笑他的断剑", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "你从他身边走过。"},
		],
		"kill": {"text": "断剑落在地上，声音很轻。", "gold": 50},
		"spare": {"text": "他把断剑插回鞘里，站到了你身后。", "ally": true},
		"ally_effect": {"type": "fighter", "damage": 5},
	},
	"灰袍女": {
		"name": "灰袍女",
		"trait": "沉默",
		"desc": "她坐在废墟里，灰袍下什么也看不清。",
		"hostile": false,
		"hp": 38, "attack": 6, "pattern": [1, 1],
		"choices": [
			{"label": "在她旁边坐下", "result": "talk", "text": "她递给你一小瓶药。", "hp": 15},
			{"label": "掀开她的兜帽", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "她连头都没抬。"},
		],
		"kill": {"text": "灰袍散开，里面空无一物。", "gold": 30},
		"spare": {"text": "她把药瓶塞进你手里。", "hp": 15},
		"ally_effect": {"type": "buff", "hp": 8},
	},
	"双生子": {
		"name": "双生子",
		"trait": "狡诈",
		"desc": "两个人长得一模一样，连笑都一样。",
		"hostile": true,
		"hp": 40, "attack": 9, "pattern": [2, 1],
		"choices": [
			{"label": "猜哪个是哥哥", "result": "talk", "random": [
				{"text": "「猜对了。」他们抛来金币。", "gold": 35},
				{"text": "「猜错了。」两把刀同时出鞘，你受了伤。", "hp": -12},
			]},
			{"label": "两个都打", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "他们笑着看你走远。"},
		],
		"kill": {"text": "倒下的是同一个影子。", "gold": 55},
		"spare": {"text": "「下次见面，我们就不客气了。」", "random_cards": 1},
		"ally_effect": {"type": "buff", "cards": ["快速思考"]},
	},
	"拾荒者": {
		"name": "拾荒者",
		"trait": "贪婪",
		"desc": "他背着一堆从尸体上捡来的东西。",
		"hostile": false,
		"hp": 44, "attack": 5, "pattern": [1],
		"choices": [
			{"label": "买一件（-40 金币）", "result": "talk", "text": "「识货。」他把东西递给你。", "gold": -40, "random_cards": 1},
			{"label": "抢他的包袱", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "他护着包袱退开了。"},
		],
		"kill": {"text": "包袱散开，都是些破烂。", "gold": 40},
		"spare": {"text": "他丢给你几个铜板，求你放他走。", "gold": 30},
		"ally_effect": {"type": "buff", "cards": ["防御"]},
	},
	"盲眼琴师": {
		"name": "盲眼琴师",
		"trait": "神秘",
		"desc": "他的眼睛蒙着布，琴声却从不走调。",
		"hostile": false,
		"hp": 36, "attack": 7, "pattern": [1, 2],
		"choices": [
			{"label": "听完这首曲子", "result": "talk", "text": "琴声落下时，你的伤口不再疼了。", "hp": 14},
			{"label": "打断他的琴弦", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "琴声一直跟着你。"},
		],
		"kill": {"text": "琴断了，世界安静了一瞬。", "gold": 35},
		"spare": {"text": "他为你弹了一段送别的曲子。", "hp": 10, "gold": 10},
		"ally_effect": {"type": "buff", "hp": 10},
	},
	"铁面人": {
		"name": "铁面人",
		"trait": "冷静",
		"desc": "面具下的呼吸很稳，像是从没慌过。",
		"hostile": true,
		"hp": 52, "attack": 8, "pattern": [1, 1, 1],
		"choices": [
			{"label": "问他为什么参赛", "result": "talk", "text": "「为了一个答案。」他丢给你些钱。", "gold": 30},
			{"label": "敲他的面具", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "他目送你离开。"},
		],
		"kill": {"text": "面具掉了下来，下面什么都没有。", "gold": 60},
		"spare": {"text": "「你比我想的沉得住气。」", "ally": true},
		"ally_effect": {"type": "fighter", "damage": 4},
	},
	"焚书人": {
		"name": "焚书人",
		"trait": "疯狂",
		"desc": "他抱着一摞书，火折子已经点着了。",
		"hostile": true,
		"hp": 34, "attack": 10, "pattern": [2, 2],
		"choices": [
			{"label": "抢下一本书", "result": "talk", "random": [
				{"text": "书页里夹着一张卡。", "cards": ["火球"]},
				{"text": "火焰烧到了你的手。", "hp": -12},
			]},
			{"label": "踩灭他的火", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "火光在你背后亮起来。"},
		],
		"kill": {"text": "书烧完了，他也安静了。", "gold": 45},
		"spare": {"text": "他把最后一本书塞给你，笑着走了。", "random_cards": 1},
		"ally_effect": {"type": "buff", "cards": ["火球"]},
	},
	"溺水的旅人": {
		"name": "溺水的旅人",
		"trait": "虚弱",
		"desc": "他瘫在浅水里，连抬手的力气都没有。",
		"hostile": false,
		"hp": 30, "attack": 4, "pattern": [1],
		"choices": [
			{"label": "把他拉起来（-5 HP）", "result": "talk", "text": "他把随身的钱袋塞给你。", "hp": -5, "gold": 40},
			{"label": "搜他的身", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "你没有回头。"},
		],
		"kill": {"text": "水面很快恢复了平静。", "gold": 25},
		"spare": {"text": "他朝你点了点头，慢慢走远了。", "hp": 10},
		"ally_effect": {"type": "buff", "hp": 6},
	},
	"沉默的钟表匠": {
		"name": "沉默的钟表匠",
		"trait": "神秘",
		"desc": "他在修一只永远走不准的表。",
		"hostile": false,
		"hp": 42, "attack": 6, "pattern": [1, 1],
		"choices": [
			{"label": "帮他扶着齿轮", "result": "talk", "text": "表终于走了一格。他把表塞给你。", "cards": ["快速思考"]},
			{"label": "把表抢走", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "滴答声跟着你走了很远。"},
		],
		"kill": {"text": "表停了。", "gold": 40},
		"spare": {"text": "他把修好的表送给了你。", "cards": ["神谕"]},
		"ally_effect": {"type": "buff", "cards": ["快速思考"]},
	},
	"第十位": {
		"name": "第十位",
		"trait": "未知",
		"desc": "名册上写着十个人，可你只见过九个。",
		"hostile": true,
		"hp": 60, "attack": 11, "pattern": [1, 2, 2],
		"choices": [
			{"label": "「你是谁？」", "result": "talk", "random": [
				{"text": "「我是你忘掉的那个。」他给了你一张牌。", "cards": ["审判"]},
				{"text": "「你不需要知道。」你的头开始疼。", "hp": -15},
			]},
			{"label": "直接动手", "result": "fight"},
			{"label": "离开", "result": "leave", "text": "你数了三遍，还是只有九个人。"},
		],
		"kill": {"text": "名册上少了一个名字，你却记不清是谁。", "gold": 70},
		"spare": {"text": "「下次别再忘了。」", "ally": true},
		"ally_effect": {"type": "fighter", "damage": 6},
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
func scaled(id: String) -> Dictionary:
	var c: Dictionary = CONTESTANTS[id].duplicate()
	var mult: float = 1.0 + 0.15 * float(GameState.transmigration - 1)
	var result := c.duplicate()
	result["hp"] = int(float(c["hp"]) * mult)
	result["attack"] = int(float(c["attack"]) * mult)
	return result

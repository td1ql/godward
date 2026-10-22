extends Node

const TRAITS := {
	"强健": {"desc": "最大生命 +25", "hp": 25},
	"富裕": {"desc": "初始金币 +40", "gold": 40},
	"敏锐": {"desc": "起手手牌 +1", "hand": 1},
	"神眷": {"desc": "牌组 +2 张随机卡", "cards": 2},
	"好战": {"desc": "每场战斗开局 +3 力量", "strength": 3},
	"精算": {"desc": "每回合能量 +1", "energy": 1},
	"残躯": {"desc": "最大生命 -15", "hp": -15},
	"健忘": {"desc": "起手手牌 -1", "hand": -1},
	"枯竭": {"desc": "每场战斗开局 -1 力量", "strength": -1},
	"迟滞": {"desc": "每回合能量 -1", "energy": -1},
}

const VOCATIONS := {
	"等待丈夫的新娘": {"desc": "她在神域尽头等了太久。", "traits": ["敏锐", "神眷", "残躯"], "card": "守夜", "remnant": "她背对着你，还在等一个不会回来的人。"},
	"失明的守钟人": {"desc": "他听不见钟声，却一直在敲。", "traits": ["强健", "健忘", "好战"], "card": "灯", "remnant": "他还在敲，敲给一个听不见的人。"},
	"饥饿的朝圣者": {"desc": "他走了很远，胃里空空。", "traits": ["富裕", "残躯", "健忘"], "card": "遗志", "remnant": "他把最后一点力气留给了你。"},
	"沉默的执剑人": {"desc": "剑比话多。", "traits": ["强健", "好战", "迟滞"], "card": "遗恨", "remnant": "他倒下的姿势，像还握着剑。"},
	"疯癫的先知": {"desc": "她看见了不该看见的东西。", "traits": ["神眷", "精算", "残躯"], "card": "遗忘", "remnant": "她在你耳边说了一个名字，然后忘了。"},
	"褴褛的记账人": {"desc": "他记着每一笔债。", "traits": ["富裕", "敏锐", "迟滞"], "card": "遗言", "remnant": "账本最后一页，写着你的名字。"},
	"断臂的旗手": {"desc": "旗还在，手没了。", "traits": ["好战", "强健", "健忘"], "card": "最后一击", "remnant": "旗子还插在那里，人已经不见了。"},
	"无名的旅人": {"desc": "你记不住他的脸。", "traits": ["敏锐", "富裕", "强健"], "card": "未竟", "remnant": "他走的路，你好像也走过。"},
	"溺水的旅人": {"desc": "他还在水里，看着岸上的你。", "traits": ["残躯", "敏锐", "迟滞"], "card": "旧伤", "remnant": "水面上浮着一张牌，他把它推给了你。"},
	"焚书的疯子": {"desc": "他烧掉了所有能读的东西。", "traits": ["神眷", "精算", "健忘"], "card": "余烬", "remnant": "火还没熄，他已经不说话了。"},
	"守夜的哨兵": {"desc": "他站了一整夜，没等到换班的人。", "traits": ["强健", "敏锐", "迟滞"], "card": "回望", "remnant": "他还在原地，往你来的方向看。"},
	"数星的瞎子": {"desc": "他数着看不见的星星。", "traits": ["健忘", "神眷", "精算"], "card": "长夜", "remnant": "他数到第几千颗，就不数了。"},
	"磨刀的哑巴": {"desc": "刀磨得很亮，人却不说话。", "traits": ["好战", "健忘", "富裕"], "card": "断章", "remnant": "刀还在石头上，一下，又一下。"},
	"收尸的妇人": {"desc": "她替所有人合上过眼睛。", "traits": ["残躯", "富裕", "好战"], "card": "旧誓", "remnant": "她替你理了理衣领：「这次别躺着回来。」"},
	"未亡的棋手": {"desc": "棋盘上只剩最后一子。", "traits": ["敏锐", "富裕", "精算"], "card": "残响", "remnant": "他把那颗棋子放进你手里。"},
	"等死的病人": {"desc": "他还在等一个不会来的医生。", "traits": ["残躯", "枯竭", "神眷"], "card": "执念", "remnant": "他抓着你的袖子，说：「再等一下。」"},
}

func roll_vocation() -> String:
	var pool: Array = VOCATIONS.keys()
	return str(pool[randi() % pool.size()])

func traits_of(vocation: String) -> Array[String]:
	var result: Array[String] = []
	if VOCATIONS.has(vocation):
		for t in VOCATIONS[vocation]["traits"]:
			result.append(str(t))
	return result

func vocation_text(vocation: String) -> String:
	if not VOCATIONS.has(vocation):
		return ""
	return "%s（%s）" % [vocation, VOCATIONS[vocation]["desc"]]

func roll() -> Array[String]:
	var pool: Array = TRAITS.keys()
	pool.shuffle()
	var count: int = randi_range(2, 3)
	var result: Array[String] = []
	for i in range(min(count, pool.size())):
		result.append(pool[i])
	return result

func text_of(traits: Array[String]) -> String:
	var s := ""
	for t in traits:
		if s != "":
			s += " / "
		s += "%s（%s）" % [t, TRAITS[t]["desc"]]
	return s

func total_hp(traits: Array[String]) -> int:
	var v := 0
	for t in traits:
		v += int(TRAITS[t].get("hp", 0))
	return v

func total_gold(traits: Array[String]) -> int:
	var v := 0
	for t in traits:
		v += int(TRAITS[t].get("gold", 0))
	return v

func total_hand(traits: Array[String]) -> int:
	var v := 0
	for t in traits:
		v += int(TRAITS[t].get("hand", 0))
	return v

func total_strength(traits: Array[String]) -> int:
	var v := 0
	for t in traits:
		v += int(TRAITS[t].get("strength", 0))
	return v

func total_energy(traits: Array[String]) -> int:
	var v := 0
	for t in traits:
		v += int(TRAITS[t].get("energy", 0))
	return v

func bonus_cards(traits: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var pool: Array = RewardDB.pool_for("battle", 1)
	for t in traits:
		if TRAITS[t].has("card"):
			result.append(str(TRAITS[t]["card"]))
		var n: int = int(TRAITS[t].get("cards", 0))
		for i in range(n):
			result.append(str(pool[randi() % pool.size()]))
	return result

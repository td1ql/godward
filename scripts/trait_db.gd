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
	"等待丈夫的新娘": {"desc": "她在神域尽头等了太久。", "traits": ["敏锐", "神眷", "残躯"], "card": "守夜", "remnant": "她背对着你，还在等一个不会回来的人。", "creed": {"key": "first_hurt_half", "value": 0, "name": "等", "desc": "每场战斗第一次受到的伤害减半"}},
	"失明的守钟人": {"desc": "他听不见钟声，却一直在敲。", "traits": ["强健", "健忘", "好战"], "card": "灯", "remnant": "他还在敲，敲给一个听不见的人。", "creed": {"key": "turn_block", "value": 4, "name": "敲", "desc": "每回合开始获得 4 格挡"}},
	"饥饿的朝圣者": {"desc": "他走了很远，胃里空空。", "traits": ["富裕", "残躯", "健忘"], "card": "遗志", "remnant": "他把最后一点力气留给了你。", "creed": {"key": "win_heal", "value": 8, "name": "饥", "desc": "战斗胜利回复 8 生命"}},
	"沉默的执剑人": {"desc": "剑比话多。", "traits": ["强健", "好战", "迟滞"], "card": "遗恨", "remnant": "他倒下的姿势，还握着剑。", "creed": {"key": "no_attack_bonus", "value": 150, "name": "静", "desc": "本回合未出攻击牌，下回合伤害 +50%"}},
	"疯癫的先知": {"desc": "她看见了不该看见的东西。", "traits": ["神眷", "精算", "残躯"], "card": "遗忘", "remnant": "她在你耳边说了一个名字，然后忘了。", "creed": {"key": "effect_draw", "value": 1, "name": "谵", "desc": "每打出一张效果牌，抽 1 张"}},
	"褴褛的记账人": {"desc": "他记着每一笔债。", "traits": ["富裕", "敏锐", "迟滞"], "card": "遗言", "remnant": "账本最后一页，写着你的名字。", "creed": {"key": "hurt_gold", "value": 0, "name": "债", "desc": "战斗胜利时，额外获得等同于本场承受伤害的金币"}},
	"断臂的旗手": {"desc": "旗还在，手没了。", "traits": ["好战", "强健", "健忘"], "card": "最后一击", "remnant": "旗子还插在那里，人已经不见了。", "creed": {"key": "first_attack_double", "value": 0, "name": "残", "desc": "每回合第一张攻击牌伤害翻倍"}},
	"无名的旅人": {"desc": "你记不住他的脸。", "traits": ["敏锐", "富裕", "强健"], "card": "未竟", "remnant": "他走的路，你好像也走过。", "creed": {"key": "start_draw", "value": 2, "name": "忘", "desc": "每场战斗开局多抽 2 张"}},
	"溺水的旅人": {"desc": "他还在水里，看着岸上的你。", "traits": ["残躯", "敏锐", "迟滞"], "card": "旧伤", "remnant": "水面上浮着一张牌，他把它推给了你。", "creed": {"key": "hurt_energy", "value": 1, "name": "溺", "desc": "每次受伤获得 1 点能量"}},
	"焚书的疯子": {"desc": "他烧掉了所有能读的东西。", "traits": ["神眷", "精算", "健忘"], "card": "余烬", "remnant": "火还没熄，他已经不说话了。", "creed": {"key": "effect_damage", "value": 4, "name": "焚", "desc": "每打出一张效果牌，对敌人造成 4 伤害"}},
	"守夜的哨兵": {"desc": "他站了一整夜，没等到换班的人。", "traits": ["强健", "敏锐", "迟滞"], "card": "回望", "remnant": "他还在原地，往你来的方向看。", "creed": {"key": "turn_block", "value": 6, "name": "守", "desc": "每回合开始获得 6 格挡"}},
	"数星的瞎子": {"desc": "他数着看不见的星星。", "traits": ["健忘", "神眷", "精算"], "card": "长夜", "remnant": "他数到第几千颗，就不数了。", "creed": {"key": "start_draw", "value": 3, "name": "数", "desc": "每场战斗开局多抽 3 张"}},
	"磨刀的哑巴": {"desc": "刀磨得很亮，人却不说话。", "traits": ["好战", "健忘", "富裕"], "card": "断章", "remnant": "刀还在石头上，一下，又一下。", "creed": {"key": "first_attack_bonus", "value": 8, "name": "磨", "desc": "每回合第一张攻击牌 +8 伤害"}},
	"收尸的妇人": {"desc": "她替所有人合上过眼睛。", "traits": ["残躯", "富裕", "好战"], "card": "旧誓", "remnant": "她替你理了理衣领：「这次别躺着回来。」", "creed": {"key": "win_heal", "value": 10, "name": "殓", "desc": "战斗胜利回复 10 生命"}},
	"未亡的棋手": {"desc": "棋盘上只剩最后一子。", "traits": ["敏锐", "富裕", "精算"], "card": "残响", "remnant": "他把那颗棋子放进你手里。", "creed": {"key": "effect_draw", "value": 2, "name": "局", "desc": "每打出一张效果牌，抽 2 张"}},
	"等死的病人": {"desc": "他还在等一个不会来的医生。", "traits": ["残躯", "枯竭", "神眷"], "card": "执念", "remnant": "他抓着你的袖子，说：「再等一下。」", "creed": {"key": "low_hp_bonus", "value": 150, "name": "待", "desc": "生命低于 30% 时，伤害 +50%"}},
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

func creed_of(vocation: String) -> Dictionary:
	if not VOCATIONS.has(vocation):
		return {}
	return VOCATIONS[vocation].get("creed", {})

func creed_text(vocation: String) -> String:
	var c := creed_of(vocation)
	if c.is_empty():
		return ""
	return "%s：%s" % [str(c.get("name", "")), str(c.get("desc", ""))]

const VOCATION_DECKS := {
	"等待丈夫的新娘": ["守空房", "望归", "来信", "久候"],
	"失明的守钟人": ["敲钟", "回音", "钟摆", "余响"],
	"饥饿的朝圣者": ["啃食", "省粮", "远路", "空腹"],
	"沉默的执剑人": ["剑息", "蓄刃", "吐锋", "归鞘"],
	"疯癫的先知": ["谵语", "窥视", "妄言", "预兆"],
	"褴褛的记账人": ["记债", "赊账", "结账", "利滚利"],
	"断臂的旗手": ["擎旗", "冲锋", "旗不倒", "断臂旗"],
	"无名的旅人": ["启程", "行囊", "夜路", "归途"],
	"溺水的旅人": ["呛水", "浮木", "打捞", "深潜"],
	"焚书的疯子": ["火折", "翻页", "焚页", "余温"],
	"守夜的哨兵": ["放哨", "示警", "夜巡", "轮值"],
	"数星的瞎子": ["数星", "星位", "流星", "星辉"],
	"磨刀的哑巴": ["磨刃", "试刀", "开刃", "哑声"],
	"收尸的妇人": ["合眼", "入殓", "白布", "送行"],
	"未亡的棋手": ["落子", "布局", "将军", "残局"],
	"等死的病人": ["咳嗽", "药渣", "回光", "最后一眼"],
}

func deck_of(vocation: String) -> Array[String]:
	var result: Array[String] = []
	for c in VOCATION_DECKS.get(vocation, []):
		result.append(str(c))
	return result

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
	"等待丈夫的新娘": {"desc": "她总是立于荒原远眺，等着那个不会回来的人", "traits": ["敏锐", "神眷", "残躯"], "card": "守夜", "remnant": "她已不愿等待，她要去找他了", "creed": {"key": "first_hurt_zero", "value": 0, "name": "等", "desc": "每场战斗免疫第一次受到的伤害"}},
	"失明的守钟人": {"desc": "他一遍又一遍的敲打着大钟，只为了掩盖乡亲们的惨叫。", "traits": ["强健", "健忘", "好战"], "card": "灯", "remnant": "他还在敲着钟，为了那些无法再听到之人。", "creed": {"key": "turn_block", "value": 6, "name": "敲", "desc": "每回合开始获得 6 格挡"}},
	"饥饿的朝圣者": {"desc": "跪拜着前行，跪拜着死去", "traits": ["富裕", "残躯", "健忘"], "card": "遗志", "remnant": "跪拜是野兽的行径，挺直你的脊梁", "creed": {"key": "win_heal", "value": 8, "name": "饥", "desc": "战斗胜利回复 8 生命"}},
	"沉默的执剑人": {"desc": "他的过去太过沉重，压得他开不了口", "traits": ["强健", "好战", "神眷", "迟滞"], "card": "遗恨", "remnant": "只留下一柄染血的长剑，和未结的遗恨", "creed": {"key": "no_attack_bonus", "value": 150, "name": "静", "desc": "本回合未出攻击牌，下回合伤害 +50%"}},
	"疯癫的先知": {"desc": "她本是最伟大之人", "traits": ["神眷", "精算", "残躯"], "card": "遗忘", "remnant": "你记得些什么，你忘了些什么", "creed": {"key": "effect_draw", "value": 1, "name": "谵", "desc": "每打出一张效果牌，抽 1 张"}},
	"褴褛的记账人": {"desc": "他总是沉默寡言，他总是郁郁寡欢，你欠我的，他也欠我的。", "traits": ["富裕", "敏锐", "强健", "迟滞"], "card": "遗言", "remnant": "该还债了", "creed": {"key": "hurt_gold", "value": 0, "name": "债", "desc": "战斗胜利时，额外获得等同于本场承受伤害的金币"}},
	"断臂的旗手": {"desc": "哪怕我的脊梁被折断，哪怕我的尸首被掩埋，但它永远高扬！", "traits": ["好战", "强健", "健忘"], "card": "最后一击", "remnant": "在那满地枯骨之中，一面血色的旗帜高高飘扬", "creed": {"key": "first_attack_double", "value": 0, "name": "残", "desc": "每回合第一张攻击牌伤害翻倍"}},
	"无名的旅人": {"desc": "你记不住他的脸，谁记得住他的脸", "traits": ["敏锐", "富裕", "强健"], "card": "未竟", "remnant": "他走的路，你好像也走过。", "creed": {"key": "start_draw", "value": 2, "name": "忘", "desc": "每场战斗开局多抽 2 张"}},
	"溺水的小公主": {"desc": "她在深埋的罪孽中永恒沉沦", "traits": ["残躯", "敏锐", "好战", "迟滞"], "card": "旧伤", "remnant": "于是沉沦，将一切的过往埋入水中", "creed": {"key": "hurt_energy", "value": 1, "name": "溺", "desc": "每次受伤获得 1 点能量"}},
	"焚书的疯子": {"desc": "他烧掉了所有能读的东西。", "traits": ["神眷", "精算", "健忘"], "card": "余烬", "remnant": "熊熊燃烧！！！熊熊燃烧！！！", "creed": {"key": "effect_damage", "value": 6, "name": "焚", "desc": "每打出一张效果牌，对敌人造成 6 伤害"}},
	"守夜的哨兵": {"desc": "他站了一整夜，但换班的人已经不会来了。", "traits": ["强健", "敏锐", "神眷", "迟滞"], "card": "回望", "remnant": "他依旧站在原地，往你来的方向远眺", "creed": {"key": "keep_block", "value": 0, "name": "守", "desc": "格挡不会在回合结束时清空"}},
	"数星星的瞎子": {"desc": "他数着看不见的星星，一颗一颗，一颗一颗", "traits": ["健忘", "神眷", "精算"], "card": "长夜", "remnant": "他依旧望着天空，璀璨华光在他眼眶中流转，像是他的眼泪。", "creed": {"key": "start_draw", "value": 3, "name": "数", "desc": "每场战斗开局多抽 3 张"}},
	"磨刀的哑巴": {"desc": "刀磨得很亮，人却不说话。", "traits": ["好战", "健忘", "富裕"], "card": "断章", "remnant": "刀还在石头上，一下，又一下。", "creed": {"key": "first_attack_bonus", "value": 8, "name": "磨", "desc": "每回合第一张攻击牌 +8 伤害"}},
	"收尸的妇人": {"desc": "她替所有人合上过眼睛。", "traits": ["残躯", "富裕", "好战"], "card": "旧誓", "remnant": "她替你理了理衣领：「这次别躺着回来。」", "creed": {"key": "kill_pick", "value": 1, "name": "殓", "desc": "杀死敌人后可以额外选择一张手牌"}},
	"执棋未落的妙手": {"desc": "这最后一子，敢叫日月换新天。", "traits": ["敏锐", "富裕", "精算"], "card": "残响", "remnant": "他把那颗棋子放进你手里。", "creed": {"key": "effect_draw", "value": 2, "name": "局", "desc": "每打出一张效果牌，抽 2 张"}},
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
	"溺水的小公主": ["呛水", "浮木", "打捞", "深潜"],
	"焚书的疯子": ["火折", "翻页", "焚页", "余温"],
	"守夜的哨兵": ["放哨", "示警", "夜巡", "轮值"],
	"数星星的瞎子": ["数星", "星位", "流星", "星辉"],
	"磨刀的哑巴": ["磨刃", "试刀", "开刃", "哑声"],
	"收尸的妇人": ["合眼", "入殓", "白布", "送行"],
	"执棋未落的妙手": ["落子", "布局", "将军", "残局"],
	"等死的病人": ["咳嗽", "药渣", "回光", "最后一眼"],
}

func deck_of(vocation: String) -> Array[String]:
	var result: Array[String] = []
	for c in VOCATION_DECKS.get(vocation, []):
		result.append(str(c))
	return result

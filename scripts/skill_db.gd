extends Node

# ============================================================
# SkillDB —— 16 个职业的专属技能
# ------------------------------------------------------------
# 每个技能有一个「触发条件」（战斗里满足才亮），
# 使用后播放演出动画，然后结算效果。
#
# 条件 kind：
#   no_attack_3   连续 3 回合没出过攻击牌
#   turn_min_5    第 5 回合之后
#   hp_below_30   生命低于 30%
#   block_zero    格挡归零
#   hand_min_6    手牌 >= 6 张
#   damage_taken  本场受过 >= 20 伤害
#   energy_zero   能量归零
#   enemy_poison  敌人中毒 >= 5
#
# 效果字段：
#   block / heal / energy / draw
#   damage_all / damage_one / damage_self_hp_pct
#   status_all / status_self
#   mult_next（本回合攻击倍率）
# ============================================================

const SKILLS := {
	"等待丈夫的新娘": {
		"name": "守望",
		"en": "VIGIL",
		"cond": "no_attack_3",
		"hint": "连续三回合不曾出手",
		"line": "她把手放在胸口，站住了。",
		"effect": {"block": 28, "status_all": {"虚弱": 3}},
		"fx": "guard",
	},
	"失明的守钟人": {
		"name": "报时",
		"en": "TOLL",
		"cond": "turn_min_5",
		"hint": "第五回合之后",
		"line": "他敲了一下钟。声音从很远的地方回来。",
		"effect": {"damage_all": 18, "status_all": {"易伤": 2}},
		"fx": "bell",
	},
	"饥饿的朝圣者": {
		"name": "空腹",
		"en": "FAST",
		"cond": "hp_below_30",
		"hint": "生命低于三成",
		"line": "他张开手，掌心什么也没有。",
		"effect": {"heal": 25, "energy": 2},
		"fx": "heal",
	},
	"沉默的执剑人": {
		"name": "出鞘",
		"en": "UNSHEATHE",
		"cond": "no_attack_3",
		"hint": "连续三回合不曾出手",
		"line": "剑终于离开鞘。没有声音。",
		"effect": {"damage_all": 26},
		"fx": "slash",
	},
	"疯癫的先知": {
		"name": "妄言",
		"en": "RANT",
		"cond": "hand_min_6",
		"hint": "手牌六张以上",
		"line": "他念出了一段谁也不懂的预言。",
		"effect": {"damage_all": 14, "status_self": {"力量": 4}},
		"fx": "mind",
	},
	"褴褛的记账人": {
		"name": "结算",
		"en": "SETTLE",
		"cond": "turn_min_5",
		"hint": "第五回合之后",
		"line": "他翻开账本，把这一页撕了下来。",
		"effect": {"damage_all": 12, "draw": 2, "energy": 1},
		"fx": "ledger",
	},
	"断臂的旗手": {
		"name": "举旗",
		"en": "RAISE",
		"cond": "hp_below_30",
		"hint": "生命低于三成",
		"line": "他把旗举了起来，尽管旗早已不在。",
		"effect": {"mult_next": 2.0, "status_self": {"力量": 3}},
		"fx": "flag",
	},
	"无名的旅人": {
		"name": "过路",
		"en": "PASS BY",
		"cond": "energy_zero",
		"hint": "能量见底",
		"line": "他只是路过。",
		"effect": {"energy": 3, "draw": 2, "block": 12},
		"fx": "step",
	},
	"溺水的小公主": {
		"name": "下沉",
		"en": "SINK",
		"cond": "block_zero",
		"hint": "格挡被打空",
		"line": "她往下沉了一点，然后又站住了。",
		"effect": {"block": 40, "status_self": {"再生": 3}},
		"fx": "water",
	},
	"焚书的疯子": {
		"name": "焚",
		"en": "BURN",
		"cond": "hand_min_6",
		"hint": "手牌六张以上",
		"line": "他把手里的东西点着了。",
		"effect": {"burn_hand": true, "damage_per_card": 7},
		"fx": "fire",
	},
	"守夜的哨兵": {
		"name": "换班",
		"en": "WATCH",
		"cond": "turn_min_5",
		"hint": "第五回合之后",
		"line": "他往黑暗里看了一眼，什么也没说。",
		"effect": {"block": 20, "status_all": {"虚弱": 2}, "energy": 1},
		"fx": "guard",
	},
	"数星星的瞎子": {
		"name": "数",
		"en": "COUNT",
		"cond": "no_attack_3",
		"hint": "连续三回合不曾出手",
		"line": "他仰起头，开始数。",
		"effect": {"draw": 3, "energy": 2, "status_self": {"洞察": 2}},
		"fx": "star",
	},
	"磨刀的哑巴": {
		"name": "开锋",
		"en": "HONE",
		"cond": "turn_min_5",
		"hint": "第五回合之后",
		"line": "刀磨好了。他把它推给你。",
		"effect": {"mult_next": 2.5},
		"fx": "blade",
	},
	"收尸的妇人": {
		"name": "合眼",
		"en": "CLOSE EYES",
		"cond": "damage_taken",
		"hint": "本场受过二十点以上伤害",
		"line": "她蹲下来，替看不见的人合上了眼睛。",
		"effect": {"heal": 18, "status_all": {"易伤": 2}, "block": 15},
		"fx": "heal",
	},
	"执棋未落的妙手": {
		"name": "落子",
		"en": "MATE",
		"cond": "enemy_poison",
		"hint": "敌人中毒五层以上",
		"line": "他落了一子。棋盘上没有别的子了。",
		"effect": {"damage_per_poison": 6},
		"fx": "chess",
	},
	"等死的病人": {
		"name": "了断",
		"en": "END",
		"cond": "turn_min_5",
		"hint": "第五回合之后",
		"line": "他笑了一下。",
		"effect": {"damage_self_hp_pct": 0.5},
		"fx": "end",
	},
}


func has(vocation: String) -> bool:
	return SKILLS.has(vocation)


func info_of(vocation: String) -> Dictionary:
	return SKILLS.get(vocation, {})


func name_of(vocation: String) -> String:
	return str(info_of(vocation).get("name", ""))


func en_of(vocation: String) -> String:
	return str(info_of(vocation).get("en", ""))


func line_of(vocation: String) -> String:
	return str(info_of(vocation).get("line", ""))


func hint_of(vocation: String) -> String:
	return str(info_of(vocation).get("hint", ""))


func fx_of(vocation: String) -> String:
	return str(info_of(vocation).get("fx", "guard"))


func effect_of(vocation: String) -> Dictionary:
	return info_of(vocation).get("effect", {})


# 判断条件是否满足（battle 传一个字典进来）
func ready(vocation: String, st: Dictionary) -> bool:
	var cond := str(info_of(vocation).get("cond", ""))
	match cond:
		"no_attack_3":
			return int(st.get("no_attack_turns", 0)) >= 3
		"turn_min_5":
			return int(st.get("turn", 0)) >= 5
		"hp_below_30":
			var mx := int(st.get("max_hp", 1))
			return mx > 0 and float(st.get("hp", mx)) / float(mx) < 0.3
		"block_zero":
			return int(st.get("block", 1)) <= 0 and int(st.get("turn", 0)) >= 2
		"hand_min_6":
			return int(st.get("hand", 0)) >= 6
		"damage_taken":
			return int(st.get("damage_taken", 0)) >= 20
		"energy_zero":
			return int(st.get("energy", 1)) <= 0 and int(st.get("turn", 0)) >= 2
		"enemy_poison":
			return int(st.get("enemy_poison", 0)) >= 5
	return false

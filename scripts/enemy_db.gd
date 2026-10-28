extends Node

const NORMAL := {
	"史莱姆": {"name": "史莱姆", "hp": 30, "attack": 5, "pattern": [1, 1]},
	"哥布林": {"name": "哥布林", "hp": 35, "attack": 6, "pattern": [1, 1, 2]},
	"骷髅兵": {"name": "骷髅兵", "hp": 40, "attack": 6, "pattern": [1, 1.5, 2]},
	"毒蜘蛛": {"name": "毒蜘蛛", "hp": 28, "attack": 4, "pattern": [1, 1], "skills": [{"every": 2, "to": "player", "status": {"中毒": 2}, "name": "毒牙"}]},
	"狂徒": {"name": "狂徒", "hp": 38, "attack": 5, "pattern": [1, 1, 1], "skills": [{"every": 2, "to": "self", "status": {"力量": 1}, "name": "蓄力"}]},
	"腐化史莱姆": {"name": "腐化史莱姆", "hp": 32, "attack": 4, "pattern": [1, 1], "skills": [{"every": 2, "to": "self", "status": {"再生": 2}, "name": "再生"}]},
	"咒术师": {"name": "咒术师", "hp": 34, "attack": 5, "pattern": [1, 2], "on_hit": {"虚弱": 1}},
	"荆棘兽": {"name": "荆棘兽", "hp": 45, "attack": 6, "pattern": [1, 1], "skills": [{"every": 2, "to": "self", "status": {"荆棘": 2}, "name": "荆棘"}]},
	"蝙蝠群": {"name": "蝙蝠群", "hp": 26, "attack": 4, "pattern": [1, 1, 1]},
	"石像鬼": {"name": "石像鬼", "hp": 40, "attack": 6, "pattern": [1, 2], "on_turn": {"荆棘": 1}},
	"腐尸": {"name": "腐尸", "hp": 42, "attack": 5, "pattern": [1, 1], "on_hit": {"中毒": 1}},
	"火元素": {"name": "火元素", "hp": 36, "attack": 4, "pattern": [2, 1], "on_turn": {"力量": 1}},
	"冰霜精": {"name": "冰霜精", "hp": 30, "attack": 5, "pattern": [1, 2], "on_hit": {"虚弱": 1}},
	"食人魔": {"name": "食人魔", "hp": 55, "attack": 8, "pattern": [1, 2, 1.5]},
}

const ELITE := {
	"双子刺客": {"name": "双子刺客", "hp": 60, "attack": 10, "pattern": [2, 0.5, 0.5, 1], "on_hit": {"流血": 2}},
	"亡灵骑士": {"name": "亡灵骑士", "hp": 85, "attack": 6, "pattern": [1, 1, 2], "skills": [{"every": 2, "to": "self", "status": {"再生": 2}, "name": "再生"}]},
	"熔岩巨像": {"name": "熔岩巨像", "hp": 95, "attack": 8, "pattern": [1, 2], "skills": [{"every": 3, "to": "self", "status": {"荆棘": 4}, "name": "荆棘"}]},
	"精英守卫": {"name": "精英守卫", "hp": 65, "attack": 8, "pattern": [1, 1, 1], "skills": [{"every": 2, "to": "self", "status": {"荆棘": 2}, "name": "荆棘"}]},
	"精英法师": {"name": "精英法师", "hp": 55, "attack": 8, "pattern": [1, 1.5], "on_hit": {"虚弱": 2}, "on_turn": {"力量": 1}},
	"血祭司": {"name": "血祭司", "hp": 60, "attack": 6, "pattern": [1, 1.5, 2], "skills": [{"every": 2, "to": "player", "status": {"流血": 3}, "name": "流血"}, {"every": 3, "to": "self", "status": {"再生": 8}, "name": "再生"}]},
	"断头骑士": {"name": "断头骑士", "hp": 72, "attack": 9, "pattern": [1, 1.5], "on_turn": {"力量": 1}},
	"缢死者": {"name": "缢死者", "hp": 58, "attack": 5, "pattern": [1, 2], "on_hit": {"中毒": 2}, "skills": [{"every": 3, "to": "player", "status": {"虚弱": 2}, "name": "垂颈"}]},
	"圣骸行者": {"name": "圣骸行者", "hp": 90, "attack": 7, "pattern": [1, 1, 2], "skills": [{"every": 2, "to": "self", "status": {"荆棘": 2}, "name": "碎骨"}]},
	"书记官": {"name": "书记官", "hp": 62, "attack": 8, "pattern": [1, 1.5], "skills": [{"every": 2, "to": "player", "status": {"易伤": 2}, "name": "宣判"}]},
	"灰烬修女": {"name": "灰烬修女", "hp": 74, "attack": 6, "pattern": [1, 1.5, 2], "skills": [{"every": 3, "to": "player", "status": {"流血": 3}, "name": "祝祷"}]},
	"无面乐师": {"name": "无面乐师", "hp": 60, "attack": 9, "pattern": [2, 1, 1], "skills": [{"every": 2, "to": "player", "status": {"虚弱": 1}, "name": "哀歌"}]},
}

const BOSS := {
	"守门人": {"name": "守门人", "hp": 100, "attack": 10, "pattern": [1, 1.5, 1, 2], "on_hit": {"易伤": 1}, "on_turn": {"力量": 1}, "skills":[{"every": 2, "to": "player", "status": {"流血": 2}, "name": "流血"}, {"every": 3, "to": "self", "status": {"再生": 3}, "name": "再生"}]},
	"奥古斯丁": {"name": "奥古斯丁", "hp": 115, "attack": 9, "pattern": [1, 1, 2, 1.5], "domain": {"type": "no_heal", "value": 1}, "skills": [{"every": 2, "to": "player", "status": {"虚弱": 2}, "name": "忏悔"}, {"every": 4, "to": "self", "heal": 14, "name": "记述"}]},
	"安布罗斯": {"name": "安布罗斯", "hp": 105, "attack": 8, "pattern": [1, 2, 1, 1], "skills": [{"every": 3, "to": "self", "status": {"力量": 3}, "name": "圣歌"}, {"every": 4, "to": "self", "status": {"再生": 5}, "name": "合唱"}]},
	"耶柔米": {"name": "耶柔米", "hp": 70, "attack": 11, "pattern": [1.5, 1, 1, 2], "domain": {"type": "cost_up", "value": 1}, "skills": [{"every": 3, "to": "player", "status": {"易伤": 2}, "name": "译注"}]},
	"格里高利": {"name": "格里高利", "hp": 120, "attack": 9, "pattern": [1, 1, 1, 2.5], "domain": {"type": "thorns_aura", "value": 3}, "skills": [{"every": 2, "to": "self", "status": {"荆棘": 3}, "name": "围墙"}]},
	"金口约翰": {"name": "金口约翰", "hp": 98, "attack": 10, "pattern": [1, 2, 2, 1], "domain": {"type": "weak_aura", "value": 1}, "skills": [{"every": 2, "to": "player", "status": {"易伤": 2}, "name": "布道"}, {"every": 3, "to": "self", "status": {"力量": 2}, "name": "金口"}]},
}

const DIVINE := {
	"悔罪者": {"name": "悔罪者", "hp": 58, "attack": 8, "pattern": [1, 1], "skills": [{"every": 2, "to": "player", "status": {"虚弱": 1}, "name": "鞭笞"}]},
	"盲眼先知": {"name": "盲眼先知", "hp": 62, "attack": 10, "pattern": [1, 2], "skills": [{"every": 2, "to": "self", "status": {"再生": 2}, "name": "预见"}]},
	"祈祷者": {"name": "祈祷者", "hp": 55, "attack": 9, "pattern": [1, 1, 2], "skills": [{"every": 2, "to": "self", "status": {"再生": 2}, "name": "祈祷"}, {"every": 3, "to": "player", "status": {"虚弱": 1}, "name": "低语"}]},
	"圣像": {"name": "圣像", "hp": 75, "attack": 7, "pattern": [1, 2], "skills": [{"every": 3, "to": "player", "status": {"虚弱": 2}, "name": "凝视"}]},
	"唱诗班": {"name": "唱诗班", "hp": 50, "attack": 11, "pattern": [2, 1], "skills": [{"every": 2, "to": "player", "status": {"流血": 2}, "name": "圣歌"}]},
	"苦行僧": {"name": "苦行僧", "hp": 60, "attack": 8, "pattern": [1, 2], "skills": [{"every": 3, "to": "self", "status": {"力量": 2}, "name": "苦修"}]},
	"荆棘像": {"name": "荆棘像", "hp": 65, "attack": 6, "pattern": [1, 1], "skills": [{"every": 3, "to": "self", "status": {"荆棘": 4}, "name": "硬化"}]},
}

const DIVINE_ELITE := {
	"圣骸": {"name": "圣骸", "hp": 105, "attack": 11, "pattern": [1, 1, 1, 2], "skills": [{"every": 2, "to": "self", "status": {"荆棘": 3}, "name": "骨刺"}, {"every": 4, "to": "self", "heal": 12, "name": "重组"}]},
	"逐神者": {"name": "逐神者", "hp": 100, "attack": 12, "pattern": [1, 1.5, 2, 2], "skills": [{"every": 2, "to": "self", "status": {"力量": 2}, "name": "狂信"}, {"every": 3, "to": "player", "status": {"易伤": 2}, "name": "残存神威"}]},
	"审判者": {"name": "审判者", "hp": 85, "attack": 13, "pattern": [1, 2, 2], "skills": [{"every": 2, "to": "player", "status": {"易伤": 2}, "name": "宣判"}, {"every": 4, "to": "self", "status": {"力量": 2}, "name": "加刑"}]},
	"神国骑士": {"name": "神国骑士", "hp": 110, "attack": 12, "pattern": [1, 1, 3], "skills": [{"every": 2, "to": "self", "status": {"力量": 2}, "name": "冲锋"}, {"every": 4, "to": "self", "heal": 15, "name": "整备"}]},
	"执灯者": {"name": "执灯者", "hp": 100, "attack": 10, "pattern": [1, 2], "skills": [{"every": 2, "to": "self", "status": {"再生": 4}, "name": "灯油"}, {"every": 3, "to": "player", "status": {"虚弱": 1}, "name": "照见"}]},
}

const POPE := {
	"教皇": {"name": "教皇", "hp": 210, "attack": 13, "pattern": [0.5, 1, 1.5, 2, 2.5, 3, 0, 0], "skills": [{"every": 2, "to": "self", "status": {"力量": 2}, "name": "神威"}, {"every": 3, "to": "player", "status": {"易伤": 3}, "name": "注视"}, {"every": 5, "to": "self", "heal": 40, "name": "圣愈"}]},
}


# ===== 第三幕：疯狂的诸神（击败后掉落器官）=====
const GODS := {
	"奥丁": {"name": "奥丁", "hp": 170, "attack": 10, "pattern": [1, 1.5], "organ": "神之眼",
		"skills": [{"every": 2, "to": "player", "status": {"虚弱": 2}, "name": "凝视"},
			{"every": 4, "to": "self", "status": {"力量": 3}, "name": "睁开"}]},
	"赫尔墨斯": {"name": "赫尔墨斯", "hp": 150, "attack": 11, "pattern": [1, 2], "organ": "神之舌",
		"skills": [{"every": 2, "to": "player", "status": {"中毒": 3}, "name": "低语"},
			{"every": 3, "to": "self", "heal": 12, "name": "吞咽"}]},
	"阿斯克勒庇俄斯": {"name": "阿斯克勒庇俄斯", "hp": 160, "attack": 8, "pattern": [1, 1, 2], "organ": "神之心",
		"skills": [{"every": 2, "to": "self", "heal": 15, "name": "愈合"},
			{"every": 3, "to": "self", "status": {"荆棘": 4}, "name": "硬化"}]},
	"赫菲斯托斯": {"name": "赫菲斯托斯", "hp": 130, "attack": 9, "pattern": [1, 1.5, 2], "organ": "神之手",
		"skills": [{"every": 2, "to": "player", "status": {"易伤": 2}, "name": "捏塑"},
			{"every": 4, "to": "self", "status": {"力量": 4}, "name": "成型"}]},
}


# ===== 第二幕终局：假的世界树 =====
const TREE := {
	"世界树": {"name": "世界树", "hp": 220, "attack": 8, "pattern": [1, 1, 2],
		"skills": [{"every": 2, "to": "player", "status": {"中毒": 3}, "name": "渗出"},
			{"every": 2, "to": "self", "heal": 12, "name": "生长"},
			{"every": 3, "to": "player", "status": {"虚弱": 2}, "name": "落叶"}]},
}


# ===== 第三幕终局：耶梦加得 =====
const SERPENT := {
	"耶梦加得": {"name": "耶梦加得", "hp": 420, "attack": 14, "pattern": [1, 1.5, 1, 2],
		"on_hit": {"中毒": 2},
		"domain": {"type": "energy_drain", "value": 1},
		"skills": [
			{"every": 2, "to": "self", "status": {"力量": 2}, "name": "缠紧"},
			{"every": 3, "to": "player", "status": {"中毒": 4}, "name": "毒牙"},
			{"every": 4, "to": "player", "status": {"易伤": 2}, "name": "吞"},
			{"every": 5, "to": "self", "heal": 30, "name": "蜕皮"},
		]},
}

func _pool_for(node_type: String) -> Dictionary:
	match node_type:
		"god":
			return GODS
		"tree":
			return TREE
		"serpent":
			return SERPENT
		"elite":
			return ELITE
		"boss":
			return BOSS
		"divine":
			return DIVINE
		"divine_elite":
			return DIVINE_ELITE
		"pope":
			return POPE
		"contestant":
			var result := {}
			for id in ContestantDB.CONTESTANTS.keys():
				var c: Dictionary = ContestantDB.scaled(id)
				result[id] = {
					"name": c["name"],
					"hp": int(c["hp"]),
					"attack": int(c["attack"]),
					"pattern": c.get("pattern", [1]),
					"on_hit": c.get("on_hit", {}),
				}
			return result
		_:
			return NORMAL

func get_enemy(id: String) -> Dictionary:
	for pool in [NORMAL, ELITE, BOSS, DIVINE, DIVINE_ELITE, POPE]:
		if pool.has(id):
			return pool[id]
	return NORMAL.values()[0]

# 按基础生命把敌人分为 3 个梯度
func _tier_of(data: Dictionary) -> int:
	var hp: int = int(data.get("hp", 0))
	if hp <= 34:
		return 1
	if hp <= 45:
		return 2
	return 3

# 该层数允许出现的最高梯度
func _max_tier(depth: int) -> int:
	if depth <= 2:
		return 1
	if depth <= 5:
		return 2
	return 3

func pick_for_node(node_type: String, depth: int = 0) -> Dictionary:
	var pool := _pool_for(node_type)
	var ids := pool.keys()
	var filtered := []
	var capped := _max_tier(depth)
	for id in ids:
		if _tier_of(pool[id]) <= capped:
			filtered.append(id)
	if filtered.is_empty():
		filtered = ids

	var chosen: String = str(filtered[randi() % filtered.size()])
	var data: Dictionary = pool[chosen].duplicate(true)

	# 深度缩放：越往下越强，上限 ×1.4；首领和教皇不缩放
	if node_type != "boss" and node_type != "pope":
		var mult: float = min(1.4, 1.0 + 0.05 * float(max(0, depth - 1)))
		data["hp"] = int(int(data["hp"]) * mult)
		data["attack"] = int(int(data["attack"]) * mult)
	return data

const SILHOUETTE := {
	"奥古斯丁": "augustine",
	"安布罗斯": "ambrose",
	"耶柔米": "jerome",
	"格里高利": "gregory",
	"金口约翰": "chrysostom",

	"史莱姆": "beast", "腐化史莱姆": "beast", "毒蜘蛛": "beast",
	"蝙蝠群": "beast", "哥布林": "beast", "荆棘兽": "beast",
	"骷髅兵": "soldier", "狂徒": "soldier", "双子刺客": "soldier",
	"亡灵骑士": "soldier", "精英守卫": "soldier", "神国骑士": "soldier",
	"逐神者": "soldier", "审判者": "soldier",
	"咒术师": "caster", "精英法师": "caster", "血祭司": "caster",
	"悔罪者": "caster", "祈祷者": "caster", "苦行僧": "caster",
	"执灯者": "caster", "盲眼先知": "caster",
	"食人魔": "giant", "熔岩巨像": "giant", "石像鬼": "giant",
	"荆棘像": "giant", "圣骸": "giant",
	"火元素": "shade", "冰霜精": "shade", "腐尸": "shade",
	"圣像": "idol", "唱诗班": "idol",
	"断头骑士": "soldier", "书记官": "soldier",
	"缢死者": "shade", "无面乐师": "shade",
	"圣骸行者": "giant", "灰烬修女": "caster",
	"奥丁": "idol", "赫尔墨斯": "shade", "阿斯克勒庇俄斯": "giant", "赫菲斯托斯": "caster",
	"耶梦加得": "beast",
	"世界树": "tree",
	"守门人": "gatekeeper",
	"教皇": "pope",
	"原罪*贪婪": "greed",
}


# 领域类型 -> 中文说明（"%d" 会被替换成数值）
const DOMAIN_TEXT := {
	"attack_recoil": "你每攻击一次，受到 %d 伤害",
	"cost_up": "你打出的牌费用 +%d",
	"damage_aura": "每回合开始失去 %d 生命",
	"weak_aura": "每回合开始获得 %d 层虚弱",
	"bleed_aura": "每回合开始获得 %d 层流血",
	"block_decay": "每回合开始失去 %d 格挡",
	"poison_aura": "每回合开始获得 %d 层中毒",
	"half_block": "你获得的格挡减半",
	"less_draw": "你每回合少抽 %d 张牌",
	"draw_penalty": "你每回合少抽 %d 张牌",
	"energy_drain": "你每回合少 %d 点能量",
	"enemy_regen": "它每回合回复 %d 生命",
	"thorns_aura": "你攻击它时受到 %d 伤害",
	"no_heal": "你无法回复生命",
}

# 把领域翻成一句话（没领域返回空字符串）
func domain_text(d: Dictionary) -> String:
	var t := str(d.get("type", ""))
	if t == "" or not DOMAIN_TEXT.has(t):
		return ""
	var v := int(d.get("value", 0))
	var s: String = str(DOMAIN_TEXT[t])
	if s.contains("%d"):
		return s % v
	return s

func silhouette_of(enemy_name: String) -> String:
	return str(SILHOUETTE.get(enemy_name, "soldier"))

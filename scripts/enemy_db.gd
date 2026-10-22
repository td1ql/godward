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
	"亡灵骑士": {"name": "亡灵骑士", "hp": 85, "attack": 6, "pattern": [1, 1, 2], "on_turn": {"再生": 2}},
	"熔岩巨像": {"name": "熔岩巨像", "hp": 95, "attack": 8, "pattern": [1, 2], "skills": [{"every": 3, "to": "self", "status": {"荆棘": 4}, "name": "荆棘"}]},
	"精英守卫": {"name": "精英守卫", "hp": 65, "attack": 8, "pattern": [1, 1, 1], "skills": [{"every": 2, "to": "self", "status": {"荆棘": 2}, "name": "荆棘"}]},
	"精英法师": {"name": "精英法师", "hp": 55, "attack": 8, "pattern": [1, 1.5], "on_hit": {"虚弱": 2}, "on_turn": {"力量": 1}},
	"血祭司": {"name": "血祭司", "hp": 60, "attack": 6, "pattern": [1, 1.5, 2], "skills": [{"every": 2, "to": "player", "status": {"流血": 3}, "name": "流血"}, {"every": 3, "to": "self", "status": {"再生": 8}, "name": "再生"}]},
}

const BOSS := {
	"守门人": {"name": "守门人", "hp": 100, "attack": 10, "pattern": [1, 1.5, 1, 2], "on_hit": {"易伤": 1}, "on_turn": {"力量": 1}, "skills":[{"every": 2, "to": "player", "status": {"流血": 2}, "name": "流血"}, {"every": 3, "to": "self", "status": {"再生": 3}, "name": "再生"}]},
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
	"教皇": {"name": "教皇", "hp": 260, "attack": 16, "pattern": [0.5, 1, 1.5, 2, 2.5, 3, 0, 0], "skills": [{"every": 2, "to": "self", "status": {"力量": 2}, "name": "神威"}, {"every": 3, "to": "player", "status": {"易伤": 3}, "name": "注视"}, {"every": 5, "to": "self", "heal": 40, "name": "圣愈"}]},
}

func _pool_for(node_type: String) -> Dictionary:
	match node_type:
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

func pick_for_node(node_type: String) -> Dictionary:
	var pool := _pool_for(node_type)
	var ids := pool.keys()
	return pool[ids[randi() % ids.size()]]

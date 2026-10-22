extends Node

const NORMAL := {
	"史莱姆": {"name": "史莱姆", "hp": 30, "attack": 5, "pattern": [1, 1]},
	"哥布林": {"name": "哥布林", "hp": 35, "attack": 6, "pattern": [1, 1, 1.5]},
	"骷髅兵": {"name": "骷髅兵", "hp": 40, "attack": 4, "pattern": [1.5, 2]},
	"毒蜘蛛": {"name": "毒蜘蛛", "hp": 28, "attack": 4, "pattern": [1, 1], "on_hit": {"中毒": 1}},
}

const ELITE := {
	"精英守卫": {"name": "精英守卫", "hp": 60, "attack": 8, "pattern": [1, 1, 1]},
	"精英法师": {"name": "精英法师", "hp": 55, "attack": 10, "pattern": [0.5, 1, 1, 1.5], "on_hit": {"虚弱": 1}},
}

const BOSS := {
	"守门人": {"name": "守门人", "hp": 10, "attack": 12, "pattern": [1, 1, 1, 1.5], "on_hit": {"易伤": 1}},
}

const POPE := {
	"教皇": {"name": "教皇", "hp": 240, "attack": 16, "pattern": [1, 1.5, 1, 2], "on_hit": {"易伤": 1}},
}

const DIVINE := {
	"祈祷者": {"name": "祈祷者", "hp": 55, "attack": 9, "pattern": [1, 1, 2]},
	"圣像": {"name": "圣像", "hp": 70, "attack": 7, "pattern": [1, 2], "on_hit": {"虚弱": 1}},
	"唱诗班": {"name": "唱诗班", "hp": 50, "attack": 11, "pattern": [2, 1]},
}

const DIVINE_ELITE := {
	"审判者": {"name": "审判者", "hp": 90, "attack": 13, "pattern": [1, 2, 2]},
	"神国骑士": {"name": "神国骑士", "hp": 100, "attack": 12, "pattern": [1, 1, 3]},
}

func _pool_for(node_type: String) -> Dictionary:
	match node_type:
		"divine":
			return DIVINE
		"divine_elite":
			return DIVINE_ELITE
		"elite":
			return ELITE
		"boss":
			return BOSS
		"pope":
			return POPE
		"contestant":
			var result := {}
			for id in ContestantDB.CONTESTANTS.keys():
				var c: Dictionary = ContestantDB.CONTESTANTS[id]
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
	for pool in [NORMAL, ELITE, BOSS]:
		if pool.has(id):
			return pool[id]
	return NORMAL.values()[0]

func pick_for_node(node_type: String) -> Dictionary:
	var pool := _pool_for(node_type)
	var ids := pool.keys()
	return pool[ids[randi() % ids.size()]]

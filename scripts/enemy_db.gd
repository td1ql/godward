extends Node

const NORMAL := {
	"史莱姆": {"name": "史莱姆", "hp": 30, "attack": 5, "pattern": [1, 1]},
	"哥布林": {"name": "哥布林", "hp": 35, "attack": 6, "pattern": [1, 1, 2]},
	"骷髅兵": {"name": "骷髅兵", "hp": 40, "attack": 7, "pattern": [1, 2]},
	"毒蜘蛛": {"name": "毒蜘蛛", "hp": 28, "attack": 4, "pattern": [1, 1], "on_hit": {"中毒": 1}},
}

const ELITE := {
	"精英守卫": {"name": "精英守卫", "hp": 60, "attack": 8, "pattern": [1, 1, 1]},
	"精英法师": {"name": "精英法师", "hp": 55, "attack": 10, "pattern": [1, 2], "on_hit": {"虚弱": 1}},
}

const BOSS := {
	"塔主": {"name": "塔主", "hp": 100, "attack": 12, "pattern": [1, 1, 1, 2], "on_hit": {"易伤": 1}},
}

func _pool_for(node_type: String) -> Dictionary:
	match node_type:
		"elite":
			return ELITE
		"boss":
			return BOSS
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

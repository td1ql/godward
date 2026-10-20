extends Node

# ===== 普通敌人：加普通怪只需在这里加一行 =====
const NORMAL := {
	"史莱姆": {"name": "史莱姆", "hp": 30, "attack": 5},
	"哥布林": {"name": "哥布林", "hp": 35, "attack": 6},
	"骷髅兵": {"name": "骷髅兵", "hp": 40, "attack": 7},
}

# ===== 精英敌人 =====
const ELITE := {
	"精英守卫": {"name": "精英守卫", "hp": 60, "attack": 8},
	"精英法师": {"name": "精英法师", "hp": 55, "attack": 10},
}

# ===== 首领 =====
const BOSS := {
	"塔主": {"name": "塔主", "hp": 100, "attack": 12},
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

# 按节点类型返回一个敌人字典（直接给战斗用）
func pick_for_node(node_type: String) -> Dictionary:
	var pool := _pool_for(node_type)
	var ids := pool.keys()
	return pool[ids[randi() % ids.size()]]

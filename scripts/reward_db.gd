extends Node

# 不出现在奖励里的牌（基础牌）
const EXCLUDE := ["打击", "防御"]

# 普通战斗只给行动牌；精英/首领才给效果牌
func pool_for(node_type: String) -> Array:
	var include_effect: bool = (node_type == "elite" or node_type == "boss")
	var result := []
	for id in CardDB.CARDS.keys():
		if EXCLUDE.has(id):
			continue
		var kind: String = CardDB.kind_of(id)
		if kind == "encounter":
			continue
		if kind == "effect" and not include_effect:
			continue
		result.append(id)
	return result

func pick_cards(node_type: String, count: int) -> Array:
	var pool := pool_for(node_type)
	pool.shuffle()
	var result := []
	var n: int = min(count, pool.size())
	for i in range(n):
		result.append(pool[i])
	return result

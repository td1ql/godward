extends Node

const EXCLUDE := ["打击", "防御"]

func pool_for(node_type: String, act: int = 1) -> Array:
	var include_effect: bool = node_type == "elite" or node_type == "boss" or node_type == "divine_elite" or node_type == "pope"
	var result := []
	for id in CardDB.CARDS.keys():
		if EXCLUDE.has(id):
			continue
		var kind: String = CardDB.kind_of(id)
		if kind == "encounter":
			continue
		var divine: bool = bool(CardDB.CARDS[id].get("divine", false))
		if bool(CardDB.CARDS[id].get("remnant", false)):
			continue
		if bool(CardDB.CARDS[id].get("event", false)):
			continue
		if bool(CardDB.CARDS[id].get("tutorial", false)):
			continue
		if bool(CardDB.CARDS[id].get("exclusive", false)):
			continue
		if not GameState.streams.is_empty():
			var hit: bool = bool(CardDB.CARDS[id].get("common", false))
			for st in CardDB.streams_of(id):
				if GameState.streams.has(st):
					hit = true
					break
			if not hit:
				continue
		if act == 2 and not divine:
			continue
		if act != 2 and divine:
			continue
		if kind == "effect" and not include_effect:
			continue
		result.append(id)
	return result

func pick_cards(node_type: String, count: int, act: int = 1) -> Array:
	var pool := pool_for(node_type, act)
	pool.shuffle()
	var result := []
	var n: int = min(count, pool.size())
	for i in range(n):
		result.append(pool[i])
	return result

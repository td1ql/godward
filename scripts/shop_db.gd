extends Node

const CARD_COUNT := 3

func pick_cards() -> Array:
	var pool := CardDB.all_ids()
	pool.shuffle()
	var count: int = min(CARD_COUNT, pool.size())
	var result := []
	for i in range(count):
		result.append(pool[i])
	return result

extends Node

const CARD_COUNT := 3

func pick_cards(act: int = 1) -> Array:
	var pool := RewardDB.pool_for("shop", act)
	if randi() % 3 == 0:
		pool = RewardDB.pool_for("elite", act)
	pool.shuffle()
	var count: int = min(CARD_COUNT, pool.size())
	var result := []
	for i in range(count):
		result.append(pool[i])
	return result

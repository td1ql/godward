extends Node

const CARD_COUNT := 3

func pick_cards() -> Array:
	# 复用 RewardDB 的精英池：包含行动牌 + 效果牌，排除遭遇牌和基础牌
	var pool := RewardDB.pool_for("elite")
	pool.shuffle()
	var count: int = min(CARD_COUNT, pool.size())
	var result := []
	for i in range(count):
		result.append(pool[i])
	return result

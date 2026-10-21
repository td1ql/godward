class_name Deck
extends RefCounted

var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

func setup(cards: Array[String]) -> void:
	draw_pile = cards.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()

# 只负责抽牌 + 空牌堆洗回，返回抽到的牌；遭遇牌由调用方处理
func draw_raw(n: int) -> Array[String]:
	var result: Array[String] = []
	for i in range(n):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		result.append(draw_pile.pop_back())
	return result

func total() -> int:
	return draw_pile.size() + hand.size() + discard_pile.size()

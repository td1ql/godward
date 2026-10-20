extends Node2D

var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

const HAND_SIZE := 5
const TOTAL_CARDS := 20

# 卡牌数据库：每张牌的 费用 / 伤害 / 格挡
const CARD_DB := {
	"打击": {"cost": 1, "damage": 6, "block": 0},
	"防御": {"cost": 1, "damage": 0, "block": 5},
	"重击": {"cost": 2, "damage": 10, "block": 0},
	"铁壁": {"cost": 2, "damage": 0, "block": 10},
	"疾风斩": {"cost": 1, "damage": 8, "block": 0},
}

@onready var info_label: Label = $InfoLabel
@onready var draw_button: Button = $DrawButton
@onready var end_turn_button: Button = $EndTurnButton

func _ready() -> void:
	var card_ids := ["打击", "防御", "重击", "铁壁", "疾风斩"]
	for i in range(TOTAL_CARDS):
		draw_pile.append(card_ids[i % card_ids.size()])
	draw_button.pressed.connect(_on_draw_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	_draw_cards(HAND_SIZE)
	_update_ui()

func _on_draw_pressed() -> void:
	_draw_cards(1)
	_update_ui()

func _on_end_turn_pressed() -> void:
	discard_pile.append_array(hand)
	hand.clear()
	_draw_cards(HAND_SIZE)
	_update_ui()

func _draw_cards(n: int) -> void:
	for i in range(n):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		hand.append(draw_pile.pop_back())

func _update_ui() -> void:
	var hand_text := ""
	for c in hand:
		var d: Dictionary = CARD_DB[c]
		if d["damage"] > 0:
			hand_text += "%s(%d伤) " % [c, d["damage"]]
		else:
			hand_text += "%s(%d挡) " % [c, d["block"]]
	if hand_text == "":
		hand_text = "（空）"
	var total := draw_pile.size() + hand.size() + discard_pile.size()
	info_label.text = "抽牌堆: %d  手牌: %d  弃牌堆: %d  总计: %d/%d\n手牌: %s" % [
		draw_pile.size(), hand.size(), discard_pile.size(),
		total, TOTAL_CARDS, hand_text
	]

extends Node2D

var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

var player_hp := 50
var enemy_hp := 30

const HAND_SIZE := 5
const TOTAL_CARDS := 20

const CARD_DB := {
	"打击": {"cost": 1, "damage": 6, "block": 0},
	"防御": {"cost": 1, "damage": 0, "block": 5},
	"重击": {"cost": 2, "damage": 10, "block": 0},
	"铁壁": {"cost": 2, "damage": 0, "block": 10},
	"疾风斩": {"cost": 1, "damage": 8, "block": 0},
}

@onready var info_label: Label = $InfoLabel
@onready var combat_label: Label = $CombatLabel
@onready var draw_button: Button = $DrawButton
@onready var end_turn_button: Button = $EndTurnButton
@onready var attack_button: Button = $AttackButton

func _ready() -> void:
	var card_ids := ["打击", "防御", "重击", "铁壁", "疾风斩"]
	for i in range(TOTAL_CARDS):
		draw_pile.append(card_ids[i % card_ids.size()])
	draw_button.pressed.connect(_on_draw_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
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

func _on_attack_pressed() -> void:
	if enemy_hp <= 0 or player_hp <= 0:
		return
	# 玩家攻击（先用固定 6 点伤害模拟）
	enemy_hp = max(0, enemy_hp - 6)
	# 敌人没死就反击
	if enemy_hp > 0:
		player_hp = max(0, player_hp - 5)
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
	combat_label.text = "玩家 HP: %d    敌人 HP: %d" % [player_hp, enemy_hp]
	if enemy_hp <= 0:
		combat_label.text += "\n你赢了！"
	elif player_hp <= 0:
		combat_label.text += "\n你被打败了..."

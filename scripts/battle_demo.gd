extends Node2D

var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

var player_hp := 50
var player_block := 0
var player_energy := 3
var enemy_hp := 30
var enemy_attack := 5

var game_over := false
var card_buttons: Array[Button] = []

const HAND_SIZE := 5
const TOTAL_CARDS := 20
const MAX_ENERGY := 3

const CARD_DB := {
	"打击": {"cost": 1, "damage": 6, "block": 0},
	"防御": {"cost": 1, "damage": 0, "block": 5},
	"重击": {"cost": 2, "damage": 10, "block": 0},
	"铁壁": {"cost": 2, "damage": 0, "block": 10},
	"疾风斩": {"cost": 1, "damage": 8, "block": 0},
}

@onready var info_label: Label = $InfoLabel
@onready var combat_label: Label = $CombatLabel
@onready var end_turn_button: Button = $EndTurnButton

func _ready() -> void:
	player_hp = GameState.player_hp
	var card_ids := ["打击", "防御", "重击", "铁壁", "疾风斩"]
	for i in range(TOTAL_CARDS):
		draw_pile.append(card_ids[i % card_ids.size()])
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	_draw_cards(HAND_SIZE)
	_rebuild_hand_buttons()
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

func _rebuild_hand_buttons() -> void:
	for b in card_buttons:
		b.queue_free()
	card_buttons.clear()
	for i in range(hand.size()):
		var c: String = hand[i]
		var d: Dictionary = CARD_DB[c]
		var btn := Button.new()
		btn.position = Vector2(200 + i * 130, 520)
		btn.size = Vector2(120, 110)
		btn.disabled = player_energy < d["cost"]
		if d["damage"] > 0:
			btn.text = "%s\n[%d费] %d 伤害" % [c, d["cost"], d["damage"]]
		else:
			btn.text = "%s\n[%d费] %d 格挡" % [c, d["cost"], d["block"]]
		btn.pressed.connect(_on_card_pressed.bind(i))
		add_child(btn)
		card_buttons.append(btn)

func _on_card_pressed(index: int) -> void:
	if game_over:
		return
	if index < 0 or index >= hand.size():
		return
	var c: String = hand[index]
	var d: Dictionary = CARD_DB[c]
	if player_energy < d["cost"]:
		return
	player_energy -= d["cost"]
	if d["damage"] > 0:
		enemy_hp = max(0, enemy_hp - d["damage"])
	if d["block"] > 0:
		player_block += d["block"]
	hand.remove_at(index)
	discard_pile.append(c)
	_check_game_over()
	_rebuild_hand_buttons()
	_update_ui()

func _on_end_turn_pressed() -> void:
	if game_over:
		return
	var incoming: int = max(0, enemy_attack - player_block)
	player_hp = max(0, player_hp - incoming)
	player_block = 0
	player_energy = MAX_ENERGY
	_check_game_over()
	discard_pile.append_array(hand)
	hand.clear()
	_draw_cards(HAND_SIZE)
	_rebuild_hand_buttons()
	_update_ui()

func _check_game_over() -> void:
	if enemy_hp <= 0:
		game_over = true
		GameState.player_hp = max(1, player_hp)
		await get_tree().create_timer(1.2).timeout
		get_tree().change_scene_to_file("res://scenes/map.tscn")
	elif player_hp <= 0:
		game_over = true
		await get_tree().create_timer(1.5).timeout
		GameState.player_hp = GameState.player_max_hp
		get_tree().reload_current_scene()

func _update_ui() -> void:
	var total := draw_pile.size() + hand.size() + discard_pile.size()
	info_label.text = "能量: %d/%d  抽牌堆: %d  手牌: %d  弃牌堆: %d  总计: %d/%d" % [
		player_energy, MAX_ENERGY, draw_pile.size(), hand.size(), discard_pile.size(), total, TOTAL_CARDS
	]
	combat_label.text = "玩家 HP: %d  格挡: %d\n敌人 HP: %d" % [player_hp, player_block, enemy_hp]
	if enemy_hp <= 0:
		combat_label.text += "\n你赢了！"
	elif player_hp <= 0:
		combat_label.text += "\n你被打败了..."

extends Node2D

var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

var player_hp := 50
var player_block := 0
var player_energy := 3
var enemy_hp := 30
var enemy_attack := 5
var enemy_label_name := "敌人"

var game_over := false
var card_buttons: Array[Button] = []

const HAND_SIZE := 5
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

	# 根据当前节点类型决定敌人强度
	var node_type := ""
	if GameState.map_nodes.has(GameState.current_node_id):
		node_type = GameState.map_nodes[GameState.current_node_id]["type"]
	match node_type:
		"elite":
			enemy_hp = 60
			enemy_attack = 8
			enemy_label_name = "精英敌人"
		"boss":
			enemy_hp = 100
			enemy_attack = 12
			enemy_label_name = "首领"
		_:
			enemy_hp = 30
			enemy_attack = 5
			enemy_label_name = "敌人"

	draw_pile = GameState.deck.duplicate()
	draw_pile.shuffle()
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
		_show_reward()
	elif player_hp <= 0:
		game_over = true
		await get_tree().create_timer(1.0).timeout
		_show_game_over()

func _update_ui() -> void:
	var total := draw_pile.size() + hand.size() + discard_pile.size()
	info_label.text = "能量: %d/%d  抽牌堆: %d  手牌: %d  弃牌堆: %d  总计: %d" % [
		player_energy, MAX_ENERGY, draw_pile.size(), hand.size(), discard_pile.size(), total
	]
	combat_label.text = "玩家 HP: %d  格挡: %d\n%s HP: %d" % [player_hp, player_block, enemy_label_name, enemy_hp]
	if enemy_hp <= 0:
		combat_label.text += "\n你赢了！"
	elif player_hp <= 0:
		combat_label.text += "\n你被打败了..."

# ========== 战斗胜利奖励 ==========
func _show_reward() -> void:
	var pool := ["打击", "防御", "重击", "铁壁", "疾风斩"]
	pool.shuffle()

	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var title := Label.new()
	title.text = "战斗胜利！选择一张卡加入牌组"
	title.position = Vector2(380, 150)
	title.add_theme_font_size_override("font_size", 24)
	overlay.add_child(title)

	for i in range(3):
		var card_name: String = pool[i]
		var d: Dictionary = CARD_DB[card_name]
		var btn := Button.new()
		btn.size = Vector2(220, 170)
		btn.position = Vector2(240 + i * 250, 280)
		if d["damage"] > 0:
			btn.text = "%s\n[%d费] %d 伤害\n\n点击选择" % [card_name, d["cost"], d["damage"]]
		else:
			btn.text = "%s\n[%d费] %d 格挡\n\n点击选择" % [card_name, d["cost"], d["block"]]
		btn.pressed.connect(_choose_reward.bind(card_name))
		overlay.add_child(btn)

	var skip := Button.new()
	skip.text = "跳过奖励"
	skip.size = Vector2(200, 50)
	skip.position = Vector2(540, 520)
	skip.pressed.connect(_finish_reward)
	overlay.add_child(skip)

func _choose_reward(card_name: String) -> void:
	GameState.deck.append(card_name)
	_finish_reward()

func _finish_reward() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")

# ========== 失败结算 ==========
func _show_game_over() -> void:
	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var title := Label.new()
	title.text = "你被打倒了……"
	title.position = Vector2(480, 260)
	title.add_theme_font_size_override("font_size", 34)
	overlay.add_child(title)

	var sub := Label.new()
	sub.text = "这次冒险到此为止。"
	sub.position = Vector2(510, 320)
	sub.add_theme_font_size_override("font_size", 18)
	overlay.add_child(sub)

	var btn := Button.new()
	btn.text = "重新开始一局"
	btn.size = Vector2(220, 60)
	btn.position = Vector2(530, 400)
	btn.pressed.connect(_restart_run)
	overlay.add_child(btn)

func _restart_run() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/map.tscn")

extends Node2D

var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

var player_hp := 50
var player_block := 0
var player_energy := 3
var player_status := {}

var enemy_hp := 30
var enemy_attack := 5
var enemy_status := {}
var enemy_on_hit := {}
var enemy_pattern: Array = [1]
var enemy_label_name := "敌人"
var turn_index := 0

var game_over := false
var card_buttons: Array[Button] = []

@onready var info_label: Label = $InfoLabel
@onready var combat_label: Label = $CombatLabel
@onready var end_turn_button: Button = $EndTurnButton

func _ready() -> void:
	player_hp = GameState.player_hp
	player_energy = RunConfig.MAX_ENERGY

	var node_type := "battle"
	if GameState.map_nodes.has(GameState.current_node_id):
		node_type = GameState.map_nodes[GameState.current_node_id]["type"]
	var e: Dictionary = EnemyDB.pick_for_node(node_type)
	enemy_hp = int(e["hp"])
	enemy_attack = int(e["attack"])
	enemy_label_name = str(e["name"])
	enemy_pattern = e.get("pattern", [1])
	enemy_on_hit = e.get("on_hit", {})

	draw_pile = GameState.deck.duplicate()
	draw_pile.shuffle()
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	_draw_cards(RunConfig.HAND_SIZE)
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

func _intent_damage() -> int:
	if enemy_pattern.is_empty():
		return enemy_attack
	return enemy_attack * int(enemy_pattern[turn_index % enemy_pattern.size()])

func _calc_damage(base: int, attacker: Dictionary, target: Dictionary) -> int:
	var dmg := float(base) + float(attacker.get("力量", 0))
	if attacker.get("虚弱", 0) > 0:
		dmg *= 0.75
	if target.get("易伤", 0) > 0:
		dmg *= 1.5
	return max(0, int(floor(dmg)))

func _apply_status(target: Dictionary, st: Dictionary) -> void:
	for key in st:
		target[key] = int(target.get(key, 0)) + int(st[key])

func _tick_poison(st: Dictionary) -> int:
	var p: int = int(st.get("中毒", 0))
	if p <= 0:
		return 0
	st["中毒"] = p - 1
	if st["中毒"] <= 0:
		st.erase("中毒")
	return p

func _decay_status(st: Dictionary) -> void:
	var to_erase: Array = []
	for key in st.keys():
		if key == "中毒" or key == "力量":
			continue
		st[key] = int(st[key]) - 1
		if st[key] <= 0:
			to_erase.append(key)
	for key in to_erase:
		st.erase(key)

func _status_text(st: Dictionary) -> String:
	var s := ""
	for key in st:
		if s != "":
			s += " "
		s += "%s%d" % [key, st[key]]
	return s
func _card_color(d: Dictionary) -> Color:
	if d.has("self_status"):
		return Color(0.55, 0.45, 0.2)
	if d.has("status"):
		return Color(0.45, 0.32, 0.55)
	if d["damage"] > 0:
		return Color(0.5, 0.25, 0.25)
	return Color(0.24, 0.4, 0.34)

func _card_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _make_card_button(c: String, d: Dictionary) -> Button:
	var btn := Button.new()
	btn.size = Vector2(130, 160)
	btn.text = CardDB.card_text(c)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.55))
	var bg := _card_color(d)
	btn.add_theme_stylebox_override("normal", _card_style(bg, bg.lightened(0.35)))
	btn.add_theme_stylebox_override("hover", _card_style(bg.lightened(0.12), Color.WHITE))
	btn.add_theme_stylebox_override("pressed", _card_style(bg.darkened(0.2), Color.WHITE))
	btn.add_theme_stylebox_override("disabled", _card_style(bg.darkened(0.5), bg.darkened(0.3)))
	return btn

func _rebuild_hand_buttons() -> void:
	for b in card_buttons:
		b.queue_free()
	card_buttons.clear()
	var n := hand.size()
	if n == 0:
		return
	var spacing := 150.0
	var card_w := 130.0
	var total := (n - 1) * spacing + card_w
	var start_x := (1280.0 - total) / 2.0
	for i in range(n):
		var c: String = hand[i]
		var d: Dictionary = CardDB.get_card(c)
		var btn := _make_card_button(c, d)
		btn.position = Vector2(start_x + i * spacing, 480)
		btn.disabled = player_energy < d["cost"]
		btn.pressed.connect(_on_card_pressed.bind(i))
		add_child(btn)
		card_buttons.append(btn)

func _on_card_pressed(index: int) -> void:
	if game_over:
		return
	if index < 0 or index >= hand.size():
		return
	var c: String = hand[index]
	var d: Dictionary = CardDB.get_card(c)
	if player_energy < d["cost"]:
		return
	AudioManager.play("click")
	player_energy -= d["cost"]

	var hits: int = d.get("hits", 1)
	if d["damage"] > 0:
		var per := _calc_damage(d["damage"], player_status, enemy_status)
		enemy_hp = max(0, enemy_hp - per * hits)
		AudioManager.play("hit")
	player_block += d["block"]
	if d.has("status"):
		_apply_status(enemy_status, d["status"])
	if d.has("self_status"):
		_apply_status(player_status, d["self_status"])
	if d.get("heal", 0) > 0:
		AudioManager.play("heal")
		player_hp = min(GameState.player_max_hp, player_hp + d["heal"])

	hand.remove_at(index)
	discard_pile.append(c)

	if d.get("draw", 0) > 0:
		_draw_cards(d["draw"])

	_check_game_over()
	if not game_over:
		_rebuild_hand_buttons()
	_update_ui()
	
func _on_end_turn_pressed() -> void:
	if game_over:
		return

	# 1. 玩家中毒结算（玩家回合结束）
	var pp := _tick_poison(player_status)
	if pp > 0:
		player_hp = max(0, player_hp - pp)

	# 2. 敌人攻击（受敌人虚弱 / 玩家易伤影响）
	var dmg := _calc_damage(_intent_damage(), enemy_status, player_status)
	dmg = max(0, dmg - player_block)
	player_hp = max(0, player_hp - dmg)
	player_block = 0
	turn_index += 1

	# 3. 敌人中毒结算（敌人回合结束）
	var ep := _tick_poison(enemy_status)
	if ep > 0:
		enemy_hp = max(0, enemy_hp - ep)

	# 4. 状态衰减（虚弱 / 易伤 -1）
	_decay_status(player_status)
	_decay_status(enemy_status)

	# 5. 敌人攻击附带的状态：本回合挂上，保留到下一回合再生效
	if not enemy_on_hit.is_empty():
		_apply_status(player_status, enemy_on_hit)

	_check_game_over()
	_update_ui()
	if game_over:
		return

	# 6. 新回合
	discard_pile.append_array(hand)
	hand.clear()
	_draw_cards(RunConfig.HAND_SIZE)
	player_energy = RunConfig.MAX_ENERGY
	_rebuild_hand_buttons()
	_update_ui()
func _check_game_over() -> void:
	if enemy_hp <= 0:
		game_over = true
		AudioManager.play("victory")
		GameState.player_hp = max(1, player_hp)
		_show_reward()
	elif player_hp <= 0:
		game_over = true
		AudioManager.play("defeat")
		await get_tree().create_timer(1.0).timeout
		_show_game_over()

func _update_ui() -> void:
	var total := draw_pile.size() + hand.size() + discard_pile.size()
	info_label.text = "能量: %d/%d  抽牌堆: %d  手牌: %d  弃牌堆: %d  总计: %d" % [
		player_energy, RunConfig.MAX_ENERGY, draw_pile.size(), hand.size(), discard_pile.size(), total
	]
	var combat := "玩家 HP: %d  格挡: %d" % [player_hp, player_block]
	var ps := _status_text(player_status)
	if ps != "":
		combat += "  [%s]" % ps
	combat += "\n%s HP: %d" % [enemy_label_name, enemy_hp]
	var es := _status_text(enemy_status)
	if es != "":
		combat += "  [%s]" % es
	if enemy_hp > 0 and player_hp > 0:
		var intent := "意图：攻击 %d" % _calc_damage(_intent_damage(), enemy_status, player_status)
		var hit_extra := _status_text(enemy_on_hit)
		if hit_extra != "":
			intent += " + %s" % hit_extra
		combat += "\n" + intent
	combat_label.text = combat
	if enemy_hp <= 0:
		combat_label.text += "\n你赢了！"
	elif player_hp <= 0:
		combat_label.text += "\n你被打败了..."

func _show_reward() -> void:
	for b in card_buttons:
		b.visible = false

	var pool := CardDB.all_ids()
	pool.shuffle()

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
	title.text = "战斗胜利！选择一张卡加入牌组"
	title.position = Vector2(380, 120)
	title.add_theme_font_size_override("font_size", 24)
	overlay.add_child(title)

	var n: int = RunConfig.REWARD_COUNT
	var spacing := 250.0
	var card_w := 200.0
	var total := (n - 1) * spacing + card_w
	var start_x := (1280.0 - total) / 2.0
	for i in range(n):
		var card_name: String = pool[i]
		var btn := _make_card_button(card_name, CardDB.get_card(card_name))
		btn.size = Vector2(card_w, 240)
		btn.position = Vector2(start_x + i * spacing, 200)
		btn.text = CardDB.card_text(card_name) + "\n\n点击选择"
		btn.pressed.connect(_choose_reward.bind(card_name))
		overlay.add_child(btn)

	if RunConfig.ALLOW_SKIP:
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
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/map.tscn")

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

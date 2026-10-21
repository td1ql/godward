extends Node2D

var deck := Deck.new()
var hand_view: HandView
var enemy := EnemyState.new()

var player_hp := 0
var player_block := 0
var player_energy := 0
var player_status := {}

var node_type := "battle"
var game_over := false

var pending_effect := -1
var pending_need := 0
var pending_selected: Array = []

@onready var info_label: Label = $InfoLabel
@onready var combat_label: Label = $CombatLabel
@onready var end_turn_button: Button = $EndTurnButton

func _ready() -> void:
	player_hp = GameState.player_hp
	player_energy = RunConfig.MAX_ENERGY

	node_type = "battle"
	if GameState.map_nodes.has(GameState.current_node_id):
		node_type = GameState.map_nodes[GameState.current_node_id]["type"]
	enemy.setup(EnemyDB.pick_for_node(node_type))

	deck.setup(GameState.deck)

	hand_view = HandView.new()
	add_child(hand_view)
	hand_view.card_pressed.connect(_on_card_pressed)

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	_draw_cards(RunConfig.HAND_SIZE)
	_render_hand()
	_update_ui()

func _render_hand() -> void:
	hand_view.render(deck.hand, player_energy, pending_effect, pending_selected)

func _draw_cards(n: int) -> void:
	var encounters: Array[String] = []
	for card in deck.draw_raw(n):
		if CardDB.kind_of(card) == "encounter":
			_apply_card_effects(card)
			deck.discard_pile.append(card)
			encounters.append(CardDB.card_text(card).replace("\n", " "))
			if player_hp <= 0:
				_check_game_over()
				return
		else:
			deck.hand.append(card)
	if not encounters.is_empty():
		var msg := ""
		for e in encounters:
			if msg != "":
				msg += "  |  "
			msg += e
		Toast.show_text("遭遇牌：" + msg)

func _apply_card_effects(c: String) -> void:
	var d: Dictionary = CardDB.get_card(c)
	var hits: int = d.get("hits", 1)
	if d["damage"] > 0:
		var per := DamageCalc.compute(d["damage"], player_status, enemy.status)
		enemy.hp = max(0, enemy.hp - per * hits)
		AudioManager.play("hit")
	player_block += d["block"]
	if d.has("status"):
		StatusSystem.apply(enemy.status, d["status"])
	if d.has("self_status"):
		StatusSystem.apply(player_status, d["self_status"])
	if d.get("heal", 0) > 0:
		AudioManager.play("heal")
		player_hp = min(GameState.player_max_hp, player_hp + d["heal"])
	if d.get("self_damage", 0) > 0:
		player_hp = max(0, player_hp - d["self_damage"])

func _on_card_pressed(index: int) -> void:
	if game_over:
		return
	if pending_effect >= 0:
		_on_effect_select(index)
		return
	if index < 0 or index >= deck.hand.size():
		return
	var c: String = deck.hand[index]
	var d: Dictionary = CardDB.get_card(c)
	if player_energy < d["cost"]:
		return
	if CardDB.kind_of(c) == "effect" and CardDB.consume_count(c) > 0:
		if deck.hand.size() - 1 < CardDB.consume_count(c):
			return
		pending_effect = index
		pending_need = CardDB.consume_count(c)
		pending_selected.clear()
		_render_hand()
		_update_ui()
		return
	AudioManager.play("click")
	player_energy -= d["cost"]
	_apply_card_effects(c)
	deck.hand.remove_at(index)
	deck.discard_pile.append(c)
	_check_game_over()
	_render_hand()
	_update_ui()

func _on_effect_select(index: int) -> void:
	if index == pending_effect:
		pending_effect = -1
		pending_need = 0
		pending_selected.clear()
		_render_hand()
		_update_ui()
		return
	if pending_selected.has(index):
		pending_selected.erase(index)
	else:
		if pending_selected.size() >= pending_need:
			return
		pending_selected.append(index)
	if pending_selected.size() == pending_need:
		_resolve_effect()
		return
	_render_hand()
	_update_ui()

func _resolve_effect() -> void:
	var idx := pending_effect
	var c: String = deck.hand[idx]
	AudioManager.play("click")
	player_energy -= CardDB.get_card(c)["cost"]
	_apply_card_effects(c)
	var remove_idx: Array = [idx]
	for i in pending_selected:
		remove_idx.append(i)
	remove_idx.sort()
	remove_idx.reverse()
	for i in remove_idx:
		var card: String = deck.hand[i]
		deck.discard_pile.append(card)
		deck.hand.remove_at(i)
	pending_effect = -1
	pending_need = 0
	pending_selected.clear()
	_check_game_over()
	_render_hand()
	_update_ui()

# ===== 回合流程（分阶段）=====
func _on_end_turn_pressed() -> void:
	if game_over or pending_effect >= 0:
		return
	_end_player_turn()
	_resolve_enemy_turn()
	_check_game_over()
	_update_ui()
	if game_over:
		return
	_start_new_turn()

func _end_player_turn() -> void:
	var pp := StatusSystem.tick_damage(player_status)
	if pp > 0:
		player_hp = max(0, player_hp - pp)

func _resolve_enemy_turn() -> void:
	var dmg := DamageCalc.compute(enemy.intent_damage(), enemy.status, player_status)
	dmg = max(0, dmg - player_block)
	player_hp = max(0, player_hp - dmg)
	player_block = 0
	enemy.turn_index += 1

	var ep := StatusSystem.tick_damage(enemy.status)
	if ep > 0:
		enemy.hp = max(0, enemy.hp - ep)

	StatusSystem.decay(player_status)
	StatusSystem.decay(enemy.status)

	if not enemy.on_hit.is_empty():
		StatusSystem.apply(player_status, enemy.on_hit)

func _start_new_turn() -> void:
	var draw_count: int = RunConfig.BASE_DRAW + player_energy
	if draw_count > 0:
		_draw_cards(draw_count)
	player_energy = RunConfig.MAX_ENERGY
	_render_hand()
	_update_ui()

func _check_game_over() -> void:
	if enemy.hp <= 0:
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
	var total := deck.total()
	info_label.text = "能量: %d/%d  抽牌堆: %d  手牌: %d  弃牌堆: %d  总计: %d" % [
		player_energy, RunConfig.MAX_ENERGY, deck.draw_pile.size(), deck.hand.size(), deck.discard_pile.size(), total
	]
	var combat := "玩家 HP: %d  格挡: %d" % [player_hp, player_block]
	var ps := StatusSystem.text(player_status)
	if ps != "":
		combat += "  [%s]" % ps
	combat += "\n%s HP: %d" % [enemy.label_name, enemy.hp]
	var es := StatusSystem.text(enemy.status)
	if es != "":
		combat += "  [%s]" % es
	if enemy.hp > 0 and player_hp > 0:
		var intent := "意图：攻击 %d" % DamageCalc.compute(enemy.intent_damage(), enemy.status, player_status)
		var hit_extra := StatusSystem.text(enemy.on_hit)
		if hit_extra != "":
			intent += " + %s" % hit_extra
		combat += "\n" + intent
	if pending_effect >= 0:
		combat += "\n选择 %d 张手牌消耗（已选 %d，点效果牌取消）" % [pending_need, pending_selected.size()]
	combat_label.text = combat
	if enemy.hp <= 0:
		combat_label.text += "\n你赢了！"
	elif player_hp <= 0:
		combat_label.text += "\n你被打败了..."

func _show_reward() -> void:
	hand_view.hide_cards()

	var pool: Array = RewardDB.pick_cards(node_type, RunConfig.REWARD_COUNT)

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

	var n: int = pool.size()
	var spacing := 250.0
	var card_w := 200.0
	var total := (n - 1) * spacing + card_w
	var start_x := (1280.0 - total) / 2.0
	for i in range(n):
		var card_name: String = pool[i]
		var btn := CardUI.make_button(card_name, 18)
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

extends Node2D

var deck := Deck.new()
var hand_view: HandView
var player_label: Label
var ally_label: Label
var ally_fighters: Array = []
var enemy := EnemyState.new()

var player_hp := 0
var player_block := 0
var player_energy := 0
var player_status := {}

var node_type := "battle"
var game_over := false
var last_gold_gain := 0

var pending_effect := -1
var pending_need := 0
var pending_selected: Array = []
var _draw_depth := 0

@onready var info_label: Label = $InfoLabel
@onready var combat_label: Label = $CombatLabel
@onready var end_turn_button: Button = $EndTurnButton

func _ready() -> void:
	player_hp = GameState.player_hp
	player_energy = RunConfig.MAX_ENERGY

	var kind: String = str(GameState.pending_snapshot.get("kind", ""))
	node_type = "battle"
	if GameState.map_nodes.has(GameState.current_node_id):
		node_type = GameState.map_nodes[GameState.current_node_id]["type"]
	if kind == "pope":
		node_type = "pope"
	var enemy_data: Dictionary
	if kind == "battle" or kind == "contestant_fight" or kind == "pope":
		enemy_data = GameState.pending_snapshot["enemy"]
	elif not GameState.pending_enemy.is_empty():
		enemy_data = GameState.pending_enemy
		GameState.pending_enemy = {}
	else:
		enemy_data = EnemyDB.pick_for_node(node_type)
	enemy.setup(enemy_data)

	deck.setup(GameState.deck)

	hand_view = HandView.new()
	add_child(hand_view)
	hand_view.card_pressed.connect(_on_card_pressed)

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	player_label = Label.new()
	player_label.position = Vector2(20, 150)
	player_label.add_theme_font_size_override("font_size", 20)
	add_child(player_label)
	ally_label = Label.new()
	ally_label.position = Vector2(20, 320)
	ally_label.add_theme_font_size_override("font_size", 18)
	ally_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	add_child(ally_label)
	var deck_btn := Button.new()
	deck_btn.text = "牌库"
	deck_btn.position = Vector2(20, 655)
	deck_btn.size = Vector2(110, 40)
	deck_btn.pressed.connect(DeckViewer.toggle)
	add_child(deck_btn)
	var pile_btn := Button.new()
	pile_btn.text = "牌堆"
	pile_btn.position = Vector2(140, 655)
	pile_btn.size = Vector2(110, 40)
	pile_btn.pressed.connect(_open_piles)
	add_child(pile_btn)
	var menu_btn := Button.new()
	menu_btn.text = "菜单"
	menu_btn.position = Vector2(1080, 660)
	menu_btn.size = Vector2(120, 40)
	menu_btn.pressed.connect(_back_to_menu_from_battle)
	add_child(menu_btn)
	_draw_cards(GameState.initial_hand_size())
	if node_type == "boss":
		_setup_allies()
	_render_hand()
	_update_ui()

func _back_to_menu_from_battle() -> void:
	GameState.player_hp = max(1, player_hp)
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _setup_allies() -> void:
	ally_fighters.clear()
	var lines: Array[String] = []
	for id in GameState.allies:
		var c: Dictionary = ContestantDB.get_contestant(id)
		var eff: Dictionary = c.get("ally_effect", {})
		var t: String = str(eff.get("type", ""))
		if t == "fighter":
			ally_fighters.append({"name": c["name"], "damage": int(eff.get("damage", 5))})
			lines.append("%s（每回合 %d 伤害）" % [c["name"], int(eff.get("damage", 5))])
		else:
			if eff.has("cards"):
				for card in eff["cards"]:
					deck.hand.append(str(card))
				lines.append("%s（赠「%s」）" % [c["name"], str(eff["cards"][0])])
			if eff.has("hp"):
				player_hp = min(GameState.player_max_hp, player_hp + int(eff["hp"]))
				lines.append("%s（+%d HP）" % [c["name"], int(eff["hp"])])

	var text := ""
	for line in lines:
		if text != "":
			text += "、"
		text += line
	ally_label.text = "盟友：" + text

func _open_piles() -> void:
	DeckViewer.open_piles(deck.draw_pile, deck.hand, deck.discard_pile)
func _render_hand() -> void:
	hand_view.render(deck.hand, player_energy, pending_effect, pending_selected)

func _draw_cards(n: int) -> void:
	if _draw_depth >= 3:
		return
	_draw_depth += 1

	var encounters: Array[String] = []
	var extra_draw := 0
	for card in deck.draw_raw(n):
		if CardDB.kind_of(card) == "encounter":
			_apply_card_effects(card)
			deck.discard_pile.append(card)
			encounters.append(CardDB.card_text(card).replace("\n", " "))
			extra_draw += int(CardDB.get_card(card).get("draw", 0))
			if player_hp <= 0:
				_check_game_over()
				_draw_depth -= 1
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

	if extra_draw > 0:
		_draw_cards(extra_draw)

	_draw_depth -= 1

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
	if d.get("gain_energy", 0) > 0:
		player_energy += int(d["gain_energy"])
	if d.get("retrieve_top", false):
		if not deck.discard_pile.is_empty():
			deck.hand.append(deck.discard_pile.pop_back())

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
	var draw_n: int = int(d.get("draw", 0))
	if draw_n > 0:
		_draw_cards(draw_n)
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

	var consumed: Array[String] = []
	var remove_idx: Array = [idx]
	for i in pending_selected:
		consumed.append(deck.hand[i])
		remove_idx.append(i)
	remove_idx.sort()
	remove_idx.reverse()
	for i in remove_idx:
		deck.hand.remove_at(i)

	# 效果牌先进弃牌堆，消耗的牌盖在它上面
	deck.discard_pile.append(c)
	for card in consumed:
		deck.discard_pile.append(card)

	var draw_n: int = int(CardDB.get_card(c).get("draw", 0))
	if draw_n > 0:
		_draw_cards(draw_n)

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
	for f in ally_fighters:
		enemy.hp = max(0, enemy.hp - int(f["damage"]))
	if not ally_fighters.is_empty():
		AudioManager.play("hit")
	_check_game_over()
	if game_over:
		return
	var draw_count: int = RunConfig.BASE_DRAW + player_energy
	if draw_count > 0:
		_draw_cards(draw_count)
	player_energy = RunConfig.MAX_ENERGY
	_render_hand()
	_update_ui()

func _check_game_over() -> void:
	if game_over:
		return
	if enemy.hp <= 0:
		game_over = true
		AudioManager.play("victory")
		GameState.player_hp = max(1, player_hp)
		if GameState.pending_contestant != "":
			_show_contestant_aftermath()
			return
		if node_type == "pope":
			_show_true_ending()
			return
		last_gold_gain = _gold_for_node()
		GameState.gold += last_gold_gain
		if node_type == "boss":
			_after_boss()
		else:
			_show_reward()
	elif player_hp <= 0:
		game_over = true
		AudioManager.play("defeat")
		await get_tree().create_timer(1.0).timeout
		_show_game_over()

func _gold_for_node() -> int:
	if node_type == "boss":
		return RunConfig.GOLD_BOSS
	elif node_type == "elite":
		return RunConfig.GOLD_ELITE
	return RunConfig.GOLD_BATTLE

func _surviving_contestants() -> Array[String]:
	var result: Array[String] = []
	for id in GameState.contestants:
		if GameState.eliminated.has(id):
			continue
		if GameState.allies.has(id):
			continue
		result.append(id)
	return result

func _after_boss() -> void:
	if not _surviving_contestants().is_empty():
		_show_cleanup_prompt()
		return
	GameState.pending_cleanup = false
	if GameState.transmigration >= 10:
		_show_pope_final()
	else:
		_show_pope()

func _show_cleanup_prompt() -> void:
	hand_view.hide_cards()
	var n := _surviving_contestants().size()

	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.93)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var title := Label.new()
	title.text = "神堂之门紧闭"
	title.position = Vector2(0, 180)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	overlay.add_child(title)

	var body := Label.new()
	body.text = "还有 %d 名参赛者活着。\n神堂不为活人开门——他们的血是钥匙。" % n
	body.position = Vector2(0, 290)
	body.size = Vector2(1280, 100)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	overlay.add_child(body)

	var btn := Button.new()
	btn.text = "开始清算"
	btn.size = Vector2(240, 64)
	btn.position = Vector2(520, 440)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_begin_cleanup)
	overlay.add_child(btn)

func _begin_cleanup() -> void:
	GameState.pending_cleanup = true
	GameState.save_game()
	_start_next_cleanup()

func _show_cleanup_result(text: String, summary: String) -> void:
	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.93)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var title := Label.new()
	title.text = "清 算"
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	overlay.add_child(title)

	var body := Label.new()
	body.text = text
	body.position = Vector2(0, 260)
	body.size = Vector2(1280, 60)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	overlay.add_child(body)

	var reward_label := Label.new()
	reward_label.text = summary if summary != "" else "什么也没留下。"
	reward_label.position = Vector2(0, 340)
	reward_label.size = Vector2(1280, 80)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 20)
	reward_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	overlay.add_child(reward_label)

	var left := _surviving_contestants().size()
	var btn := Button.new()
	btn.text = "继续清算（剩 %d 人）" % left if left > 0 else "前往神堂"
	btn.size = Vector2(280, 64)
	btn.position = Vector2(500, 470)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(_start_next_cleanup)
	overlay.add_child(btn)

func _start_next_cleanup() -> void:
	var targets := _surviving_contestants()
	if targets.is_empty():
		GameState.pending_cleanup = false
		GameState.save_game()
		if GameState.transmigration >= 10:
			_show_pope_final()
		else:
			_show_pope()
		return

	var id: String = targets[0]
	var c: Dictionary = ContestantDB.get_contestant(id)
	var enemy_data := {
		"name": c["name"],
		"hp": int(c["hp"]),
		"attack": int(c["attack"]),
		"pattern": c.get("pattern", [1]),
		"on_hit": c.get("on_hit", {}),
	}
	GameState.pending_enemy = enemy_data
	GameState.pending_contestant = id
	GameState.pending_snapshot = {"kind": "contestant_fight", "id": id, "enemy": enemy_data}
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _update_ui() -> void:
	info_label.text = "能量: %d/%d    抽牌堆: %d    手牌: %d    弃牌堆: %d    金币: %d" % [
		player_energy, RunConfig.MAX_ENERGY,
		deck.draw_pile.size(), deck.hand.size(), deck.discard_pile.size(),
		GameState.gold
	]

	var ptext := "【玩家】\nHP: %d\n格挡: %d" % [player_hp, player_block]
	var ps := StatusSystem.text(player_status)
	if ps != "":
		ptext += "\n状态: %s" % ps
	if pending_effect >= 0:
		ptext += "\n选择 %d 张手牌消耗（已选 %d）" % [pending_need, pending_selected.size()]
	player_label.text = ptext

	var etext := "【%s】\nHP: %d" % [enemy.label_name, enemy.hp]
	var es := StatusSystem.text(enemy.status)
	if es != "":
		etext += "\n状态: %s" % es
	if enemy.hp > 0 and player_hp > 0:
		var intent := "意图：攻击 %d" % DamageCalc.compute(enemy.intent_damage(), enemy.status, player_status)
		var hit_extra := StatusSystem.text(enemy.on_hit)
		if hit_extra != "":
			intent += " + %s" % hit_extra
		etext += "\n" + intent
	if enemy.hp <= 0:
		etext += "\n你赢了！"
	elif player_hp <= 0:
		etext += "\n你被打败了..."
	combat_label.text = etext
	
func _show_reward() -> void:
	hand_view.hide_cards()

	var pool: Array = RewardDB.pick_cards(node_type, RunConfig.REWARD_COUNT, GameState.act)

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
	title.text = "战斗胜利！金币 +%d　选择一张卡" % last_gold_gain
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
	GameState.pending_node = -1
	GameState.pending_snapshot = {}
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
	GameState.restart_run()
	get_tree().change_scene_to_file("res://scenes/run_intro.tscn")

func _show_victory() -> void:
	hand_view.hide_cards()

	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.9)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var title := Label.new()
	title.text = "你击败了守门人"
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	overlay.add_child(title)

	var stats := Label.new()
	stats.text = "剩余生命: %d / %d\n金币: %d\n牌组张数: %d" % [
		player_hp, GameState.player_max_hp, GameState.gold, GameState.deck.size()
	]
	stats.position = Vector2(0, 260)
	stats.size = Vector2(1280, 160)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 26)
	overlay.add_child(stats)

	var again := Button.new()
	again.text = "再来一局"
	again.size = Vector2(240, 60)
	again.position = Vector2(390, 470)
	again.pressed.connect(_restart_run)
	overlay.add_child(again)

	var menu := Button.new()
	menu.text = "返回主菜单"
	menu.size = Vector2(240, 60)
	menu.position = Vector2(650, 470)
	menu.pressed.connect(_back_to_menu)
	overlay.add_child(menu)

func _back_to_menu() -> void:
	GameState.delete_save()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
func _show_pope() -> void:
	hand_view.hide_cards()
	var old_trans: int = GameState.transmigration
	GameState.advance_transmigration()

	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.93)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var title := Label.new()
	title.text = "你见到了教皇"
	title.position = Vector2(0, 140)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	overlay.add_child(title)

	var body := Label.new()
	if old_trans >= 10:
		body.text = "你的意志已足够强大。\n教皇第一次正视了你。"
	else:
		body.text = "他看你的眼神，像在看一件工具。\n你被留下了——但你的思绪，会在下一具身体里醒来。"
	body.position = Vector2(0, 240)
	body.size = Vector2(1280, 100)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	overlay.add_child(body)

	var trans := Label.new()
	trans.text = "第 %d 次转生结束 → 第 %d 次转生开始\n职业：%s\n词条：%s" % [old_trans, GameState.transmigration, GameState.vocation, TraitDB.text_of(GameState.traits)]
	trans.position = Vector2(0, 360)
	trans.size = Vector2(1280, 100)
	trans.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trans.add_theme_font_size_override("font_size", 20)
	trans.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	overlay.add_child(trans)

	var btn := Button.new()
	btn.text = "转生"
	btn.size = Vector2(220, 60)
	btn.position = Vector2(530, 500)
	btn.pressed.connect(_transmigrate)
	overlay.add_child(btn)

func _transmigrate() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
func _show_contestant_aftermath() -> void:
	var id: String = GameState.pending_contestant
	var c: Dictionary = ContestantDB.get_contestant(id)
	hand_view.hide_cards()

	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.92)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var title := Label.new()
	title.text = "%s 倒下了" % c["name"]
	title.position = Vector2(0, 220)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	overlay.add_child(title)

	var body := Label.new()
	if GameState.pending_cleanup:
		body.text = "神堂的门只为死人打开。\n他必须留在这里。"
	else:
		body.text = "他还有呼吸。神域的风从你们之间穿过。"
	body.position = Vector2(0, 320)
	body.size = Vector2(1280, 60)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	overlay.add_child(body)

	if GameState.pending_cleanup:
		var kill_only := Button.new()
		kill_only.text = "杀死他"
		kill_only.size = Vector2(240, 60)
		kill_only.position = Vector2(520, 430)
		kill_only.pressed.connect(_choose_aftermath.bind(id, true))
		overlay.add_child(kill_only)
	else:
		var kill_btn := Button.new()
		kill_btn.text = "杀死他"
		kill_btn.size = Vector2(200, 60)
		kill_btn.position = Vector2(390, 430)
		kill_btn.pressed.connect(_choose_aftermath.bind(id, true))
		overlay.add_child(kill_btn)

		var spare_btn := Button.new()
		spare_btn.text = "饶恕他"
		spare_btn.size = Vector2(200, 60)
		spare_btn.position = Vector2(690, 430)
		spare_btn.pressed.connect(_choose_aftermath.bind(id, false))
		overlay.add_child(spare_btn)

func _choose_aftermath(id: String, kill: bool) -> void:
	var c: Dictionary = ContestantDB.get_contestant(id)
	var reward: Dictionary = c["kill"] if kill else c["spare"]

	if kill:
		GameState.eliminated.append(id)
	else:
		GameState.met_contestants.append(id)
		if reward.get("ally", false) and not GameState.allies.has(id):
			GameState.allies.append(id)

	var gains: Array[String] = []
	if reward.has("gold"):
		var g: int = int(reward["gold"])
		GameState.gold = max(0, GameState.gold + g)
		gains.append("金币 %s%d" % ["+" if g >= 0 else "", g])
	if reward.has("hp"):
		var h: int = int(reward["hp"])
		GameState.player_hp = clamp(GameState.player_hp + h, 1, GameState.player_max_hp)
		gains.append("生命 %s%d" % ["+" if h >= 0 else "", h])

	var cards: Array[String] = ContestantDB.resolve_cards(reward)
	for card in cards:
		GameState.deck.append(card)
		gains.append("获得「%s」" % card)

	if reward.get("ally", false):
		gains.append("「%s」成为盟友" % c["name"])

	var summary := ""
	for g in gains:
		if summary != "":
			summary += "　"
		summary += g

	GameState.pending_contestant = ""
	GameState.pending_snapshot = {}
	Toast.show_text("%s\n%s" % [str(reward.get("text", "")), summary], 3.5)

	if GameState.pending_cleanup:
		GameState.save_game()
		_show_cleanup_result(str(reward.get("text", "")), summary)
		return

	GameState.pending_node = -1
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _show_pope_final() -> void:
	hand_view.hide_cards()
	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.95)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var title := Label.new()
	title.text = "教 堂"
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	overlay.add_child(title)

	var body := Label.new()
	body.text = "守门人倒下后，门后的那个人站了起来。\n「你走到了这里。」教皇说，\n「那就让我看看，神的碎片能烧到什么程度。」"
	body.position = Vector2(0, 270)
	body.size = Vector2(1280, 160)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 24)
	overlay.add_child(body)

	var btn := Button.new()
	btn.text = "与教皇决战"
	btn.size = Vector2(260, 64)
	btn.position = Vector2(510, 480)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_enter_divine_realm)
	overlay.add_child(btn)

func _start_pope_fight() -> void:
	GameState.pending_snapshot = {"kind": "pope", "enemy": EnemyDB.POPE["教皇"]}
	GameState.pending_node = -1
	GameState.pending_contestant = ""
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _show_true_ending() -> void:
	hand_view.hide_cards()
	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.97)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var title := Label.new()
	title.text = "神 堂"
	title.position = Vector2(0, 130)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	overlay.add_child(title)

	var body := Label.new()
	body.text = "教皇倒下时，穹顶裂开了。\n里面没有神，只有一片安静的白。\n\n你终于想起自己是谁。"
	body.position = Vector2(0, 260)
	body.size = Vector2(1280, 200)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 24)
	overlay.add_child(body)

	var stats := Label.new()
	stats.text = "第 %d 次转生\n剩余生命: %d / %d" % [GameState.transmigration, player_hp, GameState.player_max_hp]
	stats.position = Vector2(0, 470)
	stats.size = Vector2(1280, 80)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 20)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	overlay.add_child(stats)

	var btn := Button.new()
	btn.text = "回到主菜单"
	btn.size = Vector2(240, 60)
	btn.position = Vector2(520, 580)
	btn.pressed.connect(_end_true_run)
	overlay.add_child(btn)

func _end_true_run() -> void:
	GameState.delete_save()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _enter_divine_realm() -> void:
	GameState.act = 2
	GameState.map_generated = false
	GameState.map_nodes = {}
	GameState.current_node_id = 0
	GameState.pending_snapshot = {}
	GameState.pending_node = -1
	GameState.pending_cleanup = false
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/map.tscn")

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
var max_energy: int = RunConfig.MAX_ENERGY

@onready var info_label: Label = $InfoLabel
@onready var combat_label: Label = $CombatLabel
@onready var end_turn_button: Button = $EndTurnButton

func _ready() -> void:
	player_hp = GameState.player_hp
	max_energy = GameState.initial_energy()
	player_energy = max_energy
	var bonus_strength: int = TraitDB.total_strength(GameState.traits)
	if bonus_strength != 0:
		player_status["力量"] = bonus_strength

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
	deck_btn.text = StoryDB.t("battle_deck")
	deck_btn.position = Vector2(20, 655)
	deck_btn.size = Vector2(110, 40)
	deck_btn.pressed.connect(DeckViewer.toggle)
	add_child(deck_btn)
	var pile_btn := Button.new()
	pile_btn.text = StoryDB.t("battle_piles")
	pile_btn.position = Vector2(140, 655)
	pile_btn.size = Vector2(110, 40)
	pile_btn.pressed.connect(_open_piles)
	add_child(pile_btn)
	var menu_btn := Button.new()
	menu_btn.text = StoryDB.t("battle_menu")
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
		var thorns: int = int(enemy.status.get("荆棘", 0))
		if thorns > 0:
			player_hp = max(0, player_hp - thorns)
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

	var eh := StatusSystem.tick_heal(enemy.status)
	if eh > 0:
		enemy.hp = min(enemy.max_hp, enemy.hp + eh)

	StatusSystem.decay(player_status)
	StatusSystem.decay(enemy.status)

	if not enemy.on_turn.is_empty():
		StatusSystem.apply(enemy.status, enemy.on_turn)
	if not enemy.on_hit.is_empty():
		StatusSystem.apply(player_status, enemy.on_hit)

	for s in enemy.due_skills():
		if s.has("heal"):
			enemy.hp = min(enemy.max_hp, enemy.hp + int(s["heal"]))
		if s.has("status"):
			var st: Dictionary = s["status"]
			if str(s.get("to", "player")) == "self":
				StatusSystem.apply(enemy.status, st)
			else:
				StatusSystem.apply(player_status, st)

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
	player_energy = max_energy
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
		last_gold_gain = NodeRuleDB.gold_of(node_type)
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
	_show_church()

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
	title.text = StoryDB.t("cleanup_title")
	title.position = Vector2(0, 180)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	overlay.add_child(title)

	var body := Label.new()
	body.text = StoryDB.f("cleanup_body", [n])
	body.position = Vector2(0, 290)
	body.size = Vector2(1280, 100)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	overlay.add_child(body)

	var btn := Button.new()
	btn.text = StoryDB.t("cleanup_button")
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
	var overlay := Modal.open(self, 0.93)
	Modal.title(overlay, StoryDB.t("cleanup_result_title"), 150, 44)
	Modal.text(overlay, text, 260, 22, 60)
	var gain := Modal.text(overlay, summary if summary != "" else StoryDB.t("cleanup_result_empty"), 340, 20, 80)
	gain.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	var left := _surviving_contestants().size()
	var label := StoryDB.f("cleanup_continue", [left]) if left > 0 else StoryDB.t("cleanup_go")
	Modal.button(overlay, label, 500, 470, 280, 64, _start_next_cleanup)

func _start_next_cleanup() -> void:
	var targets := _surviving_contestants()
	if targets.is_empty():
		GameState.pending_cleanup = false
		GameState.save_game()
		_show_church()
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
		player_energy, max_energy,
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

	var pool: Array = RewardDB.pick_cards(node_type, NodeRuleDB.cards_of(node_type), GameState.act)
	var overlay := Modal.open(self, 0.85)
	Modal.title(overlay, StoryDB.f("reward_title", [last_gold_gain]), 110, 24)

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
		btn.text = CardDB.card_text(card_name) + "\n\n" + StoryDB.t("reward_pick")
		btn.pressed.connect(_choose_reward.bind(card_name))
		overlay.add_child(btn)

	if RunConfig.ALLOW_SKIP:
		Modal.button(overlay, StoryDB.t("reward_skip"), 540, 520, 200, 50, _finish_reward)

func _choose_reward(card_name: String) -> void:
	GameState.deck.append(card_name)
	_finish_reward()

func _finish_reward() -> void:
	GameState.pending_node = -1
	GameState.pending_snapshot = {}
	GameState.save_game()
	if NodeRuleDB.discard_of(node_type):
		_offer_discard()
		return
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _offer_discard() -> void:
	DeckViewer.open_choose("精英战利品：弃掉一张牌", GameState.deck, _discard_card)

func _discard_card(index: int) -> void:
	if index >= 0 and index < GameState.deck.size():
		var removed: String = GameState.deck[index]
		GameState.deck.remove_at(index)
		Toast.show_text("弃掉了「%s」" % removed, 2.5)
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _show_game_over() -> void:
	var overlay := Modal.open(self, 0.85)
	var title_key := "gameover_title"
	var body_key := "gameover_body"
	if GameState.transmigration >= 10:
		title_key = "gameover_loop_title"
		body_key = "gameover_loop_body"
	Modal.title(overlay, StoryDB.t(title_key), 240, 34)
	Modal.text(overlay, StoryDB.t(body_key), 310, 18, 50)
	Modal.button(overlay, StoryDB.t("gameover_restart"), 530, 400, 220, 60, _restart_run)

func _restart_run() -> void:
	GameState.restart_run()
	get_tree().change_scene_to_file("res://scenes/run_intro.tscn")

func _back_to_menu() -> void:
	GameState.delete_save()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _show_pope() -> void:
	hand_view.hide_cards()
	var old_trans: int = GameState.transmigration
	GameState.advance_transmigration()

	var overlay := Modal.open(self, 0.93)
	Modal.title(overlay, StoryDB.t("pope_title"), 140, 44)
	Modal.text(overlay, StoryDB.t("pope_body"), 240, 22, 100)
	var trans := Modal.text(overlay, "第 %d 次转生结束 → 第 %d 次转生开始\n职业：%s\n词条：%s" % [old_trans, GameState.transmigration, GameState.vocation, TraitDB.text_of(GameState.traits)], 360, 20, 100)
	trans.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	Modal.button(overlay, StoryDB.t("pope_button"), 530, 500, 220, 60, _transmigrate)

func _transmigrate() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _show_contestant_aftermath() -> void:
	var id: String = GameState.pending_contestant
	var c: Dictionary = ContestantDB.scaled(id)
	hand_view.hide_cards()

	var overlay := Modal.open(self, 0.92)
	Modal.title(overlay, StoryDB.f("aftermath_title", [c["name"]]), 220, 42)
	var body_text := StoryDB.t("aftermath_cleanup") if GameState.pending_cleanup else StoryDB.t("aftermath_normal")
	Modal.text(overlay, body_text, 320, 22, 60)

	if GameState.pending_cleanup:
		Modal.button(overlay, StoryDB.t("aftermath_kill"), 520, 430, 240, 60, _choose_aftermath.bind(id, true))
	else:
		Modal.button(overlay, StoryDB.t("aftermath_kill"), 390, 430, 200, 60, _choose_aftermath.bind(id, true))
		Modal.button(overlay, StoryDB.t("aftermath_spare"), 690, 430, 200, 60, _choose_aftermath.bind(id, false))

func _choose_aftermath(id: String, kill: bool) -> void:
	var c: Dictionary = ContestantDB.get_contestant(id)
	var reward: Dictionary = c["kill"] if kill else c["spare"]

	if kill:
		GameState.eliminated.append(id)
	else:
		GameState.met_contestants.append(id)

	var summary := Reward.apply(reward, id)

	GameState.pending_contestant = ""
	GameState.pending_snapshot = {}

	if GameState.pending_cleanup:
		GameState.save_game()
		_show_cleanup_result(str(reward.get("text", "")), summary)
		return

	GameState.pending_node = -1
	GameState.save_game()
	Toast.show_text("%s\n%s" % [str(reward.get("text", "")), summary], 3.5)
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _show_church() -> void:
	hand_view.hide_cards()
	var overlay := Modal.open(self, 0.95)
	Modal.title(overlay, StoryDB.t("church_title"), 150, 52)
	Modal.text(overlay, StoryDB.t("church_body"), 270, 24, 100)
	Modal.button(overlay, StoryDB.t("church_button"), 510, 480, 260, 64, _enter_church)

func _enter_church() -> void:
	GameState.player_hp = GameState.player_max_hp
	GameState.save_game()
	if GameState.transmigration >= 10:
		_enter_divine_realm()
		return
	_show_pope()

func _show_true_ending() -> void:
	hand_view.hide_cards()
	var overlay := Modal.open(self, 0.97)
	var title := Modal.title(overlay, StoryDB.t("ending_title"), 130, 52)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	Modal.text(overlay, StoryDB.t("ending_body"), 260, 24, 200)
	var stats := Modal.text(overlay, "第 %d 次转生\n剩余生命: %d / %d" % [GameState.transmigration, player_hp, GameState.player_max_hp], 470, 20, 80)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	Modal.button(overlay, StoryDB.t("ending_button"), 520, 580, 240, 60, _end_true_run)

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

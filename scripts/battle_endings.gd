extends Node
# 战斗的结局与转生（阶段 D）：教皇 / 假结局 / 世界树 / 蛇 / 真结局 / 转生 / 教堂。
# 与 battle_hud.gd、battle_flow.gd、battle_victory.gd 同一套路：静态函数，第一个参数 b 是 battle_demo 的实例。

static func _show_pope(b) -> void:
	b.hand_view.hide_cards()
	var old_trans: int = GameState.transmigration
	GameState.advance_transmigration()

	var overlay := Modal.open(b, 0.93)
	Modal.title(overlay, StoryDB.t("pope_title"), 140, 44)
	Modal.text(overlay, StoryDB.t("pope_body"), 240, 22, 100)
	var trans := Modal.text(overlay, "第 %d 次转生结束 → 第 %d 次转生开始\n职业：%s\n词条：%s" % [old_trans, GameState.transmigration, GameState.vocation, TraitDB.text_of(GameState.traits)], 360, 20, 100)
	trans.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	Modal.button(overlay, StoryDB.t("pope_button"), 530, 500, 220, 60, b._transmigrate)

static func _transmigrate(b) -> void:
	GameState.save_game()
	b.get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

static func _show_contestant_aftermath(b) -> void:
	var id: String = GameState.pending_contestant
	var c: Dictionary = ContestantDB.scaled(id)
	b.hand_view.hide_cards()

	var overlay := Modal.open(b, 0.92)
	Modal.title(overlay, StoryDB.f("aftermath_title", [c["name"]]), 220, 42)
	var body_text := StoryDB.t("aftermath_cleanup") if GameState.pending_cleanup else StoryDB.t("aftermath_normal")
	Modal.text(overlay, body_text, 320, 22, 60)

	if GameState.pending_cleanup:
		Modal.button(overlay, StoryDB.t("aftermath_kill"), 520, 430, 240, 60, b._choose_aftermath.bind(id, true))
	else:
		Modal.button(overlay, StoryDB.t("aftermath_kill"), 390, 430, 200, 60, b._choose_aftermath.bind(id, true))
		Modal.button(overlay, StoryDB.t("aftermath_spare"), 690, 430, 200, 60, b._choose_aftermath.bind(id, false))

static func _choose_aftermath(b, id: String, kill: bool) -> void:
	var c: Dictionary = ContestantDB.get_contestant(id)
	var reward: Dictionary = c["kill"] if kill else c["spare"]

	if kill:
		GameState.eliminated.append(id)
		Morality.add(-5, 10)
		if GameState.act == 3:
			GameState.divinity = clampi(GameState.divinity + 10, 0, 100)  # 第三幕杀英雄
	else:
		GameState.met_contestants.append(id)
		Morality.add(8, 0)

	var summary := Reward.apply(reward, id)

	GameState.pending_contestant = ""
	GameState.pending_snapshot = {}

	if GameState.pending_cleanup:
		GameState.save_game()
		b._show_cleanup_result(str(reward.get("text", "")), summary)
		return

	GameState.pending_node = -1
	GameState.save_game()
	Toast.show_text("%s\n%s" % [str(reward.get("text", "")), summary], 3.5)
	b.get_tree().change_scene_to_file("res://scenes/map.tscn")

static func _show_church(b) -> void:
	b.hand_view.hide_cards()
	var overlay := Modal.open(b, 0.95)
	Modal.title(overlay, StoryDB.t("church_title"), 150, 52)
	Modal.text(overlay, StoryDB.t("church_body"), 270, 24, 100)
	Modal.button(overlay, StoryDB.t("church_button"), 510, 480, 260, 64, b._enter_church)

static func _enter_church(b) -> void:
	GameState.player_hp = GameState.player_max_hp
	GameState.save_game()
	if GameState.transmigration >= 10:
		b._enter_divine_realm()
		return
	b._show_pope()

# 教皇死亡假结局：善恶值不够的玩家停在这里，永远见不到第三幕
# 善恶达标：教皇死后先看见那棵假树，才打它
static func _show_tree_reveal(b) -> void:
	b.hand_view.hide_cards()
	var overlay := Modal.open(b, 0.97)
	var title := Modal.title(overlay, "伪·世界树", 120, 48)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	var key := "ending_body_good" if Morality.is_saint() else "ending_body_dark"
	Modal.text(overlay, StoryDB.t(key), 240, 22, 260)
	Modal.button(overlay, "抬头", 520, 560, 240, 60, func() -> void:
		overlay.queue_free()
		b._start_tree_fight()
	)

static func _show_fake_ending(b) -> void:
	b.hand_view.hide_cards()
	var overlay := Modal.open(b, 0.97)
	var title := Modal.title(overlay, StoryDB.t("ending_title"), 130, 52)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	Modal.text(overlay, StoryDB.t("ending_body"), 260, 24, 200)
	var stats := Modal.text(overlay, "第 %d 次转生\n剩余生命: %d / %d\n%s" % [GameState.transmigration, b.player_hp, GameState.player_max_hp, Morality.summary()], 460, 20, 100)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	var hint := Modal.text(overlay, "（一切似乎都结束了）", 545, 17, 30)
	hint.add_theme_color_override("font_color", Color(0.55, 0.52, 0.48))
	Modal.button(overlay, StoryDB.t("ending_button"), 520, 590, 240, 60, b._end_fake_run)


static func _on_pope_defeated(b) -> void:
	if Morality.is_saint() or Morality.is_sinner():
		Dialogue.play(b, DialogueDB.get_lines("pope_defeat"), b._show_tree_reveal)
	else:
		Dialogue.play(b, DialogueDB.get_lines("pope_defeat"), b._show_fake_ending)

static func _show_title(b, text: String, next: Callable) -> void:
	var layer := ColorRect.new()
	layer.color = Color(0.02, 0.02, 0.03, 0.0)
	layer.size = Vector2(1280, 720)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_child(layer)

	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(0, 300)
	lbl.size = Vector2(1280, 120)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 64)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	lbl.modulate.a = 0.0
	StoryDB.apply_serif(lbl)
	layer.add_child(lbl)

	var tw: Tween = b.create_tween()
	tw.tween_property(layer, "color", Color(0.02, 0.02, 0.03, 0.94), 0.5)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.9)
	tw.tween_interval(1.2)
	tw.tween_property(layer, "color", Color(0.02, 0.02, 0.03, 0.0), 0.5)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		layer.queue_free()
		if next.is_valid():
			next.call()
	)

static func _start_tree_fight(b) -> void:
	b.node_type = "tree"
	b.enemy_organ = ""
	var data: Dictionary = EnemyDB.pick_for_node("tree", 0)
	b.enemy.setup(data)
	b.deck.hand.clear()
	b.deck.discard_pile.clear()
	b.deck.draw_pile.clear()
	for card in GameState.deck:
		b.deck.draw_pile.append(str(card))
	b.deck.draw_pile.shuffle()
	b.player_hp = GameState.player_max_hp
	b.player_block = 0
	b.player_status = {}
	b.player_energy = GameState.initial_energy()
	b._start_new_turn()
	Toast.show_text("树还在。\n它没有倒。", 3.5)

static func _enter_act3(b) -> void:
	GameState.act = 3
	GameState.allies.clear()
	# 人间不属于逐神游戏：第一幕死掉的人在这里都会再出现
	GameState.eliminated.clear()
	GameState.map_generated = false
	GameState.map_nodes = {}
	GameState.current_node_id = 0
	GameState.pending_snapshot = {}
	GameState.pending_node = -1
	GameState.pending_cleanup = false
	GameState.save_game()
	Dialogue.play(b, DialogueDB.get_lines("first_act3"), b._goto_act3_map)

static func _goto_act3_map(b) -> void:
	b.get_tree().change_scene_to_file("res://scenes/map.tscn")


static func _on_serpent_defeated(b) -> void:
	GameState.divinity = clampi(GameState.divinity, 0, 100)
	b._first_clear = not GameState.act3_cleared
	GameState.mark_act3_cleared()
	GameState.save_game()
	if GameState.divinity >= 71:
		Dialogue.play(b, DialogueDB.get_lines("ending_god"), b._show_serpent_ending)
	elif GameState.divinity >= 31:
		Dialogue.play(b, DialogueDB.get_lines("ending_loop"), b._show_serpent_ending)
	else:
		Dialogue.play(b, DialogueDB.get_lines("ending_human"), b._show_serpent_ending)

static func _show_serpent_ending(b) -> void:
	b.hand_view.hide_cards()
	var overlay := Modal.open(b, 0.97)
	var title := StoryDB.t("ending_god_title") if GameState.divinity >= 71 else (StoryDB.t("ending_loop_title") if GameState.divinity >= 31 else StoryDB.t("ending_human_title"))
	Modal.title(overlay, title, 150, 46)
	var stats := Modal.text(overlay, "第 %d 次转生\n剩余生命: %d / %d\n%s\n神性: %d" % [GameState.transmigration, b.player_hp, GameState.player_max_hp, Morality.summary(), GameState.divinity], 300, 20, 140)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))

	if b._first_clear:
		var unlock := Modal.text(overlay, "★ 解锁「自由配置」：下次开局可以自选职业与流派", 452, 18, 40)
		unlock.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	Modal.button(overlay, "回到开始", 530, 520, 220, 58, b._end_true_run)

static func _end_true_run(b) -> void:
	# 真结局：通关不删档，把「已通关」写进这个存档，下次可以自由配置
	GameState.mark_act3_cleared()
	GameState.pending_snapshot = {}
	GameState.pending_node = -1
	GameState.pending_cleanup = false
	GameState.pending_contestant = ""
	GameState.act = 3
	GameState.map_generated = false
	GameState.map_nodes = {}
	GameState.current_node_id = 0
	GameState.player_hp = GameState.player_max_hp
	GameState.save_game()
	b.get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

static func _end_fake_run(b) -> void:
	# 假结局：这一轮到此为止。存档保留（还停在打教皇之前），但什么都不解锁。
	b.get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

static func _enter_divine_realm(b) -> void:
	GameState.act = 2
	GameState.allies.clear()
	GameState.map_generated = false
	GameState.map_nodes = {}
	GameState.current_node_id = 0
	GameState.pending_snapshot = {}
	GameState.pending_node = -1
	GameState.pending_cleanup = false
	GameState.save_game()
	Dialogue.play(b, DialogueDB.get_lines("first_divine"), b._goto_divine_map)

static func _goto_divine_map(b) -> void:
	b.get_tree().change_scene_to_file("res://scenes/map.tscn")

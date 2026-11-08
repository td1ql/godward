extends Node
# 战斗胜利后的收尾（阶段 C）：奖励选牌 / 击杀复制 / 弃牌 / Boss 后的清理流程。
# 与 battle_hud.gd、battle_flow.gd 同一套路：静态函数，第一个参数 b 是 battle_demo.gd 的实例。

static func _surviving_contestants(b) -> Array[String]:
	var result: Array[String] = []
	for id in GameState.contestants:
		if GameState.eliminated.has(id):
			continue
		# 自愿退赛的不参与守门人之后的清算
		if GameState.retired.has(id):
			continue
		if GameState.allies.has(id):
			continue
		result.append(id)
	return result

static func _show_cleanup_prompt(b) -> void:
	b.hand_view.hide_cards()
	var n: int = b._surviving_contestants().size()

	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	b.add_child(overlay)

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
	btn.pressed.connect(b._begin_cleanup)
	overlay.add_child(btn)
	b._ghost_button(btn, 20)

static func _begin_cleanup(b) -> void:
	GameState.pending_cleanup = true
	GameState.save_game()
	b._start_next_cleanup()

static func _show_cleanup_result(b, text: String, summary: String) -> void:
	var overlay := Modal.open(b, 0.93)
	Modal.title(overlay, StoryDB.t("cleanup_result_title"), 150, 44)
	Modal.text(overlay, text, 260, 22, 60)
	var gain := Modal.text(overlay, summary if summary != "" else StoryDB.t("cleanup_result_empty"), 340, 20, 80)
	gain.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	var left: int = b._surviving_contestants().size()
	var label := StoryDB.f("cleanup_continue", [left]) if left > 0 else StoryDB.t("cleanup_go")
	Modal.button(overlay, label, 500, 470, 280, 64, b._start_next_cleanup)

static func _start_next_cleanup(b) -> void:
	var targets: Array = b._surviving_contestants()
	if targets.is_empty():
		GameState.pending_cleanup = false
		GameState.save_game()
		b._show_church()
		return

	var id: String = targets[0]
	var c: Dictionary = ContestantDB.get_contestant(id)
	var enemy_data := {
		"name": c["name"],
		"hp": int(c["hp"]),
		"attack": int(c["attack"]),
		"pattern": c.get("pattern", [1]),
		"on_hit": c.get("on_hit", {}),
		"domain": c.get("domain", {}),
		"skills": c.get("skills", []),
	}
	GameState.pending_enemy = enemy_data
	GameState.pending_contestant = id
	GameState.pending_snapshot = {"kind": "contestant_fight", "id": id, "enemy": enemy_data}
	GameState.save_game()
	b.get_tree().change_scene_to_file("res://scenes/main.tscn")

# 胜利后的第一步：先看有没有掉落物可选（三选一），没有就直接进选牌
static func _show_reward(b) -> void:
	b.hand_view.hide_cards()
	var pool := DropDB.pool_for_enemy(str(b.enemy.label_name))
	if pool.is_empty():
		_show_card_reward(b)
		return
	_show_drop_pick(b, pool)


# 掉落物三选一（池子里不够 3 个就全列出来）
static func _show_drop_pick(b, pool: Array) -> void:
	var cands := pool.duplicate()
	cands.shuffle()
	if cands.size() > 3:
		cands = cands.slice(0, 3)

	var overlay := Modal.open(b, 0.85)
	Modal.title(overlay, "掉　落", 110, 24)

	var hint := Label.new()
	hint.text = "从「%s」身上，挑一样带走。" % str(b.enemy.label_name)
	hint.position = Vector2(0, 158)
	hint.size = Vector2(1280, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	StoryDB.apply_serif(hint)
	overlay.add_child(hint)

	var n: int = cands.size()
	var spacing := 300.0
	var bw := 260.0
	var total := (n - 1) * spacing + bw
	var start_x := (1280.0 - total) / 2.0
	for i in range(n):
		var drop_id: String = str(cands[i])
		var btn := Button.new()
		btn.text = "%s\n\n%s\n（已有 %d）" % [
			DropDB.name_of(drop_id), DropDB.desc_of(drop_id), Inventory.drop_count(drop_id)]
		btn.position = Vector2(start_x + i * spacing, 210)
		btn.size = Vector2(bw, 180)
		btn.add_theme_font_size_override("font_size", 16)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.pressed.connect(_choose_drop.bind(b, overlay, drop_id))
		b._ghost_button(btn, 16)
		overlay.add_child(btn)

	var skip := Modal.button(overlay, "什么都不要", 540, 430, 200, 50, func() -> void:
		overlay.queue_free()
		_show_card_reward(b))
	b._ghost_button(skip, 18)


static func _choose_drop(b, overlay: Control, drop_id: String) -> void:
	Inventory.add_drop(drop_id, 1)
	Toast.show_text("拾得 %s" % DropDB.name_of(drop_id))
	GameState.save_game()
	overlay.queue_free()
	_show_card_reward(b)


# 选牌那一屏
static func _show_card_reward(b) -> void:
	var pool: Array = RewardDB.pick_cards(b.node_type, NodeRuleDB.cards_of(b.node_type), GameState.act)
	var overlay := Modal.open(b, 0.85)
	var title_key := "reward_title" if pool.size() > 0 else "reward_title_gold"
	Modal.title(overlay, StoryDB.f(title_key, [b.last_gold_gain]), 110, 24)

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
		btn.pressed.connect(b._choose_reward.bind(card_name))
		overlay.add_child(btn)
	var hint := Label.new()
	hint.text = "点击一张，加入牌组"
	hint.position = Vector2(0, 458)
	hint.size = Vector2(1280, 32)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	StoryDB.apply_serif(hint)
	overlay.add_child(hint)

	var help := Modal.button(overlay, "状态说明", 40, 610, 170, 44, func() -> void: StatusHelp.open(b))
	b._ghost_button(help, 18)

	if RunConfig.ALLOW_SKIP:
		var skip := Modal.button(overlay, StoryDB.t("reward_skip"), 540, 520, 200, 50, b._finish_reward)
		b._ghost_button(skip)

static func _choose_reward(b, card_name: String) -> void:
	GameState.deck.append(card_name)
	b._finish_reward()

static func _finish_reward(b) -> void:
	GameState.pending_node = -1
	GameState.pending_snapshot = {}
	GameState.save_game()
	if b._kill_pick_pending:
		b._kill_pick_pending = false
		DeckViewer.open_choose("收殓：从牌组中复制一张", GameState.deck, b._do_kill_pick)
		return
	if NodeRuleDB.discard_of(b.node_type):
		b._offer_discard()
		return
	b.get_tree().change_scene_to_file("res://scenes/map.tscn")

static func _do_kill_pick(b, index: int) -> void:
	if index >= 0 and index < GameState.deck.size():
		var c: String = GameState.deck[index]
		GameState.deck.append(c)
		GameState.save_game()
		Toast.show_text("「%s」又进了一份" % c, 2.5)
	b.get_tree().change_scene_to_file("res://scenes/map.tscn")

static func _offer_discard(b) -> void:
	DeckViewer.open_choose("精英战利品：弃掉一张牌", GameState.deck, b._discard_card)

static func _discard_card(b, index: int) -> void:
	if index >= 0 and index < GameState.deck.size():
		var removed: String = GameState.deck[index]
		GameState.deck.remove_at(index)
		Toast.show_text("弃掉了「%s」" % removed, 2.5)
	GameState.save_game()
	b.get_tree().change_scene_to_file("res://scenes/map.tscn")

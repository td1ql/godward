extends Node2D

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.1)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var title := Label.new()
	title.text = "逐 神 之 戏"
	title.position = Vector2(0, 50)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	add_child(title)

	var bx := 210
	if GameState.transmigration >= 3 and not GameState.milestone_card:
		var card_btn := Button.new()
		card_btn.text = "轮回馈赠 · 三选一效果牌"
		card_btn.size = Vector2(300, 50)
		card_btn.position = Vector2(bx, 520)
		card_btn.add_theme_font_size_override("font_size", 18)
		card_btn.pressed.connect(_claim_card)
		add_child(card_btn)
		bx += 320

	if GameState.transmigration >= 6 and not GameState.milestone_discard:
		var discard_btn := Button.new()
		discard_btn.text = "轮回馈赠 · 弃一张牌"
		discard_btn.size = Vector2(300, 50)
		discard_btn.position = Vector2(bx, 520)
		discard_btn.add_theme_font_size_override("font_size", 18)
		discard_btn.pressed.connect(_claim_discard)
		add_child(discard_btn)

	var enter := Button.new()
	enter.text = "进入神域"
	enter.size = Vector2(260, 64)
	enter.position = Vector2(510, 620)
	enter.add_theme_font_size_override("font_size", 24)
	enter.pressed.connect(_enter)
	add_child(enter)

	Dialogue.play(self, _intro_lines())

func _intro_lines() -> Array:
	var page1 := "%s\n\n词条：%s\n守则：%s\n\n初始生命 %d　初始金币 %d" % [
		TraitDB.vocation_text(GameState.vocation),
		TraitDB.text_of(GameState.traits),
		TraitDB.creed_text(GameState.vocation),
		GameState.player_hp,
		GameState.gold,
	]

	var rows := ""
	for id in GameState.contestants:
		var c: Dictionary = ContestantDB.get_contestant(id)
		if rows != "":
			rows += "\n"
		rows += "%s　·　%s　—　%s" % [c["name"], c["trait"], c["desc"]]

	return [
		{"speaker": "第 %d 次转生" % GameState.transmigration, "text": page1},
		{"speaker": "本轮参赛者", "text": rows},
	]

func _claim_card() -> void:
	GameState.milestone_card = true
	GameState.save_game()
	_show_card_pick()

func _claim_discard() -> void:
	GameState.milestone_discard = true
	GameState.save_game()
	DeckViewer.open_choose("轮回馈赠：弃掉一张牌", GameState.deck, _discard_pick)

func _show_card_pick() -> void:
	var pool: Array = []
	for id in CardDB.CARDS.keys():
		if CardDB.kind_of(id) == "effect" and not bool(CardDB.CARDS[id].get("divine", false)):
			pool.append(id)
	pool.shuffle()

	var options: Array = []
	for i in range(min(3, pool.size())):
		options.append(pool[i])

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
	title.text = "轮回馈赠：选择一张效果牌"
	title.position = Vector2(0, 100)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	overlay.add_child(title)

	var n := options.size()
	var spacing := 250.0
	var card_w := 200.0
	var total := (n - 1) * spacing + card_w
	var start_x := (1280.0 - total) / 2.0
	for i in range(n):
		var btn := CardUI.make_button(options[i], 18)
		btn.size = Vector2(card_w, 240)
		btn.position = Vector2(start_x + i * spacing, 200)
		btn.pressed.connect(_pick_card.bind(options[i], overlay))
		overlay.add_child(btn)

func _pick_card(card_name: String, overlay: Control) -> void:
	GameState.deck.append(card_name)
	GameState.save_game()
	overlay.queue_free()
	Toast.show_text("获得了「%s」" % card_name, 3.0)

func _discard_pick(index: int) -> void:
	if index >= 0 and index < GameState.deck.size():
		var removed: String = GameState.deck[index]
		GameState.deck.remove_at(index)
		Toast.show_text("弃掉了「%s」" % removed, 2.5)
	GameState.save_game()

func _enter() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")

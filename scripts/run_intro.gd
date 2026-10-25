extends Node2D

var _card_btn: Button
var _discard_btn: Button
var _claiming := false
var _claiming_discard := false
var _page_nodes: Array = []


func _add_meta_button() -> void:
	if not GameState.act3_cleared:
		return
	var cfg := Button.new()
	cfg.text = "自由配置"
	cfg.position = Vector2(20, 20)
	cfg.size = Vector2(170, 38)
	cfg.focus_mode = Control.FOCUS_NONE
	cfg.pressed.connect(func() -> void: MetaPick.open(self))
	UiKit.ghost_button(cfg, 18)
	add_child(cfg)

func _ready() -> void:
	var bg_path := "res://assets/art/bg/bg_intro.webp"
	if ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.size = Vector2(1280, 720)
		add_child(bg)
	else:
		var fallback := ColorRect.new()
		fallback.color = Color(0.06, 0.07, 0.1)
		fallback.size = Vector2(1280, 720)
		add_child(fallback)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.30)
	dim.size = Vector2(1280, 720)
	add_child(dim)

	var title := Label.new()
	title.text = "第 %d 次转生" % GameState.transmigration
	title.position = Vector2(0, 50)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	StoryDB.apply_serif(title)
	add_child(title)
	_page_nodes.append(title)
	var card_path := "res://assets/art/vocation/%s.webp" % GameState.vocation
	if ResourceLoader.exists(card_path):
		var card := TextureRect.new()
		card.texture = load(card_path)
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.position = Vector2(70, 140)
		card.size = Vector2(330, 549)
		add_child(card)
		_page_nodes.append(card)
	else:
		var ph := ColorRect.new()
		ph.color = Color(0.88, 0.84, 0.74, 0.8)
		ph.position = Vector2(70, 140)
		ph.size = Vector2(330, 549)
		add_child(ph)
		_page_nodes.append(ph)

	var panel := Panel.new()
	panel.position = Vector2(430, 150)
	panel.size = Vector2(820, 520)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.06, 0.09, 0.74)
	ps.border_width_left = 1
	ps.border_width_right = 1
	ps.border_width_top = 1
	ps.border_width_bottom = 1
	ps.border_color = Color(0.55, 0.44, 0.24, 0.45)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)
	_page_nodes.append(panel)

	var info := Label.new()
	info.text = "%s\n\n词条：%s\n守则：%s\n流派：%s\n\n初始生命 %d　　初始金币 %d" % [
		TraitDB.vocation_text(GameState.vocation),
		TraitDB.text_of(GameState.traits),
		TraitDB.creed_text(GameState.vocation),
		" / ".join(GameState.streams),
		GameState.player_hp,
		GameState.gold,
	]
	info.position = Vector2(460, 172)
	info.size = Vector2(750, 300)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color(0.87, 0.83, 0.73))
	StoryDB.apply_serif(info)
	add_child(info)
	_page_nodes.append(info)

	var bx := 470
	if GameState.transmigration >= 3 and not GameState.milestone_card:
		_card_btn = Button.new()
		_card_btn.text = "轮回馈赠 · 三选一效果牌"
		_card_btn.size = Vector2(330, 50)
		_card_btn.position = Vector2(bx, 500)
		_card_btn.add_theme_font_size_override("font_size", 18)
		_card_btn.pressed.connect(_claim_card)
		add_child(_card_btn)
		_page_nodes.append(_card_btn)
		bx += 350

	if GameState.transmigration >= 6 and not GameState.milestone_discard:
		_discard_btn = Button.new()
		_discard_btn.text = "轮回馈赠 · 弃一张牌"
		_discard_btn.size = Vector2(330, 50)
		_discard_btn.position = Vector2(bx, 500)
		_discard_btn.add_theme_font_size_override("font_size", 18)
		_discard_btn.pressed.connect(_claim_discard)
		add_child(_discard_btn)
		_page_nodes.append(_discard_btn)

	var enter := Button.new()
	enter.text = "戏幕开场"
	enter.position = Vector2(830, 592)
	enter.size = Vector2(340, 58)
	enter.focus_mode = Control.FOCUS_NONE
	enter.add_theme_font_size_override("font_size", 24)
	enter.add_theme_color_override("font_color", Color(0.93, 0.87, 0.71))
	enter.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.76))
	StoryDB.apply_serif(enter)

	var nb := StyleBoxFlat.new()
	nb.bg_color = Color(0, 0, 0, 0)
	nb.border_width_left = 1
	nb.border_width_right = 1
	nb.border_width_top = 1
	nb.border_width_bottom = 1
	nb.border_color = Color(0.62, 0.50, 0.28, 0.55)
	enter.add_theme_stylebox_override("normal", nb)

	var hb := nb.duplicate()
	hb.bg_color = Color(0.95, 0.85, 0.60, 0.10)
	hb.border_color = Color(0.85, 0.68, 0.34, 0.95)
	enter.add_theme_stylebox_override("hover", hb)
	enter.add_theme_stylebox_override("pressed", hb)
	enter.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	enter.add_theme_color_override("font_pressed_color", Color(1.0, 0.94, 0.76))
	enter.pressed.connect(_enter)
	add_child(enter)
	_page_nodes.append(enter)

	NavMenu.attach(self, [
		{"text": "牌库", "action": func() -> void: DeckViewer.toggle()},
		{"text": "返回主菜单", "action": func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn")},
	])
	_add_meta_button()
	for n in _page_nodes:
		if n != null:
			n.visible = false
	Dialogue.play(self, _intro_lines(), _show_page)

func _show_page() -> void:
	for n in _page_nodes:
		if n != null and is_instance_valid(n):
			n.visible = true

func _intro_lines() -> Array:
	var rows := ""
	for id in GameState.contestants:
		var c: Dictionary = ContestantDB.get_contestant(id)
		if rows != "":
			rows += "\n"
		rows += "%s　·　%s　—　%s" % [c["name"], c["trait"], str(c["desc"]).split("\n")[0]]

	return [
		{"speaker": "逐神之戏", "text": "加入这场游戏吧\n谈判，战斗，和平，同行\n这里没有规则，一切由你来决定\n但只有最后一人能获得觐见神明的机会\n去尽情杀戮吧"},
		{"speaker": "本轮参赛者", "text": rows},
	]

func _claim_card() -> void:
	if GameState.milestone_card or _claiming:
		return
	_claiming = true
	if _card_btn:
		_card_btn.queue_free()
		_card_btn = null
	_show_card_pick()

func _claim_discard() -> void:
	if GameState.milestone_discard or _claiming_discard:
		return
	_claiming_discard = true
	if _discard_btn:
		_discard_btn.queue_free()
		_discard_btn = null
	DeckViewer.open_choose("轮回馈赠：弃掉一张牌", GameState.deck, _discard_pick)

func _show_card_pick() -> void:
	var pool: Array = []
	for id in CardDB.CARDS.keys():
		var d: Dictionary = CardDB.CARDS[id]
		if CardDB.kind_of(id) != "effect":
			continue
		if bool(d.get("divine", false)) or bool(d.get("remnant", false)) or bool(d.get("event", false)):
			continue
		if bool(d.get("tutorial", false)):
			continue
		if bool(d.get("exclusive", false)):
			continue
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
	if overlay == null or not is_instance_valid(overlay):
		return
	overlay.visible = false
	GameState.deck.append(card_name)
	GameState.milestone_card = true
	GameState.save_game()
	overlay.queue_free()
	Toast.show_text("获得了「%s」" % card_name, 3.0)

func _discard_pick(index: int) -> void:
	if index >= 0 and index < GameState.deck.size():
		var removed: String = GameState.deck[index]
		GameState.deck.remove_at(index)
		Toast.show_text("弃掉了「%s」" % removed, 2.5)
	GameState.milestone_discard = true
	GameState.save_game()

func _style_ghost(b: Button) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color(0.93, 0.88, 0.74))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.76))
	StoryDB.apply_serif(b)

	var nb := StyleBoxFlat.new()
	nb.bg_color = Color(0, 0, 0, 0)
	nb.border_width_left = 1
	nb.border_width_right = 1
	nb.border_width_top = 1
	nb.border_width_bottom = 1
	nb.border_color = Color(0.62, 0.50, 0.28, 0.50)
	b.add_theme_stylebox_override("normal", nb)

	var hb := nb.duplicate()
	hb.bg_color = Color(0.95, 0.85, 0.60, 0.12)
	hb.border_color = Color(0.85, 0.68, 0.34, 0.95)
	b.add_theme_stylebox_override("hover", hb)
	b.add_theme_stylebox_override("pressed", hb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _enter() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")

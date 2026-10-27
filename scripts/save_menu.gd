extends Node2D

func _ready() -> void:
	AudioManager.play_bgm("menu")
	NavMenu.attach(self, [
		{"text": "返回主菜单", "action": func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn")},
	])
	var bg_path := "res://assets/art/bg/bg_menu.webp"
	if ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.size = Vector2(1280, 720)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.08, 0.74)
	dim.size = Vector2(1280, 720)
	add_child(dim)

	var title := Label.new()
	title.text = "存 档"
	title.position = Vector2(0, 48)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.93, 0.87, 0.71))
	StoryDB.apply_serif(title)
	add_child(title)

	var sub := Label.new()
	sub.text = "三卷名册，各记一世"
	sub.position = Vector2(0, 126)
	sub.size = Vector2(1280, 32)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.62, 0.57, 0.47))
	StoryDB.apply_serif(sub)
	add_child(sub)

	for i in range(GameState.SLOT_COUNT):
		_build_slot(i)

	var back := _solid_button("返回", 540, 626, 200, 54)
	back.pressed.connect(_on_back)
	_build_debug_buttons()


func _build_slot(i: int) -> void:
	var has := GameState.has_save(i)
	var y := 186 + i * 140

	var panel := Panel.new()
	panel.position = Vector2(200, y)
	panel.size = Vector2(880, 114)
	panel.add_theme_stylebox_override("panel", _parchment(Color(0.91, 0.87, 0.77, 0.96), Color(0.50, 0.38, 0.18, 0.62)))
	add_child(panel)

	var tag := Label.new()
	tag.text = "存档 · %s" % ["一", "二", "三"][i]
	tag.position = Vector2(232, y + 20)
	tag.size = Vector2(320, 28)
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", Color(0.46, 0.37, 0.23))
	StoryDB.apply_serif(tag)
	add_child(tag)

	var info := Label.new()
	if has:
		info.text = GameState.slot_summary(i)
		info.add_theme_color_override("font_color", Color(0.16, 0.14, 0.10))
	else:
		info.text = "此处尚空"
		info.add_theme_color_override("font_color", Color(0.48, 0.44, 0.37))
	info.position = Vector2(232, y + 54)
	info.size = Vector2(560, 40)
	info.add_theme_font_size_override("font_size", 22)
	StoryDB.apply_serif(info)
	add_child(info)

	if has:
		var cont := _slot_button("继续", 800, y + 31, 120)
		cont.pressed.connect(func(): _continue(i))
		var del := _slot_button("删除", 940, y + 31, 120)
		del.pressed.connect(func(): _delete(i))
	else:
		var new_btn := _slot_button("新建", 880, y + 31, 160)
		new_btn.pressed.connect(func(): _new_game(i))

func _parchment(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = border
	s.corner_radius_top_left = 3
	s.corner_radius_top_right = 3
	s.corner_radius_bottom_left = 3
	s.corner_radius_bottom_right = 3
	return s

func _solid_button(content: String, x: float, y: float, w: float, h: float) -> Button:
	var b := Button.new()
	b.text = content
	b.position = Vector2(x, y)
	b.size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color(0.20, 0.17, 0.12))
	b.add_theme_color_override("font_hover_color", Color(0.08, 0.06, 0.04))
	StoryDB.apply_serif(b)
	b.add_theme_stylebox_override("normal", _parchment(Color(0.91, 0.87, 0.77, 0.96), Color(0.50, 0.38, 0.18, 0.62)))
	b.add_theme_stylebox_override("hover", _parchment(Color(0.95, 0.91, 0.81, 1.0), Color(0.62, 0.46, 0.18, 0.95)))
	b.add_theme_stylebox_override("pressed", _parchment(Color(0.84, 0.80, 0.70, 1.0), Color(0.45, 0.33, 0.15, 1.0)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(b)
	return b

func _slot_button(content: String, x: float, y: float, w: float) -> Button:
	var b := Button.new()
	b.text = content
	b.position = Vector2(x, y)
	b.size = Vector2(w, 52)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color(0.20, 0.17, 0.12))
	b.add_theme_color_override("font_hover_color", Color(0.62, 0.42, 0.14))
	StoryDB.apply_serif(b)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.42, 0.33, 0.20, 0.55)
	b.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.18, 0.14, 0.08, 0.10)
	hover.border_color = Color(0.58, 0.42, 0.16, 0.95)
	b.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.18, 0.14, 0.08, 0.18)
	pressed.border_color = Color(0.45, 0.33, 0.15, 1.0)
	b.add_theme_stylebox_override("pressed", pressed)

	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(b)
	return b

func _continue(slot: int) -> void:
	if GameState.load_game(slot):
		if GameState.map_generated:
			get_tree().change_scene_to_file("res://scenes/map.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/run_intro.tscn")

func _new_game(slot: int) -> void:
	GameState.current_slot = slot
	GameState.reset_run()
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/run_intro.tscn")

func _delete(slot: int) -> void:
	# 二级确认：删档不可撤销
	var overlay := Modal.open(self, 0.88)
	Modal.title(overlay, "删除存档", 140, 38)
	Modal.text(overlay, "存档 · %s\n\n删掉之后，这一轮的职业、牌组、金币都会消失。\n不能撤回。" % _slot_name(slot), 260, 20, 140)

	Modal.button(overlay, "确认删除", 360, 460, 240, 56, func() -> void:
		overlay.queue_free()
		GameState.delete_save(slot)
		get_tree().reload_current_scene()
	)
	Modal.button(overlay, "算了", 680, 460, 240, 56, overlay.queue_free)

func _slot_name(slot: int) -> String:
	return ["一", "二", "三"][clampi(slot, 0, 2)]

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ===== 调试入口（仅调试版可见，导出版没有）=====
func _debug_starter_deck() -> Array[String]:
	var out: Array[String] = []
	for c in ["打击", "打击", "防御", "防御", "淬毒", "毒潮", "催化", "毒源", "引爆", "千刀万剐", "麻痹", "铁骨"]:
		if CardDB.CARDS.has(c):
			out.append(str(c))
	return out

func _debug_prepare(act: int) -> void:
	GameState.act = act
	GameState.player_max_hp = 150
	GameState.player_hp = 150
	GameState.gold = 300
	GameState.divinity = 50
	GameState.map_generated = false
	GameState.map_nodes = {}
	GameState.current_node_id = 0
	GameState.pending_snapshot = {}
	GameState.pending_node = -1
	GameState.pending_cleanup = false
	GameState.deck = _debug_starter_deck()
	GameState.save_game()

func _debug_act3() -> void:
	_debug_prepare(3)
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _debug_serpent() -> void:
	_debug_prepare(3)
	GameState.pending_snapshot = {"kind": "battle", "node_type": "serpent", "enemy": EnemyDB.pick_for_node("serpent", 0)}
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _debug_act2() -> void:
	_debug_prepare(2)
	get_tree().change_scene_to_file("res://scenes/map.tscn")


# 打开英雄 NPC 的对话样板（只对阿喀琉斯有效）
func _debug_npc() -> void:
	NpcView.open(self, "阿喀琉斯", func(_what: String, _who: String) -> void:
		Toast.show_text("（样板结束）", 2.0)
	)

func _build_debug_buttons() -> void:
	if not OS.is_debug_build():
		return
	var items := [
		{"text": "调试：第三幕", "action": _debug_act3},
		{"text": "调试：第二幕", "action": _debug_act2},
		{"text": "调试：耶梦加得", "action": _debug_serpent},
		{"text": "调试：英雄 NPC", "action": _debug_npc},
	]
	var y := 610.0
	for it in items:
		var b := Button.new()
		b.text = str(it["text"])
		b.position = Vector2(40, y)
		b.size = Vector2(190, 32)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 14)
		var act: Callable = it["action"]
		b.pressed.connect(act)
		UiKit.ghost_button(b, 14)
		add_child(b)
		y += 36.0

extends Node2D

var _mute_btn: Button


func _ready() -> void:
	var bg_path := "res://assets/art/bg/bg_menu.png"
	if ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.size = Vector2(1280, 720)
		add_child(bg)
	else:
		var fallback := ColorRect.new()
		fallback.color = Color(0.07, 0.08, 0.11)
		fallback.size = Vector2(1280, 720)
		add_child(fallback)


	var title := Label.new()
	title.text = "逐 神"
	title.position = Vector2(640, 250)
	title.size = Vector2(600, 110)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 70)
	title.add_theme_color_override("font_color", Color(0.13, 0.14, 0.20))
	StoryDB.apply_serif(title)
	add_child(title)

	var sub := Label.new()
	sub.text = "Godward"
	sub.position = Vector2(640, 365)
	sub.size = Vector2(600, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(0.37, 0.31, 0.25))
	StoryDB.apply_serif(sub)
	add_child(sub)

	var start := _make_menu_button("开始游戏", 438)
	start.pressed.connect(_on_start)

	_mute_btn = _make_menu_button("", 498)
	_mute_btn.pressed.connect(_on_toggle_audio)
	_update_mute_btn()

	var quit := _make_menu_button("退出游戏", 558)
	quit.pressed.connect(_on_quit)
	_check_prologue()

func _update_mute_btn() -> void:
	_mute_btn.text = "音效：" + ("开" if not AudioManager.muted else "关")

func _make_menu_button(content: String, y: float) -> Button:
	var b := Button.new()
	b.text = content
	b.position = Vector2(770, y)
	b.size = Vector2(430, 54)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", Color(0.18, 0.16, 0.13))
	b.add_theme_color_override("font_hover_color", Color(0.45, 0.32, 0.15))
	b.add_theme_color_override("font_pressed_color", Color(0.10, 0.09, 0.07))
	StoryDB.apply_serif(b)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.0)
	normal.border_width_bottom = 1
	normal.border_color = Color(0.42, 0.33, 0.20, 0.45)
	b.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.16, 0.14, 0.10, 0.07)
	hover.border_width_bottom = 1
	hover.border_color = Color(0.55, 0.42, 0.20, 0.85)
	b.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.16, 0.14, 0.10, 0.14)
	pressed.border_width_bottom = 1
	pressed.border_color = Color(0.55, 0.42, 0.20, 0.95)
	b.add_theme_stylebox_override("pressed", pressed)

	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(b)
	return b

func _on_toggle_audio() -> void:
	AudioManager.set_muted(not AudioManager.muted)
	_update_mute_btn()

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/save_menu.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _check_prologue() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	var stage: int = int(cfg.get_value("story", "prologue_stage", -1))
	if stage < 0:
		if bool(cfg.get_value("story", "prologue_part2", false)):
			stage = 3
		elif bool(cfg.get_value("story", "prologue_part1", false)):
			stage = 2
		else:
			stage = 0
	if stage >= 3:
		return
	if stage == 0:
		Dialogue.play(self, DialogueDB.get_lines("prologue"), _start_tutorial, _skip_prologue)
	elif stage == 1:
		_start_tutorial()
	elif stage == 2:
		Dialogue.play(self, DialogueDB.get_lines("prologue_after"), _finish_prologue)

func _set_stage(v: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("story", "prologue_stage", v)
	cfg.save("user://settings.cfg")

func _start_tutorial() -> void:
	_set_stage(1)
	GameState.pending_snapshot = {"kind": "tutorial"}
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _finish_prologue() -> void:
	_set_stage(3)

func _skip_prologue() -> void:
	_set_stage(3)

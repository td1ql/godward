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
	title.position = Vector2(0, 140)
	title.size = Vector2(1280, 130)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(0.11, 0.13, 0.20))
	StoryDB.apply_serif(title)
	add_child(title)

	var sub := Label.new()
	sub.text = "Godward　·　逐 神 之 戏"
	sub.position = Vector2(0, 280)
	sub.size = Vector2(1280, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(0.40, 0.36, 0.30))
	StoryDB.apply_serif(sub)
	add_child(sub)

	var start := Button.new()
	start.text = "开始游戏"
	start.size = Vector2(320, 64)
	start.position = Vector2(480, 370)
	start.add_theme_font_size_override("font_size", 24)
	start.pressed.connect(_on_start)
	add_child(start)

	_mute_btn = Button.new()
	_mute_btn.size = Vector2(320, 60)
	_mute_btn.position = Vector2(480, 455)
	_mute_btn.add_theme_font_size_override("font_size", 22)
	_mute_btn.pressed.connect(_on_toggle_audio)
	add_child(_mute_btn)
	_update_mute_btn()

	var quit := Button.new()
	quit.text = "退出游戏"
	quit.size = Vector2(320, 60)
	quit.position = Vector2(480, 540)
	quit.add_theme_font_size_override("font_size", 22)
	quit.pressed.connect(_on_quit)
	add_child(quit)
	_check_prologue()

func _update_mute_btn() -> void:
	_mute_btn.text = "音效：" + ("开" if not AudioManager.muted else "关")

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

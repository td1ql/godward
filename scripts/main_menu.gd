extends Node2D

var _mute_btn: Button

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var title := Label.new()
	title.text = "逐 神"
	title.position = Vector2(0, 110)
	title.size = Vector2(1280, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	add_child(title)

	var sub := Label.new()
	sub.text = "Godward · Roguelike 卡牌构筑"
	sub.position = Vector2(0, 210)
	sub.size = Vector2(1280, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	add_child(sub)

	var start := Button.new()
	start.text = "开始游戏"
	start.size = Vector2(320, 64)
	start.position = Vector2(480, 320)
	start.add_theme_font_size_override("font_size", 24)
	start.pressed.connect(_on_start)
	add_child(start)

	_mute_btn = Button.new()
	_mute_btn.size = Vector2(320, 60)
	_mute_btn.position = Vector2(480, 410)
	_mute_btn.add_theme_font_size_override("font_size", 22)
	_mute_btn.pressed.connect(_on_toggle_audio)
	add_child(_mute_btn)
	_update_mute_btn()

	var quit := Button.new()
	quit.text = "退出游戏"
	quit.size = Vector2(320, 60)
	quit.position = Vector2(480, 495)
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
	var part1 := bool(cfg.get_value("story", "prologue_part1", false))
	var part2 := bool(cfg.get_value("story", "prologue_part2", false))
	if part2:
		return
	if part1:
		Dialogue.play(self, DialogueDB.get_lines("prologue_after"), _finish_prologue)
		return
	Dialogue.play(self, DialogueDB.get_lines("prologue"), _start_tutorial, _skip_prologue)

func _start_tutorial() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("story", "prologue_part1", true)
	cfg.save("user://settings.cfg")
	GameState.pending_snapshot = {"kind": "tutorial"}
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _finish_prologue() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("story", "prologue_part2", true)
	cfg.save("user://settings.cfg")

func _skip_prologue() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("story", "prologue_part1", true)
	cfg.set_value("story", "prologue_part2", true)
	cfg.save("user://settings.cfg")

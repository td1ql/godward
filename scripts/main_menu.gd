extends Node2D

var _mute_btn: Button

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var title := Label.new()
	title.text = "Slay the Tower"
	title.position = Vector2(0, 110)
	title.size = Vector2(1280, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	add_child(title)

	var sub := Label.new()
	sub.text = "杀戮塔 · Roguelike 卡牌构筑"
	sub.position = Vector2(0, 205)
	sub.size = Vector2(1280, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	add_child(sub)

	var cont := Button.new()
	cont.text = "继续"
	cont.size = Vector2(300, 64)
	cont.position = Vector2(490, 290)
	cont.add_theme_font_size_override("font_size", 24)
	cont.disabled = not GameState.has_save()
	cont.pressed.connect(_on_continue)
	add_child(cont)

	var start := Button.new()
	start.text = "开始新游戏"
	start.size = Vector2(300, 64)
	start.position = Vector2(490, 370)
	start.add_theme_font_size_override("font_size", 24)
	start.pressed.connect(_on_start)
	add_child(start)

	_mute_btn = Button.new()
	_mute_btn.size = Vector2(300, 64)
	_mute_btn.position = Vector2(490, 450)
	_mute_btn.add_theme_font_size_override("font_size", 24)
	_mute_btn.pressed.connect(_on_toggle_audio)
	add_child(_mute_btn)
	_update_mute_btn()

	var quit := Button.new()
	quit.text = "退出游戏"
	quit.size = Vector2(300, 64)
	quit.position = Vector2(490, 530)
	quit.add_theme_font_size_override("font_size", 24)
	quit.pressed.connect(_on_quit)
	add_child(quit)

func _update_mute_btn() -> void:
	_mute_btn.text = "音效：" + ("开" if not AudioManager.muted else "关")

func _on_toggle_audio() -> void:
	AudioManager.set_muted(not AudioManager.muted)
	_update_mute_btn()

func _on_continue() -> void:
	if GameState.load_game():
		get_tree().change_scene_to_file("res://scenes/map.tscn")

func _on_start() -> void:
	GameState.reset_run()
	GameState.delete_save()
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _on_quit() -> void:
	get_tree().quit()

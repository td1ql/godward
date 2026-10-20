extends Node2D

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var title := Label.new()
	title.text = "Slay the Tower"
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	add_child(title)

	var sub := Label.new()
	sub.text = "杀戮塔 · Roguelike 卡牌构筑"
	sub.position = Vector2(0, 245)
	sub.size = Vector2(1280, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	add_child(sub)

	var start := Button.new()
	start.text = "开始新游戏"
	start.size = Vector2(300, 68)
	start.position = Vector2(490, 380)
	start.add_theme_font_size_override("font_size", 24)
	start.pressed.connect(_on_start)
	add_child(start)

	var quit := Button.new()
	quit.text = "退出游戏"
	quit.size = Vector2(300, 68)
	quit.position = Vector2(490, 480)
	quit.add_theme_font_size_override("font_size", 24)
	quit.pressed.connect(_on_quit)
	add_child(quit)

func _on_start() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _on_quit() -> void:
	get_tree().quit()

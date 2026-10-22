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

	var info := Label.new()
	info.text = "第 %d 次转生　·　职业：%s" % [GameState.transmigration, TraitDB.vocation_text(GameState.vocation)]
	info.position = Vector2(0, 130)
	info.size = Vector2(1280, 40)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 22)
	info.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	add_child(info)

	var traits := Label.new()
	traits.text = "词条：%s\n初始生命 %d　初始金币 %d" % [TraitDB.text_of(GameState.traits), GameState.player_hp, GameState.gold]
	traits.position = Vector2(0, 180)
	traits.size = Vector2(1280, 60)
	traits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	traits.add_theme_font_size_override("font_size", 18)
	add_child(traits)

	var list_title := Label.new()
	list_title.text = "本轮参赛者"
	list_title.position = Vector2(0, 255)
	list_title.size = Vector2(1280, 30)
	list_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_title.add_theme_font_size_override("font_size", 22)
	add_child(list_title)

	var y := 305
	for id in GameState.contestants:
		var c: Dictionary = ContestantDB.get_contestant(id)
		var row := Label.new()
		row.text = "%s　·　%s　—　%s" % [c["name"], c["trait"], c["desc"]]
		row.position = Vector2(120, y)
		row.size = Vector2(1040, 30)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 17)
		add_child(row)
		y += 36

	var btn := Button.new()
	btn.text = "进入神域"
	btn.size = Vector2(260, 64)
	btn.position = Vector2(510, 620)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_enter)
	add_child(btn)

func _enter() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")

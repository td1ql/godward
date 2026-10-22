extends Node2D

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var title := Label.new()
	title.text = "存 档"
	title.position = Vector2(0, 60)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	add_child(title)

	for i in range(GameState.SLOT_COUNT):
		_build_slot(i)

	var back := Button.new()
	back.text = "返回"
	back.size = Vector2(200, 56)
	back.position = Vector2(540, 620)
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(_on_back)
	add_child(back)

func _build_slot(i: int) -> void:
	var has := GameState.has_save(i)
	var y := 170 + i * 135

	var panel := ColorRect.new()
	panel.color = Color(0.13, 0.14, 0.19)
	panel.position = Vector2(220, y)
	panel.size = Vector2(840, 110)
	add_child(panel)

	var info := Label.new()
	if has:
		info.text = "存档 %d　%s" % [i + 1, GameState.slot_summary(i)]
	else:
		info.text = "存档 %d　空" % (i + 1)
	info.position = Vector2(250, y + 34)
	info.size = Vector2(560, 50)
	info.add_theme_font_size_override("font_size", 20)
	add_child(info)

	if has:
		var cont := Button.new()
		cont.text = "继续"
		cont.size = Vector2(110, 50)
		cont.position = Vector2(780, y + 30)
		cont.pressed.connect(func(): _continue(i))
		add_child(cont)

		var del := Button.new()
		del.text = "删除"
		del.size = Vector2(110, 50)
		del.position = Vector2(900, y + 30)
		del.pressed.connect(func(): _delete(i))
		add_child(del)
	else:
		var new_btn := Button.new()
		new_btn.text = "新建"
		new_btn.size = Vector2(110, 50)
		new_btn.position = Vector2(900, y + 30)
		new_btn.pressed.connect(func(): _new_game(i))
		add_child(new_btn)

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
	GameState.delete_save(slot)
	get_tree().reload_current_scene()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

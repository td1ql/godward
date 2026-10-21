extends Node2D

var _mute_btn: Button

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var title := Label.new()
	title.text = "Slay the Tower"
	title.position = Vector2(0, 80)
	title.size = Vector2(1280, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	add_child(title)

	var sub := Label.new()
	sub.text = "杀戮塔 · Roguelike 卡牌构筑"
	sub.position = Vector2(0, 175)
	sub.size = Vector2(1280, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	add_child(sub)

	for i in range(GameState.SLOT_COUNT):
		var summary := GameState.slot_summary(i)
		var btn := Button.new()
		if summary == "空":
			btn.text = "存档 %d · 空（点击开始新游戏）" % (i + 1)
		else:
			btn.text = "存档 %d · %s" % [i + 1, summary]
		btn.size = Vector2(460, 58)
		btn.position = Vector2(410, 250 + i * 74)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_slot.bind(i))
		add_child(btn)

	_mute_btn = Button.new()
	_mute_btn.size = Vector2(420, 54)
	_mute_btn.position = Vector2(430, 510)
	_mute_btn.add_theme_font_size_override("font_size", 22)
	_mute_btn.pressed.connect(_on_toggle_audio)
	add_child(_mute_btn)
	_update_mute_btn()

	var quit := Button.new()
	quit.text = "退出游戏"
	quit.size = Vector2(420, 54)
	quit.position = Vector2(430, 580)
	quit.add_theme_font_size_override("font_size", 22)
	quit.pressed.connect(_on_quit)
	var hint := Label.new()
	hint.text = "点空槽位开始新游戏；点有存档的槽位可继续或重开"
	hint.position = Vector2(0, 468)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	add_child(hint)
	add_child(quit)

func _update_mute_btn() -> void:
	_mute_btn.text = "音效：" + ("开" if not AudioManager.muted else "关")

func _on_toggle_audio() -> void:
	AudioManager.set_muted(not AudioManager.muted)
	_update_mute_btn()

func _on_slot(slot: int) -> void:
	if not GameState.has_save(slot):
		_start_new(slot)
		return
	_show_slot_dialog(slot)

func _start_new(slot: int) -> void:
	GameState.current_slot = slot
	GameState.reset_run()
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _show_slot_dialog(slot: int) -> void:
	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var panel := ColorRect.new()
	panel.color = Color(0.13, 0.14, 0.19)
	panel.position = Vector2(440, 240)
	panel.size = Vector2(400, 280)
	overlay.add_child(panel)

	var title := Label.new()
	title.text = "存档 %d" % (slot + 1)
	title.position = Vector2(460, 260)
	title.size = Vector2(360, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	overlay.add_child(title)

	var cont := Button.new()
	cont.text = "继续"
	cont.size = Vector2(300, 50)
	cont.position = Vector2(490, 320)
	cont.pressed.connect(func():
		if GameState.load_game(slot):
			get_tree().change_scene_to_file("res://scenes/map.tscn")
	)
	overlay.add_child(cont)

	var restart := Button.new()
	restart.text = "重新开始（覆盖本档）"
	restart.size = Vector2(300, 50)
	restart.position = Vector2(490, 390)
	restart.pressed.connect(func():
		_start_new(slot)
	)
	overlay.add_child(restart)

	var cancel := Button.new()
	cancel.text = "取消"
	cancel.size = Vector2(300, 50)
	cancel.position = Vector2(490, 460)
	cancel.pressed.connect(overlay.queue_free)
	overlay.add_child(cancel)
func _on_quit() -> void:
	get_tree().quit()

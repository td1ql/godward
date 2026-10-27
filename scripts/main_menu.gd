extends Node2D

var _mute_btn: Button
var _bgm_btn: Button
var _master_btn: Button
var _quit_btn: Button
var _silence_btn: Button
var _sub_open := false


const CardDump = preload("res://tools/dump_cards.gd")
const StoryDump = preload("res://tools/dump_story.gd")

func _ready() -> void:
	# 开发用：带 --dump-cards 参数启动时，只导出卡表然后退出
	if "--dump-cards" in OS.get_cmdline_user_args():
		CardDump.write()
		get_tree().quit()
		return
	if "--dump-story" in OS.get_cmdline_user_args():
		StoryDump.write()
		get_tree().quit()
		return
	if "--test-npc" in OS.get_cmdline_user_args():
		# 冒烟测试：打开 NPC 界面，看有没有运行时报错
		NpcView.open(self, "阿喀琉斯", func(_a: String, _b: String) -> void: pass)
		print("[npc] opened ok")
		get_tree().quit()
		return
	AudioManager.play_bgm("menu")
	var bg_path := "res://assets/art/bg/bg_menu.webp"
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
	title.position = Vector2(685, 175)
	title.size = Vector2(600, 110)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 70)
	title.add_theme_color_override("font_color", Color(0.13, 0.14, 0.20))
	StoryDB.apply_serif(title)
	add_child(title)

	var sub := Label.new()
	sub.text = "Godward"
	sub.position = Vector2(685, 290)
	sub.size = Vector2(600, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(0.37, 0.31, 0.25))
	StoryDB.apply_serif(sub)
	add_child(sub)

	var start := _make_menu_button("开始游戏", 390)
	start.pressed.connect(_on_start)

	_master_btn = _make_menu_button("", 444)
	_master_btn.pressed.connect(_on_master_pressed)
	_update_master_btn()

	_mute_btn = _make_menu_button("", 498)
	_mute_btn.pressed.connect(_on_toggle_audio)
	_mute_btn.visible = false
	_update_mute_btn()

	_bgm_btn = _make_menu_button("", 552)
	_bgm_btn.pressed.connect(_on_toggle_bgm)
	_bgm_btn.visible = false
	_update_bgm_btn()

	_silence_btn = _make_menu_button("", 606)
	_silence_btn.pressed.connect(_on_toggle_master)
	_silence_btn.visible = false
	_update_silence_btn()

	_quit_btn = _make_menu_button("退出游戏", 498)
	_quit_btn.pressed.connect(_on_quit)
	_check_prologue()

func _update_mute_btn() -> void:
	_mute_btn.text = "音效：" + ("开" if not AudioManager.muted else "关")

func _update_master_btn() -> void:
	var arrow := "▼" if _sub_open else "▶"
	_master_btn.text = "声音设置  " + arrow

# 点「全部声音」：展开/收起子菜单
func _on_master_pressed() -> void:
	_sub_open = not _sub_open
	_apply_sub_state()
	_update_master_btn()

func _update_silence_btn() -> void:
	_silence_btn.text = "静音全部：" + ("开" if AudioManager.master_muted else "关")

func _apply_sub_state() -> void:
	_mute_btn.visible = _sub_open
	_bgm_btn.visible = _sub_open
	_silence_btn.visible = _sub_open
	_quit_btn.position = Vector2(_quit_btn.position.x, 660 if _sub_open else 498)

func _on_toggle_master() -> void:
	AudioManager.set_master_muted(not AudioManager.master_muted)
	_update_master_btn()
	_update_mute_btn()
	_update_bgm_btn()
	_update_silence_btn()

func _update_bgm_btn() -> void:
	_bgm_btn.text = "音乐：" + ("开" if not AudioManager.bgm_muted else "关")

func _on_toggle_bgm() -> void:
	AudioManager.set_bgm_muted(not AudioManager.bgm_muted)
	_update_bgm_btn()

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

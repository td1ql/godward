extends Node2D


# ============================================================
# 存档界面 —— 明日方舟风格
#   深墨底 + 切角面板 + 金色细线 + 章节副标题
# ============================================================

const ArkPanel = preload("res://scripts/ark_panel.gd")
const GridOverlay = preload("res://scripts/grid_overlay.gd")

const GOLD := Color("c9a86a")
const GOLD_HI := Color("e6c98c")
const CREAM := Color("ede0c7")
const DIM := Color(0.55, 0.51, 0.44)


func _ready() -> void:
	AudioManager.play_bgm("menu")

	var bg_path := "res://assets/art/bg/bg_menu.webp"
	if ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.size = Vector2(1280, 720)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.z_index = -10
		add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0.016, 0.023, 0.031, 0.80)
	dim.size = Vector2(1280, 720)
	dim.z_index = -9
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var grid := GridOverlay.new()
	grid.z_index = -8
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grid)

	# 标题：右下角切角的大字
	var title := Label.new()
	title.text = "存 档"
	title.position = Vector2(120, 62)
	title.size = Vector2(600, 76)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", CREAM)
	StoryDB.apply_serif(title)
	title.z_index = 5
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var sub := Label.new()
	sub.text = "S A V E   D A T A"
	sub.position = Vector2(124, 142)
	sub.size = Vector2(600, 24)
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(GOLD, 0.75))
	sub.z_index = 5
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	var tag := Label.new()
	tag.text = "三卷名册，各记一世"
	tag.position = Vector2(760, 100)
	tag.size = Vector2(400, 30)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", DIM)
	StoryDB.apply_serif(tag)
	tag.z_index = 5
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)

	var rule := ColorRect.new()
	rule.color = Color(GOLD, 0.30)
	rule.position = Vector2(120, 174)
	rule.size = Vector2(1040, 1)
	rule.z_index = 5
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)

	for i in range(GameState.SLOT_COUNT):
		_build_slot(i)
	# 记录每个槽的节点组，供入场动画使用

	var back := _ghost_button("返 回", 540, 630, 200, 50)
	back.pressed.connect(_on_back)
	_build_debug_buttons()


func _build_slot(i: int) -> void:
	var has := GameState.has_save(i)
	var y := 196 + i * 132

	# 切角底板
	var panel := ArkPanel.new()
	panel.position = Vector2(120, y)
	panel.size = Vector2(1040, 112)
	panel.cut = 22.0
	panel.alpha = 0.72 if has else 0.42
	panel.z_index = 1
	add_child(panel)

	# 左侧序号块（金色数字）
	var idx := Label.new()
	idx.text = ["01", "02", "03"][i]
	idx.position = Vector2(146, y + 24)
	idx.size = Vector2(80, 60)
	idx.add_theme_font_size_override("font_size", 40)
	idx.add_theme_color_override("font_color", Color(GOLD_HI, 0.85) if has else Color(0.42, 0.39, 0.33, 0.7))
	idx.z_index = 5
	idx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(idx)

	var sep := ColorRect.new()
	sep.color = Color(GOLD, 0.22 if has else 0.10)
	sep.position = Vector2(238, y + 22)
	sep.size = Vector2(1, 68)
	sep.z_index = 5
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	var tag := Label.new()
	tag.text = "存档 · %s" % ["一", "二", "三"][i]
	tag.position = Vector2(262, y + 20)
	tag.size = Vector2(320, 24)
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color(0.52, 0.48, 0.41))
	StoryDB.apply_serif(tag)
	tag.z_index = 5
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)

	var info := Label.new()
	if has:
		info.text = GameState.slot_summary(i)
		info.add_theme_color_override("font_color", CREAM)
	else:
		info.text = "此处尚空"
		info.add_theme_color_override("font_color", Color(0.40, 0.37, 0.32))
	info.position = Vector2(262, y + 50)
	info.size = Vector2(510, 40)
	info.add_theme_font_size_override("font_size", 24)
	StoryDB.apply_serif(info)
	info.z_index = 5
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info)

	if has:
		var cont := _line_button("继 续", 790, y + 34, 130)
		cont.pressed.connect(func(): _continue(i))
		var del := _line_button("删 除", 936, y + 34, 130)
		del.pressed.connect(func(): _delete(i))
	else:
		var new_btn := _line_button("新 建", 880, y + 34, 150)
		new_btn.pressed.connect(func(): _new_game(i))


# 切角描边按钮（方舟风）
func _line_button(content: String, x: float, y: float, w: float, h: float = 44.0) -> Button:
	var b := Button.new()
	b.text = content
	b.position = Vector2(x, y)
	b.size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.z_index = 6
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.72))
	StoryDB.apply_serif(b)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.07, 0.09, 0.55)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(GOLD, 0.42)
	b.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(GOLD, 0.14)
	hover.border_color = Color(GOLD_HI, 0.95)
	b.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(GOLD, 0.24)
	pressed.border_color = Color(GOLD_HI, 1.0)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(b)
	return b


func _ghost_button(content: String, x: float, y: float, w: float, h: float) -> Button:
	return _line_button(content, x, y, w, h)


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
	# 两列排，全部落在屏幕内（原来第 4 个跑到 y=718，屏幕只有 720 高）
	var col := 0
	var row := 0
	for it in items:
		var b := Button.new()
		b.text = str(it["text"])
		b.position = Vector2(40 + col * 200, 606 + row * 38)
		b.size = Vector2(190, 32)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 14)
		var act: Callable = it["action"]
		b.pressed.connect(act)
		UiKit.ghost_button(b, 14)
		add_child(b)
		col += 1
		if col >= 2:
			col = 0
			row += 1

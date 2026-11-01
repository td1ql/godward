extends Control

# ============================================================
# TitleSplash —— 开局展示界面
# ------------------------------------------------------------
# 全屏黑 → 细线展开 → 「逐 神」浮现 → GODWARD 淡入 →
# 一条金色扫描线掠过 → 「点击开始」
# 点击后整体淡出，露出主菜单。
#
# 用法：TitleSplash.show_on(root)
# ============================================================

const GOLD := Color("c9a86a")
const GOLD_HI := Color("e6c98c")
const CREAM := Color("ede0c7")

var _bg: ColorRect
var _rule: ColorRect
var _title: Label
var _en: Label
var _tag: Label
var _hint: Label
var _sweep: ColorRect
var _root: Node
var _done := false


static func show_on(root: Node) -> void:
	var c := new()
	c._root = root
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.z_index = 900
	root.add_child(c)
	c._build()


func _build() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.014, 0.02, 0.027, 1.0)
	_bg.size = Vector2(1280, 720)
	add_child(_bg)

	# 标题左对齐，竖排在左侧 1/3 处
	_title = Label.new()
	_title.text = "逐　神"
	_title.position = Vector2(148, 246)
	_title.size = Vector2(620, 130)
	_title.add_theme_font_size_override("font_size", 96)
	_title.add_theme_color_override("font_color", CREAM)
	_title.modulate.a = 0.0
	StoryDB.apply_serif(_title)
	add_child(_title)

	# 金色横线
	_rule = ColorRect.new()
	_rule.color = GOLD
	_rule.position = Vector2(152, 392)
	_rule.size = Vector2(0, 1)
	add_child(_rule)

	_en = Label.new()
	_en.text = "G O D W A R D"
	_en.position = Vector2(154, 408)
	_en.size = Vector2(600, 40)
	_en.add_theme_font_size_override("font_size", 20)
	_en.add_theme_color_override("font_color", Color(GOLD, 0.85))
	_en.modulate.a = 0.0
	add_child(_en)

	_tag = Label.new()
	_tag.text = "一场把人送上神位的游戏"
	_tag.position = Vector2(154, 452)
	_tag.size = Vector2(600, 34)
	_tag.add_theme_font_size_override("font_size", 16)
	_tag.add_theme_color_override("font_color", Color(0.55, 0.51, 0.44))
	_tag.modulate.a = 0.0
	StoryDB.apply_serif(_tag)
	add_child(_tag)

	# 扫描光带
	_sweep = ColorRect.new()
	_sweep.color = Color(GOLD_HI, 0.0)
	_sweep.size = Vector2(3, 720)
	_sweep.position = Vector2(-10, 0)
	add_child(_sweep)

	# 全屏透明按钮接管点击：Control 的 _gui_input 在某些父节点下收不到事件
	var clicker := Button.new()
	clicker.flat = true
	clicker.focus_mode = Control.FOCUS_NONE
	clicker.set_anchors_preset(Control.PRESET_FULL_RECT)
	clicker.mouse_filter = Control.MOUSE_FILTER_STOP
	clicker.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	clicker.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	clicker.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	clicker.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	clicker.pressed.connect(_close)
	add_child(clicker)

	_hint = Label.new()
	_hint.text = "点击开始"
	_hint.position = Vector2(0, 636)
	_hint.size = Vector2(1280, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(CREAM, 0.0))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StoryDB.apply_serif(_hint)
	add_child(_hint)

	_play()


func _play() -> void:
	var t := create_tween()
	t.tween_property(_title, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_title, "position:y", 236.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_rule, "size:x", 384.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_sweep, "modulate:a", 0.55, 0.3)
	t.parallel().tween_property(_sweep, "position:x", 1290.0, 1.1).set_trans(Tween.TRANS_SINE)

	t.tween_property(_en, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property(_tag, "modulate:a", 1.0, 0.6).set_delay(0.15)
	t.parallel().tween_property(_sweep, "modulate:a", 0.0, 0.4)

	t.tween_property(_hint, "modulate:a", 1.0, 0.6)
	t.tween_property(_hint, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE)
	t.set_loops(0)
	# 呼吸
	var breathe := create_tween()
	breathe.set_loops()
	breathe.tween_interval(1.6)
	breathe.tween_property(_hint, "modulate:a", 0.9, 1.0).set_trans(Tween.TRANS_SINE)
	breathe.tween_property(_hint, "modulate:a", 0.35, 1.0).set_trans(Tween.TRANS_SINE)


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed:
		_close()
	elif event is InputEventKey and event.pressed:
		_close()


func _close() -> void:
	_done = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)


func _unhandled_key_input(event: InputEvent) -> void:
	if not _done and event is InputEventKey and event.pressed:
		_close()

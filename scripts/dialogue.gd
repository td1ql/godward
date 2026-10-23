# ============================================================
# Dialogue —— 多段对话播放器
# ------------------------------------------------------------
# 用法：
#   Dialogue.play(self, DialogueDB.get_lines("prologue"), _on_done)
#
# 点击屏幕任意位置 / 空格 / 回车 → 下一句
# 右下角「跳过」→ 直接结束
# ============================================================

class_name Dialogue
extends Node

var overlay: Control
var speaker_label: Label
var text_label: Label
var hint_label: Label
var lines: Array = []
var index := 0
var on_finish: Callable
var on_skip: Callable

static func play(parent: Node, lines: Array, on_finish: Callable = Callable(), on_skip: Callable = Callable()) -> void:
	if lines.is_empty():
		if on_finish.is_valid():
			on_finish.call()
		return
	var d := Dialogue.new()
	parent.add_child(d)
	d._start(parent, lines, on_finish, on_skip)

func _start(parent: Node, source: Array, finish: Callable, skip_cb: Callable = Callable()) -> void:
	lines = source
	on_finish = finish
	on_skip = skip_cb
	index = 0

	overlay = Modal.open(parent, 0.96)

	var catcher := Button.new()
	catcher.flat = true
	catcher.size = Vector2(1280, 720)
	catcher.position = Vector2.ZERO
	catcher.pressed.connect(_advance)
	overlay.add_child(catcher)

	speaker_label = Label.new()
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_label.position = Vector2(0, 220)
	speaker_label.size = Vector2(1280, 40)
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker_label.add_theme_font_size_override("font_size", 24)
	speaker_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	overlay.add_child(speaker_label)

	text_label = Label.new()
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.position = Vector2(140, 285)
	text_label.size = Vector2(1000, 200)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 22)
	overlay.add_child(text_label)

	hint_label = Label.new()
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.position = Vector2(0, 640)
	hint_label.size = Vector2(1280, 30)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	overlay.add_child(hint_label)

	var skip := Button.new()
	skip.text = "跳过"
	skip.size = Vector2(120, 44)
	skip.position = Vector2(1130, 650)
	skip.add_theme_font_size_override("font_size", 16)
	skip.pressed.connect(_finish.bind(true))
	overlay.add_child(skip)

	_render()

func _unhandled_input(event: InputEvent) -> void:
	if overlay == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_advance()
			get_viewport().set_input_as_handled()

func _render() -> void:
	var line = lines[index]
	var speaker := ""
	var content := ""
	if typeof(line) == TYPE_DICTIONARY:
		speaker = str(line.get("speaker", ""))
		content = str(line.get("text", ""))
	else:
		content = str(line)

	speaker_label.text = speaker
	text_label.text = content
	hint_label.text = "点击继续　(%d / %d)" % [index + 1, lines.size()]

func _advance() -> void:
	index += 1
	if index >= lines.size():
		_finish()
		return
	_render()

func _finish(skipped: bool = false) -> void:
	if overlay:
		overlay.queue_free()
		overlay = null
	var cb: Callable = on_skip if skipped and on_skip.is_valid() else on_finish
	on_finish = Callable()
	on_skip = Callable()
	queue_free()
	if cb.is_valid():
		cb.call()

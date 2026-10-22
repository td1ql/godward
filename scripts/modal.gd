# ============================================================
# Modal —— 全屏弹窗工厂
# ------------------------------------------------------------
# 用法：
#   var overlay := Modal.open(self)                 # 全屏遮罩
#   Modal.title(overlay, "标题")                     # 居中标题
#   Modal.text(overlay, "正文", 260)                 # 居中正文（自动换行）
#   Modal.button(overlay, "确定", 530, 400, 220, 60, _on_ok)
#
# 所有界面共用同一套遮罩/标题/正文/按钮样式，改这里全局生效。
# ============================================================

class_name Modal

# 创建全屏遮罩，返回 overlay 容器（后续元素都 add 到它上面）
static func open(parent: Node, alpha: float = 0.93) -> Control:
	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	parent.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, alpha)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)
	return overlay

# 居中标题
static func title(overlay: Control, content: String, y: float = 150.0, font_size: int = 44) -> Label:
	var lbl := Label.new()
	lbl.text = content
	lbl.position = Vector2(0, y)
	lbl.size = Vector2(1280, 70)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	overlay.add_child(lbl)
	return lbl

# 居中正文（自动换行，适合多行剧情）
static func text(overlay: Control, content: String, y: float, font_size: int = 22, height: float = 100.0) -> Label:
	var lbl := Label.new()
	lbl.text = content
	lbl.position = Vector2(0, y)
	lbl.size = Vector2(1280, height)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", font_size)
	overlay.add_child(lbl)
	return lbl

# 按钮
static func button(overlay: Control, content: String, x: float, y: float, w: float = 240.0, h: float = 60.0, on_press: Callable = Callable()) -> Button:
	var btn := Button.new()
	btn.text = content
	btn.size = Vector2(w, h)
	btn.position = Vector2(x, y)
	btn.add_theme_font_size_override("font_size", 22)
	if on_press.is_valid():
		btn.pressed.connect(on_press)
	overlay.add_child(btn)
	return btn

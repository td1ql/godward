class_name NavMenu
extends RefCounted

# ============================================================
# NavMenu —— 右上角的 ≡ 菜单
# ------------------------------------------------------------
# 用法：
#   NavMenu.attach(hud, [
#       {"text": "牌库", "action": func() -> void: DeckViewer.toggle()},
#       {"text": "返回主菜单", "action": Callable(self, "_on_back")},
#   ])
#
# 所有非战斗界面共用这一套，改这里全局生效。
# ============================================================

const BUTTON_POS := Vector2(1228, 14)
const BUTTON_SIZE := Vector2(40, 40)
const PANEL_W := 260.0
const ROW_H := 52.0


# 在 parent 上挂一个 ≡ 按钮（CanvasLayer / Node2D / Control 都可以）
static func attach(parent: Node, items: Array) -> Button:
	var btn := Button.new()
	btn.text = "≡"
	btn.position = BUTTON_POS
	btn.size = BUTTON_SIZE
	btn.tooltip_text = "菜单"
	btn.pressed.connect(func() -> void: open(parent, items))
	UiKit.ghost_button(btn, 26)
	parent.add_child(btn)
	return btn


# 弹出菜单（点空白处关闭）
static func open(parent: Node, items: Array) -> void:
	var layer := Control.new()
	layer.size = Vector2(1280, 720)
	layer.z_index = 200
	parent.add_child(layer)

	var dim := Button.new()
	dim.flat = true
	dim.size = Vector2(1280, 720)
	dim.focus_mode = Control.FOCUS_NONE
	dim.pressed.connect(layer.queue_free)
	layer.add_child(dim)

	var h: float = 24.0 + items.size() * ROW_H
	var panel := Panel.new()
	panel.position = Vector2(1280.0 - PANEL_W - 20.0, 64)
	panel.size = Vector2(PANEL_W, h)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11, 0.97)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.55, 0.44, 0.24, 0.55)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 8
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(12, 12)
	vbox.size = Vector2(PANEL_W - 24, h - 24)
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	for it in items:
		var b := Button.new()
		b.text = str(it.get("text", ""))
		b.custom_minimum_size = Vector2(PANEL_W - 24, ROW_H - 6)
		b.focus_mode = Control.FOCUS_NONE
		UiKit.ghost_button(b, 18)
		var act: Callable = it.get("action", Callable())
		b.pressed.connect(func() -> void:
			layer.queue_free()
			if act.is_valid():
				act.call()
		)
		vbox.add_child(b)

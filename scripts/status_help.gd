class_name StatusHelp
extends RefCounted

# ============================================================
# StatusHelp —— 「状态一览」弹窗（两栏）
# 左：减益　右：增益
# ============================================================

const COL_W := 580.0
const ROW_H := 26.0


static func open(parent: Node) -> void:
	var overlay := Modal.open(parent, 0.95)
	Modal.title(overlay, "状态", 40, 34)

	var bad: Array = []
	var good: Array = []
	for key in StatusDB.STATUS.keys():
		var rule: Dictionary = StatusDB.STATUS[key]
		var item := {"name": str(rule["name"]), "desc": str(rule.get("desc", ""))}
		if bool(rule.get("good", false)):
			good.append(item)
		else:
			bad.append(item)

	_column(overlay, 40.0, "—— 减益 ——", bad, Color(0.86, 0.55, 0.52))
	_column(overlay, 40.0 + COL_W + 40.0, "—— 增益 ——", good, Color(0.62, 0.82, 0.62))

	Modal.button(overlay, "返回", 520, 640, 240, 50, overlay.queue_free)


static func _column(overlay: Control, x: float, head: String, items: Array, color: Color) -> void:
	var title := Label.new()
	title.text = head
	title.position = Vector2(x, 100)
	title.size = Vector2(COL_W, 30)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", color)
	StoryDB.apply_serif(title)
	overlay.add_child(title)

	var y := 100.0 + ROW_H + 8.0
	for it in items:
		var name_lbl := Label.new()
		name_lbl.text = str(it["name"])
		name_lbl.position = Vector2(x, y)
		name_lbl.size = Vector2(110, ROW_H)
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
		StoryDB.apply_serif(name_lbl)
		overlay.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = str(it["desc"])
		desc_lbl.position = Vector2(x + 110, y)
		desc_lbl.size = Vector2(COL_W - 110, ROW_H)
		desc_lbl.add_theme_font_size_override("font_size", 16)
		desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.69, 0.60))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		StoryDB.apply_serif(desc_lbl)
		overlay.add_child(desc_lbl)

		y += ROW_H

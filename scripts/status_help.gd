class_name StatusHelp
extends RefCounted

# ============================================================
# StatusHelp —— 「状态一览」弹窗
# 数据来自 StatusDB，UI 来自 Modal。
# ============================================================

static func open(parent: Node) -> void:
	var overlay := Modal.open(parent, 0.95)
	Modal.title(overlay, "状态", 50, 34)

	var bad := ""
	var good := ""
	for key in StatusDB.STATUS.keys():
		var rule: Dictionary = StatusDB.STATUS[key]
		var line := "%s　%s\n" % [str(rule["name"]), str(rule.get("desc", ""))]
		if bool(rule.get("good", false)):
			good += line
		else:
			bad += line

	var body := ""
	if bad != "":
		body += "—— 减益 ——\n" + bad + "\n"
	if good != "":
		body += "—— 增益 ——\n" + good

	var lbl := Label.new()
	lbl.text = body
	lbl.position = Vector2(150, 120)
	lbl.size = Vector2(980, 470)
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.74))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay.add_child(lbl)

	Modal.button(overlay, "返回", 520, 620, 240, 56, overlay.queue_free)

class_name MetaPick
extends RefCounted

# ============================================================
# MetaPick —— 通关第三幕后的「自由配置」面板
# 选 1 个职业 + 3 个流派，确认后重建本轮。
# ============================================================

const COL_W := 258.0
const ROW_H := 56.0
const COLS := 4


static func open(parent: Node) -> void:
	var overlay := Modal.open(parent, 0.96)
	Modal.title(overlay, "自由配置", 34, 32)

	# GDScript 的 lambda 按值捕获局部变量，用数组包一层才能改到
	var picked_v: Array = [GameState.vocation]
	var picked_s: Array = GameState.streams.duplicate()

	var voc_head := Label.new()
	voc_head.text = "职业"
	voc_head.position = Vector2(60, 96)
	voc_head.size = Vector2(400, 28)
	voc_head.add_theme_font_size_override("font_size", 20)
	voc_head.add_theme_color_override("font_color", Color(0.85, 0.78, 0.60))
	StoryDB.apply_serif(voc_head)
	overlay.add_child(voc_head)

	var voc_buttons: Array = []
	var names: Array = TraitDB.VOCATIONS.keys()
	names.sort()
	for i in range(names.size()):
		var id := str(names[i])
		var col := i % COLS
		var row := i / COLS
		var b := Button.new()
		b.text = id
		b.position = Vector2(60 + col * COL_W, 130 + row * ROW_H)
		b.size = Vector2(COL_W - 12, ROW_H - 8)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(func() -> void:
			picked_v[0] = id
			for vb in voc_buttons:
				var bb: Button = vb
				bb.modulate = Color(1, 1, 1, 1) if str(bb.text) == str(picked_v[0]) else Color(0.62, 0.62, 0.66, 1)
		)
		UiKit.ghost_button(b, 16)
		overlay.add_child(b)
		voc_buttons.append(b)
		if id == str(picked_v[0]):
			b.modulate = Color(1, 1, 1, 1)
		else:
			b.modulate = Color(0.62, 0.62, 0.66, 1)

	var st_head := Label.new()
	st_head.text = "流派（选 3 个）"
	st_head.position = Vector2(60, 420)
	st_head.size = Vector2(400, 28)
	st_head.add_theme_font_size_override("font_size", 20)
	st_head.add_theme_color_override("font_color", Color(0.85, 0.78, 0.60))
	StoryDB.apply_serif(st_head)
	overlay.add_child(st_head)

	var st_buttons: Array = []
	var streams: Array = CardDB.STREAMS.duplicate()
	for i in range(streams.size()):
		var s := str(streams[i])
		var b := Button.new()
		b.text = s
		b.position = Vector2(60 + i * 148.0, 458)
		b.size = Vector2(136, 50)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(func() -> void:
			if picked_s.has(s):
				picked_s.erase(s)
			elif picked_s.size() < 3:
				picked_s.append(s)
			for sb in st_buttons:
				var bb: Button = sb
				bb.modulate = Color(1, 1, 1, 1) if picked_s.has(str(bb.text)) else Color(0.55, 0.55, 0.60, 1)
		)
		UiKit.ghost_button(b, 20)
		overlay.add_child(b)
		st_buttons.append(b)
		b.modulate = Color(1, 1, 1, 1) if picked_s.has(s) else Color(0.55, 0.55, 0.60, 1)

	var hint := Label.new()
	hint.text = "确认后会重新生成本轮（职业、词条、牌组、名册）"
	hint.position = Vector2(60, 530)
	hint.size = Vector2(900, 26)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.66, 0.63, 0.56))
	StoryDB.apply_serif(hint)
	overlay.add_child(hint)

	Modal.button(overlay, "确定", 380, 580, 200, 54, func() -> void:
		if picked_s.size() != 3:
			Toast.show_text("流派要选满 3 个。", 2.0)
			return
		GameState.set_vocation(str(picked_v[0]))
		GameState.set_streams(picked_s)
		overlay.queue_free()
		parent.get_tree().reload_current_scene()
	)
	Modal.button(overlay, "取消", 620, 580, 200, 54, overlay.queue_free)

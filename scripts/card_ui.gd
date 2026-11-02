class_name CardUI
extends RefCounted

static func border_of(d: Dictionary) -> Color:
	if d.get("divine", false):
		return Color(0.28, 0.34, 0.52)
	if d.has("self_status"):
		return Color(0.44, 0.34, 0.14)
	if d.has("status"):
		return Color(0.34, 0.20, 0.44)
	if d["damage"] > 0:
		return Color(0.48, 0.18, 0.15)
	return Color(0.18, 0.30, 0.22)

static func style(bg: Color, border: Color, width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(8)
	return sb


# 一张牌属于哪个流派（拿第一个；通用的牌返回空）
# 流派 -> 底图文件名（中文流派名不直接做文件名，避免路径问题）
const STREAM_ART := {
	"毒": "poison",
	"力": "strength",
	"守": "guard",
	"抽": "draw",
	"斩": "slash",
	"血": "blood",
	"技": "skill",
	"愈": "heal",
}

static func stream_of(id: String) -> String:
	var ss: Array = CardDB.streams_of(id)
	if ss.is_empty():
		return ""
	return str(STREAM_ART.get(str(ss[0]), ""))

static func make_button(id: String, font_size: int = 15) -> Button:
	var d: Dictionary = CardDB.get_card(id)
	var parts := CardDB.card_text(id).split("\n")
	var cname := str(parts[0]) if parts.size() > 0 else id
	var ctag := str(parts[1]) if parts.size() > 1 else ""
	var cbody := str(parts[2]) if parts.size() > 2 else ""

	var bc := border_of(d)
	var paper := Color(0.93, 0.89, 0.79)
	var ink := Color(0.14, 0.11, 0.08)

	var btn := Button.new()
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", style(paper, bc, 2))
	btn.add_theme_stylebox_override("hover", style(paper.lightened(0.05), Color(0.91, 0.75, 0.35), 3))
	btn.add_theme_stylebox_override("pressed", style(paper.darkened(0.08), Color(0.85, 0.66, 0.25), 3))
	btn.add_theme_stylebox_override("disabled", style(Color(0.60, 0.57, 0.50), Color(0.32, 0.30, 0.26), 2))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# ---- 卡面插画：卡片上半部分（每张卡自己的图，没有就退回流派图）----
	const ART_H := 84
	var art_path := "res://assets/art/cardart3b/%s.png" % id
	if not ResourceLoader.exists(art_path):
		art_path = "res://assets/art/card/%s.webp" % stream_of(id)
	if ResourceLoader.exists(art_path):
		# 深色底衬：插画四周不留白
		var back := ColorRect.new()
		back.color = Color(0.10, 0.12, 0.15, 1.0)
		back.anchor_right = 1.0
		back.offset_left = 2
		back.offset_right = -2
		back.offset_top = 2
		back.offset_bottom = ART_H
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(back)

		var art := TextureRect.new()
		art.texture = load(art_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.anchor_right = 1.0
		art.offset_left = 2
		art.offset_right = -2
		art.offset_top = 2
		art.offset_bottom = ART_H
		art.modulate = Color(0.82, 0.84, 0.88, 1.0)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(art)

		# 顶部轻压暗（让插画上沿不冲）
		var shade_t := ColorRect.new()
		shade_t.color = Color(0.04, 0.05, 0.07, 0.38)
		shade_t.anchor_right = 1.0
		shade_t.offset_left = 2
		shade_t.offset_right = -2
		shade_t.offset_top = 2
		shade_t.offset_bottom = 10
		shade_t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(shade_t)

		# 下沿渐变淡出：插画底边融进卡底色，不再是硬边
		var grad := Gradient.new()
		grad.set_color(0, Color(0.10, 0.12, 0.15, 0.0))
		grad.set_color(1, Color(0.10, 0.12, 0.15, 1.0))
		grad.set_offset(0, 0.0)
		grad.set_offset(1, 1.0)
		var gtex := GradientTexture2D.new()
		gtex.gradient = grad
		gtex.fill_from = Vector2(0, 0)
		gtex.fill_to = Vector2(0, 1)
		gtex.width = 8
		gtex.height = 64
		var fade := TextureRect.new()
		fade.texture = gtex
		fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fade.stretch_mode = TextureRect.STRETCH_SCALE
		fade.anchor_right = 1.0
		fade.offset_left = 2
		fade.offset_right = -2
		fade.offset_top = ART_H - 26
		fade.offset_bottom = ART_H
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(fade)

		# 窗口边框：细金线一圈
		var frame := Panel.new()
		frame.anchor_right = 1.0
		frame.offset_left = 1
		frame.offset_right = -1
		frame.offset_top = 1
		frame.offset_bottom = ART_H + 1
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = Color(0, 0, 0, 0)
		fsb.border_color = Color(0.62, 0.52, 0.34, 0.75)
		fsb.set_border_width_all(1)
		frame.add_theme_stylebox_override("panel", fsb)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(frame)

		# 插画下沿一条金线，和下面信息区分开
		var rule := ColorRect.new()
		rule.color = Color(0.79, 0.66, 0.42, 0.55)
		rule.anchor_right = 1.0
		rule.offset_left = 2
		rule.offset_right = -2
		rule.offset_top = ART_H
		rule.offset_bottom = ART_H + 1
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(rule)

	var bs: int = font_size + 11
	var badge := Panel.new()
	badge.position = Vector2(4, 4)
	badge.size = Vector2(bs, bs)
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = bc.darkened(0.18)
	bstyle.set_corner_radius_all(bs / 2)
	badge.add_theme_stylebox_override("panel", bstyle)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(badge)

	var cost_lbl := Label.new()
	cost_lbl.text = str(int(d.get("cost", 0)))
	cost_lbl.size = Vector2(bs, bs)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", font_size)
	cost_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StoryDB.apply_serif(cost_lbl)
	badge.add_child(cost_lbl)

	var name_lbl := Label.new()
	name_lbl.text = cname
	name_lbl.anchor_left = 0.0
	name_lbl.anchor_right = 1.0
	name_lbl.offset_left = bs + 9
	name_lbl.offset_right = -5
	name_lbl.offset_top = 88
	name_lbl.offset_bottom = 110
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", font_size)
	name_lbl.add_theme_color_override("font_color", ink)
	name_lbl.add_theme_constant_override("outline_size", 1)
	name_lbl.add_theme_color_override("font_outline_color", ink)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StoryDB.apply_serif(name_lbl)
	btn.add_child(name_lbl)

	var nrule := ColorRect.new()
	nrule.color = Color(0.72, 0.59, 0.36, 0.60)
	nrule.anchor_right = 1.0
	nrule.offset_left = 30
	nrule.offset_right = -30
	nrule.offset_top = 109
	nrule.offset_bottom = 110
	nrule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(nrule)

	var need: int = int(d.get("consume", 0))
	if need > 0:
		name_lbl.offset_right = -(bs + 6)

		var cbadge := Panel.new()
		cbadge.anchor_left = 1.0
		cbadge.anchor_right = 1.0
		cbadge.offset_left = -(bs - 4)
		cbadge.offset_right = -4
		cbadge.offset_top = 6
		cbadge.offset_bottom = bs + 2
		var cbs := StyleBoxFlat.new()
		cbs.bg_color = Color(0.34, 0.12, 0.10)
		cbs.set_corner_radius_all((bs - 4) / 2)
		cbadge.add_theme_stylebox_override("panel", cbs)
		cbadge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(cbadge)

		var clbl := Label.new()
		clbl.text = str(need)
		clbl.size = Vector2(bs - 4, bs - 4)
		clbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		clbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		clbl.add_theme_font_size_override("font_size", max(10, font_size - 3))
		clbl.add_theme_color_override("font_color", Color(0.98, 0.90, 0.86))
		clbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		StoryDB.apply_serif(clbl)
		cbadge.add_child(clbl)


	var tips: Array[String] = []
	for key in d.get("status", {}):
		var sd: Dictionary = StatusDB.STATUS.get(key, {})
		tips.append("【%s】%s" % [key, str(sd.get("desc", ""))])
	for key in d.get("self_status", {}):
		var sd2: Dictionary = StatusDB.STATUS.get(key, {})
		tips.append("【%s】%s" % [key, str(sd2.get("desc", ""))])
	if int(d.get("consume", 0)) > 0:
		tips.append("需要消耗 %d 张手牌" % int(d["consume"]))
	if not tips.is_empty():
		btn.tooltip_text = "\n".join(tips)

	var tag_lbl := Label.new()
	tag_lbl.text = ctag
	tag_lbl.anchor_right = 1.0
	tag_lbl.offset_left = 6
	tag_lbl.offset_right = -5
	tag_lbl.offset_top = 110
	tag_lbl.offset_bottom = 124
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_size_override("font_size", max(10, font_size - 4))
	tag_lbl.add_theme_color_override("font_color", Color(0.42, 0.36, 0.27))
	tag_lbl.add_theme_constant_override("outline_size", 1)
	tag_lbl.add_theme_color_override("font_outline_color", Color(0.42, 0.36, 0.27))
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StoryDB.apply_serif(tag_lbl)
	btn.add_child(tag_lbl)

	var body_lbl := Label.new()
	body_lbl.text = cbody
	body_lbl.anchor_right = 1.0
	body_lbl.anchor_bottom = 1.0
	body_lbl.offset_left = 6
	body_lbl.offset_right = -6
	body_lbl.offset_top = 124
	body_lbl.offset_bottom = -4
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# 字多的时候自动缩字号：每多 6 个字缩 1px，最小 9px
	var body_fs: int = max(11, font_size - 2)
	var extra: int = max(0, cbody.length() - 16)
	body_fs = max(9, body_fs - int(extra / 6))
	body_lbl.add_theme_font_size_override("font_size", body_fs)
	body_lbl.add_theme_color_override("font_color", ink)
	body_lbl.clip_text = true
	body_lbl.add_theme_constant_override("outline_size", 1)
	body_lbl.add_theme_color_override("font_outline_color", ink)
	body_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StoryDB.apply_serif(body_lbl)
	btn.add_child(body_lbl)

	return btn

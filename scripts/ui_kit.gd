class_name UiKit
extends RefCounted

# ============================================================
# UiKit —— 统一的「墨金按钮」样式
# ------------------------------------------------------------
# 全游戏只有这一处定义按钮长什么样。
# 要改配色/字号/边框，改这里，所有界面一起变。
# ============================================================

const INK_TEXT := Color(0.93, 0.88, 0.74)
const INK_TEXT_HOVER := Color(1.0, 0.95, 0.78)
const INK_BORDER := Color(0.55, 0.44, 0.24, 0.45)
const INK_BORDER_HOVER := Color(0.85, 0.68, 0.34, 0.95)
const INK_BG_DARK := Color(0.05, 0.06, 0.09, 0.72)
const INK_BG := Color(0.13, 0.14, 0.18, 0.92)
const INK_BG_HOVER := Color(0.55, 0.42, 0.16, 0.32)

const PARCHMENT_BG := Color(0.94, 0.90, 0.80, 0.92)
const PARCHMENT_BORDER := Color(0.48, 0.37, 0.18, 0.55)
const PARCHMENT_SHADOW := Color(0.10, 0.07, 0.03, 0.35)


static func style(b: Button, font_size: int = 20, dark: bool = false) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", INK_TEXT)
	b.add_theme_color_override("font_hover_color", INK_TEXT_HOVER)
	StoryDB.apply_serif(b)

	var nb := StyleBoxFlat.new()
	nb.bg_color = INK_BG_DARK if dark else INK_BG
	nb.border_width_left = 1
	nb.border_width_right = 1
	nb.border_width_top = 1
	nb.border_width_bottom = 1
	nb.border_color = INK_BORDER
	b.add_theme_stylebox_override("normal", nb)

	var hb: StyleBoxFlat = nb.duplicate()
	hb.bg_color = INK_BG_HOVER
	hb.border_color = INK_BORDER_HOVER
	b.add_theme_stylebox_override("hover", hb)
	b.add_theme_stylebox_override("pressed", hb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


# 透明底、只有细金边（战斗界面顶部按钮）
static func ghost_button(b: Button, font_size: int = 20) -> void:
	style(b, font_size, true)


# 实底墨色按钮（地图/商店/事件）
static func ink_button(content: String, min_height: int = 48, font_size: int = 20) -> Button:
	var b := Button.new()
	b.text = content
	b.custom_minimum_size = Vector2(0, min_height)
	style(b, font_size, false)
	return b


# 羊皮纸底衬（地图左上角信息板）
static func parchment_style(radius: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PARCHMENT_BG
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = PARCHMENT_BORDER
	s.set_corner_radius_all(radius)
	s.shadow_color = PARCHMENT_SHADOW
	s.shadow_size = 6
	return s

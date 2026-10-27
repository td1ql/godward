class_name UiKit
extends RefCounted

# ============================================================
# UiKit —— 统一的「墨金按钮」样式
# ------------------------------------------------------------
# 全游戏只有这一处定义按钮长什么样。
# 要改配色/字号/边框，改这里，所有界面一起变。
# ============================================================

# ===== 美术色卡（docs/ART_STYLE.md）=====
# 双色世界：深夜蓝黑 + 羊皮纸暖白，金线只用一根细的。
const NIGHT := Color("1d3143")
const NIGHT_DEEP := Color("141e28")
const INK_BLACK := Color("0b0f14")
const PAPER := Color("f9ecd8")
const PAPER_HI := Color("fbf3e1")
const PAPER_SHADE := Color("eaddc4")
const PAPER_DIM := Color("a49681")
const GOLD := Color("c9a86a")
const GOLD_HI := Color("e0c48a")
const MOON := Color("faefd1")
const BLOOD := Color("7a2e2a")

const INK_TEXT := Color("e9dfc6")
const INK_TEXT_HOVER := Color("fbf3e1")
const INK_BORDER := Color("c9a86a")
const INK_BORDER_HOVER := Color("e0c48a")
const INK_BG_DARK := Color(0.043, 0.059, 0.078, 0.82)
const INK_BG := Color(0.078, 0.118, 0.161, 0.94)
const INK_BG_HOVER := Color(0.788, 0.659, 0.416, 0.14)

const PARCHMENT_BG := Color(0.976, 0.925, 0.847, 0.96)
const PARCHMENT_BORDER := Color(0.788, 0.659, 0.416, 0.62)
const PARCHMENT_SHADOW := Color(0.043, 0.059, 0.078, 0.40)


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
	nb.border_color = Color(INK_BORDER, 0.42)
	b.add_theme_stylebox_override("normal", nb)

	var hb: StyleBoxFlat = nb.duplicate()
	hb.bg_color = INK_BG_HOVER
	hb.border_color = Color(INK_BORDER_HOVER, 0.95)
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

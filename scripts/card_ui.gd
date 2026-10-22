class_name CardUI
extends RefCounted

static func color_of(d: Dictionary) -> Color:
	if d.get("divine", false):
		return Color(0.55, 0.5, 0.3)
	if d.has("self_status"):
		return Color(0.55, 0.45, 0.2)
	if d.has("status"):
		return Color(0.45, 0.32, 0.55)
	if d["damage"] > 0:
		return Color(0.5, 0.25, 0.25)
	return Color(0.24, 0.4, 0.34)

static func style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

static func make_button(id: String, font_size: int = 15) -> Button:
	var d: Dictionary = CardDB.get_card(id)
	var btn := Button.new()
	btn.text = CardDB.card_text(id)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.55))
	var bg := color_of(d)
	btn.add_theme_stylebox_override("normal", style(bg, bg.lightened(0.35)))
	btn.add_theme_stylebox_override("hover", style(bg.lightened(0.12), Color.WHITE))
	btn.add_theme_stylebox_override("pressed", style(bg.darkened(0.2), Color.WHITE))
	btn.add_theme_stylebox_override("disabled", style(bg.darkened(0.5), bg.darkened(0.3)))
	return btn

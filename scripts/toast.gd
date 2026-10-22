extends Node

var _layer: CanvasLayer

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)

func show_text(text: String, duration: float = 2.8) -> void:
	var panel := Panel.new()
	panel.position = Vector2(340, 250)
	panel.size = Vector2(600, 120)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	sb.border_color = Color(0.85, 0.75, 0.35)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(panel)

	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(12, 8)
	lbl.size = Vector2(576, 104)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 17)
	panel.add_child(lbl)

	var tw := panel.create_tween()
	tw.tween_interval(duration)
	tw.tween_property(panel, "modulate:a", 0.0, 0.5)
	tw.finished.connect(panel.queue_free)

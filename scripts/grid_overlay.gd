extends Control

# 方舟风格的背景网格

var step := 96.0
var line := Color(0.79, 0.66, 0.42, 0.06)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -1

func _draw() -> void:
	var w := size.x
	var h := size.y
	var x := 0.0
	while x < w:
		draw_line(Vector2(x, 0), Vector2(x, h), line, 1.0)
		x += step
	var y := 0.0
	while y < h:
		draw_line(Vector2(0, y), Vector2(w, y), line, 1.0)
		y += step

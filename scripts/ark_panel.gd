extends Panel

# ============================================================
# ArkPanel —— 明日方舟风格的切角面板
# ------------------------------------------------------------
#   var p := ArkPanel.new()
#   p.size = Vector2(310, 200)
#   p.cut = 18.0          # 切角大小
#   p.filled = true       # false = 只有线框
#
# 特点：右下角斜切一刀，左上角一个小三角，
#       1px 金线，深墨底，没有圆角。
# ============================================================

const GOLD := Color("c9a86a")
const INK := Color(0.043, 0.059, 0.078, 0.90)

var cut := 18.0
var filled := true
var alpha := 0.90
var accent := true          # 左上角的小三角


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var c := cut

	# 切角外形：左上 → 右上 → 右下（切）→ 左下
	var pts := PackedVector2Array([
		Vector2(0, 0),
		Vector2(w, 0),
		Vector2(w, h - c),
		Vector2(w - c, h),
		Vector2(0, h),
	])

	if filled:
		draw_colored_polygon(pts, Color(INK.r, INK.g, INK.b, alpha))

	# 外框
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, Color(GOLD, 0.70), 1.0, true)

	# 切角那一道斜线加亮
	draw_line(Vector2(w, h - c), Vector2(w - c, h), Color(GOLD, 0.95), 1.4, true)

	# 左上小三角
	if accent:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, 0), Vector2(14, 0), Vector2(0, 14),
		]), Color(GOLD, 0.85))

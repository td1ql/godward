class_name ArtFrame
extends Control

# ============================================================
# ArtFrame —— 立绘用的金线边框
# ------------------------------------------------------------
#   var f := ArtFrame.new()
#   f.frame_rect = Rect2(96, 96, 340, 470)
#   f.add_child(...) 或直接 add_child 到界面
#
# 长这样：
#   外圈 1px 金线（40% 透明）
#   内圈 1px 金线（22% 透明），距外圈 6px
#   四角一小段藤蔓弧线（参考主菜单那张图）
# ============================================================

const GOLD := Color("c9a86a")

var frame_rect := Rect2(0, 0, 340, 470)
var outer_alpha := 0.42
var inner_alpha := 0.22
var corner := 26.0        # 角饰半径
var inset := 6.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1


func _draw() -> void:
	var r := frame_rect

	# 外圈
	draw_rect(r, Color(GOLD, outer_alpha), false, 1.0)
	# 内圈
	var ri := r.grow(-inset)
	draw_rect(ri, Color(GOLD, inner_alpha), false, 1.0)

	# 四角藤蔓：一小段弧 + 一根短须
	var c := Color(GOLD, 0.75)
	for k in [[0, 0], [1, 0], [0, 1], [1, 1]]:
		var cx: float = r.position.x + (corner if k[0] == 0 else r.size.x - corner)
		var cy: float = r.position.y + (corner if k[1] == 0 else r.size.y - corner)
		var center := Vector2(cx, cy)
		# 弧：从角向两边张开
		var start := 0.0
		if k[0] == 0 and k[1] == 0:
			start = PI * 0.0
		elif k[0] == 1 and k[1] == 0:
			start = PI * 0.5
		elif k[0] == 0 and k[1] == 1:
			start = -PI * 0.5
		else:
			start = PI
		draw_arc(center, corner, start, start + PI * 0.5, 16, c, 1.0, true)
		# 短须：从弧中点伸出一小段
		var mid := start + PI * 0.25
		var p1 := center + Vector2(cos(mid), sin(mid)) * corner
		var p2 := center + Vector2(cos(mid), sin(mid)) * (corner + 10.0)
		draw_line(p1, p2, Color(GOLD, 0.5), 1.0, true)


# 便捷构造
static func make(rect: Rect2, a_outer: float = 0.42, a_inner: float = 0.22) -> ArtFrame:
	var f := ArtFrame.new()
	f.frame_rect = rect
	f.outer_alpha = a_outer
	f.inner_alpha = a_inner
	f.size = Vector2(1280, 720)
	return f

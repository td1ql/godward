extends Button

# ============================================================
# MapNode —— 明日方舟风格的扁平地图节点
# ------------------------------------------------------------
# 图标全部用 _draw() 画，不依赖任何图片：
#   战斗  → 交叉双刀      精英 → 交叉双刀 + 尖角
#   首领  → 王冠          事件 → 菱形
#   商店  → 天平          休息 → 火堆
#   神    → 眼睛          财富 → 孔币
#   英雄  → 面具          空壳 → 螺旋
#   教皇  → 权杖          遗骸 → 断环
#   神国  → 光环          蛇   → 波线
#   世界树→ 树形          起点 → 火星
# ============================================================

const SIZE := 66.0
const GOLD := Color("c9a86a")
const GOLD_HI := Color("e6c98c")
const DIM := Color(0.55, 0.50, 0.42, 0.75)
const FAINT := Color(0.42, 0.39, 0.33, 0.42)
const INK := Color(0.043, 0.059, 0.078, 0.95)

var kind := "battle"
var state := "locked"
var _pulse := 0.0


func setup(k: String, _tex = null, st: String = "locked") -> void:
	kind = k
	state = st
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP if st == "walkable" else Control.MOUSE_FILTER_IGNORE

	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())

	queue_redraw()


func _process(delta: float) -> void:
	if state == "walkable" or state == "current":
		_pulse += delta
		queue_redraw()


func _draw() -> void:
	var c := Vector2(SIZE / 2.0, SIZE / 2.0)
	var r := SIZE / 2.0 - 4.0

	var ring := GOLD
	var glow := 0.0
	match state:
		"current":
			ring = GOLD_HI
			glow = 0.50 + 0.15 * sin(_pulse * 2.4)
		"walkable":
			ring = GOLD
			glow = 0.20 + 0.10 * sin(_pulse * 2.0)
		"visited":
			ring = DIM
		_:
			ring = FAINT

	if glow > 0.01:
		for i in range(3):
			var rr := r + 4.0 + i * 5.0
			draw_arc(c, rr, 0, TAU, 32, Color(GOLD, glow * (0.20 - i * 0.05)), 2.0, true)

	var is_big := kind in ["boss", "serpent", "tree", "pope", "god", "divine_elite"]
	if is_big:
		_poly(c, r, 6, INK, ring)
	elif kind == "elite":
		_poly(c, r, 4, INK, ring)
	# 普通节点不画外圈：只留图标，直接落在底图上

	var ic := Color(ring, 0.92 if state != "locked" else 0.45)
	var sym_r := r * 0.62
	if is_big or kind == "elite":
		sym_r = r * 0.46
	_symbol(c, sym_r, ic)


func _poly(c: Vector2, r: float, n: int, fill: Color, line: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := -PI / 2.0 + i * TAU / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, fill)
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, line, 1.6, true)


func _symbol(c: Vector2, s: float, col: Color) -> void:
	var w := 1.8
	match kind:
		"battle", "elite":
			draw_line(c + Vector2(-s, -s), c + Vector2(s * 0.7, s), col, w, true)
			draw_line(c + Vector2(s, -s), c + Vector2(-s * 0.7, s), col, w, true)
			draw_line(c + Vector2(-s * 0.78, -s * 0.42), c + Vector2(-s * 0.28, -s), col, w * 0.8, true)
			draw_line(c + Vector2(s * 0.78, -s * 0.42), c + Vector2(s * 0.28, -s), col, w * 0.8, true)
			if kind == "elite":
				draw_line(c + Vector2(-s * 0.5, s * 0.65), c + Vector2(0, s * 0.98), col, w, true)
				draw_line(c + Vector2(0, s * 0.98), c + Vector2(s * 0.5, s * 0.65), col, w, true)

		"boss":
			var pts := PackedVector2Array([
				c + Vector2(-s, s * 0.55), c + Vector2(-s, -s * 0.30),
				c + Vector2(-s * 0.45, s * 0.12), c + Vector2(0, -s * 0.78),
				c + Vector2(s * 0.45, s * 0.12), c + Vector2(s, -s * 0.30),
				c + Vector2(s, s * 0.55),
			])
			draw_polyline(pts, col, w, true)
			draw_line(c + Vector2(-s, s * 0.55), c + Vector2(s, s * 0.55), col, w, true)

		"pope":
			draw_line(c + Vector2(-s * 0.55, s), c + Vector2(s * 0.30, -s * 0.70), col, w, true)
			draw_arc(c + Vector2(s * 0.42, -s * 0.82), s * 0.34, 0, TAU, 16, col, w, true)

		"event":
			var pts2 := PackedVector2Array([
				c + Vector2(0, -s), c + Vector2(s, 0),
				c + Vector2(0, s), c + Vector2(-s, 0),
			])
			var lp := pts2.duplicate()
			lp.append(pts2[0])
			draw_polyline(lp, col, w, true)
			draw_circle(c, s * 0.17, col)

		"shop":
			draw_line(c + Vector2(0, -s * 0.85), c + Vector2(0, s * 0.72), col, w, true)
			draw_line(c + Vector2(-s * 0.85, -s * 0.50), c + Vector2(s * 0.85, -s * 0.50), col, w, true)
			draw_line(c + Vector2(-s * 0.85, -s * 0.50), c + Vector2(-s * 0.58, -s * 0.05), col, w * 0.8, true)
			draw_line(c + Vector2(-s * 0.85, -s * 0.50), c + Vector2(-s * 1.05, -s * 0.05), col, w * 0.8, true)
			draw_line(c + Vector2(s * 0.85, -s * 0.50), c + Vector2(s * 0.58, -s * 0.05), col, w * 0.8, true)
			draw_line(c + Vector2(s * 0.85, -s * 0.50), c + Vector2(s * 1.05, -s * 0.05), col, w * 0.8, true)
			draw_line(c + Vector2(-s * 0.45, s * 0.75), c + Vector2(s * 0.45, s * 0.75), col, w, true)

		"rest":
			draw_line(c + Vector2(-s * 0.90, s * 0.75), c + Vector2(s * 0.90, s * 0.75), col, w, true)
			draw_line(c + Vector2(-s * 0.55, s * 0.55), c + Vector2(0, -s * 0.85), col, w, true)
			draw_line(c + Vector2(s * 0.55, s * 0.55), c + Vector2(0, -s * 0.85), col, w, true)
			draw_line(c + Vector2(-s * 0.33, s * 0.10), c + Vector2(s * 0.33, s * 0.10), col, w * 0.8, true)

		"god":
			draw_arc(c + Vector2(0, s * 1.18), s * 1.28, -PI * 0.72, -PI * 0.28, 20, col, w, true)
			draw_arc(c + Vector2(0, -s * 1.18), s * 1.28, PI * 0.28, PI * 0.72, 20, col, w, true)
			draw_circle(c, s * 0.34, col)

		"wealth":
			draw_arc(c, s * 0.85, 0, TAU, 24, col, w, true)
			draw_rect(Rect2(c - Vector2(s * 0.21, s * 0.21), Vector2(s * 0.42, s * 0.42)), col, false, w)

		"npc":
			draw_arc(c, s * 0.82, PI * 0.15, PI * 0.85, 18, col, w, true)
			draw_arc(c, s * 0.82, PI * 1.15, PI * 1.85, 18, col, w, true)
			draw_circle(c + Vector2(-s * 0.30, -s * 0.14), s * 0.11, col)
			draw_circle(c + Vector2(s * 0.30, -s * 0.14), s * 0.11, col)

		"shell":
			var prev := c + Vector2(s * 0.90, 0)
			for i in range(1, 26):
				var t := float(i) / 25.0
				var ang := t * TAU * 1.5
				var rr := s * 0.90 * (1.0 - t * 0.85)
				var np := c + Vector2(cos(ang), sin(ang)) * rr
				draw_line(prev, np, col, w * 0.85, true)
				prev = np

		"remnant":
			draw_arc(c, s * 0.80, -PI * 0.85, PI * 0.55, 20, col, w, true)
			draw_arc(c, s * 0.80, PI * 0.65, PI * 1.15, 12, Color(col, 0.5), w, true)

		"divine":
			draw_arc(c, s * 0.72, 0, TAU, 24, col, w, true)
			for i in range(6):
				var a := i * TAU / 6.0
				draw_line(c + Vector2(cos(a), sin(a)) * s * 0.90,
						  c + Vector2(cos(a), sin(a)) * s * 1.18, col, w * 0.8, true)

		"divine_elite":
			draw_arc(c, s * 0.85, 0, TAU, 24, col, w, true)
			draw_arc(c, s * 0.45, 0, TAU, 20, col, w, true)

		"serpent":
			var p0 := c + Vector2(-s, s * 0.40)
			for i in range(1, 13):
				var t2 := float(i) / 12.0
				var p1 := c + Vector2(-s + t2 * s * 2.0, sin(t2 * TAU * 1.3) * s * 0.55)
				draw_line(p0, p1, col, w, true)
				p0 = p1

		"tree":
			draw_line(c + Vector2(0, s * 0.90), c + Vector2(0, -s * 0.10), col, w, true)
			draw_line(c + Vector2(0, s * 0.10), c + Vector2(-s * 0.70, -s * 0.55), col, w * 0.9, true)
			draw_line(c + Vector2(0, s * 0.10), c + Vector2(s * 0.70, -s * 0.55), col, w * 0.9, true)
			draw_line(c + Vector2(0, -s * 0.10), c + Vector2(-s * 0.40, -s * 0.90), col, w * 0.8, true)
			draw_line(c + Vector2(0, -s * 0.10), c + Vector2(s * 0.40, -s * 0.90), col, w * 0.8, true)

		"start":
			draw_circle(c, s * 0.28, col)
			for i in range(4):
				var a2 := i * TAU / 4.0 + PI / 4.0
				draw_line(c + Vector2(cos(a2), sin(a2)) * s * 0.52,
						  c + Vector2(cos(a2), sin(a2)) * s * 1.02, col, w * 0.9, true)

		_:
			draw_arc(c, s * 0.60, 0, TAU, 20, col, w, true)

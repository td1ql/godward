extends Button

# ============================================================
# MapNode —— 明日方舟风格的扁平地图节点
# ------------------------------------------------------------
#   var n := MapNode.new()
#   n.setup("battle", icon_texture, true, false)
#
# 形状按类型区分：
#   首领 → 六边形    精英 → 菱形
#   其余 → 圆环
#
# 状态：
#   可走  → 金色描边 + 呼吸光晕
#   当前  → 双层环 + 中心亮点
#   走过  → 暗金 + 45% 透明
#   不可走 → 灰
# ============================================================

const SIZE := 66.0
const GOLD := Color("c9a86a")
const GOLD_HI := Color("e6c98c")
const DIM := Color(0.55, 0.50, 0.42, 0.75)
const FAINT := Color(0.42, 0.39, 0.33, 0.45)
const INK := Color(0.043, 0.059, 0.078, 0.92)

var kind := "battle"
var state := "locked"      # current / walkable / visited / locked
var _icon: TextureRect
var _pulse := 0.0


func setup(k: String, tex: Texture2D, st: String) -> void:
	kind = k
	state = st
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP if st == "walkable" else Control.MOUSE_FILTER_IGNORE

	# 清掉 Button 自带的灰色圆角底（不然节点外面会有一个灰方块）
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())

	_icon = TextureRect.new()
	_icon.texture = tex
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var s := 30.0 if st != "locked" else 26.0
	_icon.position = Vector2((SIZE - s) / 2.0, (SIZE - s) / 2.0)
	_icon.size = Vector2(s, s)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if st == "locked":
		_icon.modulate = Color(1, 1, 1, 0.35)
	elif st == "visited":
		_icon.modulate = Color(1, 1, 1, 0.60)
	add_child(_icon)

	queue_redraw()


func _process(delta: float) -> void:
	if state == "walkable" or state == "current":
		_pulse += delta
		queue_redraw()


func _draw() -> void:
	var c := Vector2(SIZE / 2.0, SIZE / 2.0)
	var r := SIZE / 2.0 - 4.0

	var ring: Color = GOLD
	var glow := 0.0
	match state:
		"current":
			ring = GOLD_HI
			glow = 0.55 + 0.15 * sin(_pulse * 2.4)
		"walkable":
			ring = GOLD
			glow = 0.22 + 0.10 * sin(_pulse * 2.0)
		"visited":
			ring = DIM
		_:
			ring = FAINT

	# 外发光（可走 / 当前）
	if glow > 0.01:
		for i in range(3):
			var rr := r + 4.0 + i * 5.0
			draw_arc(c, rr, 0, TAU, 32, Color(GOLD, glow * (0.20 - i * 0.05)), 2.0, true)

	# 底板
	match kind:
		"boss", "serpent", "tree", "pope", "god", "divine_elite":
			_hex(c, r, INK, ring)
		"elite":
			_diamond(c, r, INK, ring)
		_:
			draw_circle(c, r, INK)
			draw_arc(c, r, 0, TAU, 40, ring, 2.0, true)

	# 当前节点：内圈 + 中心点
	if state == "current":
		draw_arc(c, r - 6.0, 0, TAU, 36, Color(GOLD_HI, 0.55), 1.0, true)


func _hex(c: Vector2, r: float, fill: Color, line: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(6):
		var a := -PI / 2.0 + i * TAU / 6.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, fill)
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, line, 2.0, true)


func _diamond(c: Vector2, r: float, fill: Color, line: Color) -> void:
	var pts := PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r, 0),
		c + Vector2(0, r), c + Vector2(-r, 0),
	])
	draw_colored_polygon(pts, fill)
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, line, 2.0, true)

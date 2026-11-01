extends Control

# ============================================================
# EnemyFx —— 敌人交互动画（纯代码，无素材）
# ------------------------------------------------------------
#   EnemyFx.hit(portrait, amount)     受击：抖动 + 白闪 + 飘伤害数字
#   EnemyFx.telegraph(portrait, lvl)  预警：放大招前红光呼吸
#   EnemyFx.death(portrait)           死亡：灰化 + 碎裂下沉
#   EnemyFx.heal(portrait)            回血：绿色光晕
#   EnemyFx.block(portrait)           加盾：蓝色弧光
#
# 传入的 portrait 是 TextureRect（战斗界面右侧那块立绘）
# ============================================================

const RED := Color(0.85, 0.24, 0.20)
const GREEN := Color(0.42, 0.78, 0.48)
const BLUE := Color(0.42, 0.66, 0.92)


# ---------- 受击 ----------
static func hit(portrait: Control, amount: int = 0, crit: bool = false) -> void:
	if portrait == null or not is_instance_valid(portrait):
		return
	var base := portrait.position
	var amp := 7.0 if crit else 4.0
	var t := portrait.create_tween()
	for i in range(3):
		t.tween_property(portrait, "position", base + Vector2(randf_range(-amp, amp), randf_range(-2, 2)), 0.035)
	t.tween_property(portrait, "position", base, 0.06)

	# 白闪：叠一层同尺寸的白色矩形
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.55)
	flash.size = portrait.size
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(flash)
	var ft := flash.create_tween()
	ft.tween_property(flash, "color:a", 0.0, 0.22)
	ft.tween_callback(flash.queue_free)

	if amount > 0:
		_float_number(portrait, str(amount), RED if not crit else Color(1.0, 0.72, 0.35), crit)


# ---------- 飘伤害数字 ----------
static func _float_number(portrait: Control, text: String, color: Color, big: bool = false) -> void:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 42 if big else 30)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	var parent := portrait.get_parent()
	if parent == null:
		parent = portrait
	l.position = portrait.position + Vector2(portrait.size.x * 0.30, portrait.size.y * 0.28)
	l.size = Vector2(120, 50)
	parent.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - 54.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.75).set_delay(0.20)
	t.tween_callback(l.queue_free)


# ---------- 大招预警 ----------
static func telegraph(portrait: Control, level: int = 1) -> void:
	if portrait == null or not is_instance_valid(portrait):
		return
	var ring := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(RED, 0.0)
	ring.add_theme_stylebox_override("panel", sb)
	ring.size = portrait.size
	ring.position = Vector2.ZERO
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(ring)

	var t := ring.create_tween().set_loops(3 if level <= 1 else 5)
	t.tween_property(ring, "modulate:a", 1.0, 0.28)
	t.parallel().tween_property(sb, "border_color", Color(RED, 0.95), 0.28)
	t.tween_property(ring, "modulate:a", 0.25, 0.28)
	t.parallel().tween_property(sb, "border_color", Color(RED, 0.25), 0.28)
	t.tween_callback(ring.queue_free)

	# 立绘本身也轻微放大一下，暗示「蓄力」
	var base := portrait.scale
	var p := portrait.create_tween()
	p.tween_property(portrait, "scale", base * 1.05, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	p.tween_property(portrait, "scale", base, 0.30)


# ---------- 回血 ----------
static func heal(portrait: Control, amount: int = 0) -> void:
	if portrait == null or not is_instance_valid(portrait):
		return
	var glow := ColorRect.new()
	glow.color = Color(GREEN, 0.0)
	glow.size = portrait.size
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(glow)
	var t := glow.create_tween()
	t.tween_property(glow, "color:a", 0.28, 0.20)
	t.tween_property(glow, "color:a", 0.0, 0.45)
	t.tween_callback(glow.queue_free)
	if amount > 0:
		_float_number(portrait, "+" + str(amount), GREEN)


# ---------- 加盾 ----------
static func block(portrait: Control, amount: int = 0) -> void:
	if portrait == null or not is_instance_valid(portrait):
		return
	var arc := ColorRect.new()
	arc.color = Color(BLUE, 0.0)
	arc.size = Vector2(6, portrait.size.y)
	arc.position = Vector2(0, 0)
	arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(arc)
	var t := arc.create_tween()
	t.tween_property(arc, "color:a", 0.55, 0.16)
	t.parallel().tween_property(arc, "position:x", portrait.size.x - 6, 0.34)
	t.parallel().tween_property(arc, "color:a", 0.0, 0.34)
	t.tween_callback(arc.queue_free)
	if amount > 0:
		_float_number(portrait, "+" + str(amount), BLUE)


# ---------- 死亡 ----------
static func death(portrait: Control) -> void:
	if portrait == null or not is_instance_valid(portrait):
		return
	var t := portrait.create_tween()
	t.set_parallel(true)
	t.tween_property(portrait, "modulate", Color(0.30, 0.26, 0.30, 0.0), 0.75).set_trans(Tween.TRANS_QUAD)
	t.tween_property(portrait, "scale", portrait.scale * Vector2(1.06, 0.94), 0.75)
	t.tween_property(portrait, "position:y", portrait.position.y + 26.0, 0.75)
	t.chain().tween_callback(func() -> void:
		portrait.visible = false
	)


# ---------- 出场 ----------
static func appear(portrait: Control) -> void:
	if portrait == null or not is_instance_valid(portrait):
		return
	var base := portrait.position
	portrait.modulate.a = 0.0
	portrait.position = base + Vector2(26, 0)
	var t := portrait.create_tween()
	t.set_parallel(true)
	t.tween_property(portrait, "modulate:a", 0.92, 0.42).set_trans(Tween.TRANS_SINE)
	t.tween_property(portrait, "position", base, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

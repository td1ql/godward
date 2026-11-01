extends Control

# ============================================================
# SkillCutIn —— 职业技能演出
# ------------------------------------------------------------
#   SkillCutIn.play(battle_node, vocation, on_done)
#
# 演出层次（全部代码绘制，无图）：
#   ① 全屏压暗（0.9 的墨）
#   ② 斜向光带从右往左掠过
#   ③ 职业名英文（大号）+ 中文技能名，从右侧滑入
#   ④ 一句台词，逐字打出
#   ⑤ 冲击：白闪 + 抖动
#   ⑥ 淡出
# ============================================================

const GOLD := Color("c9a86a")
const GOLD_HI := Color("e6c98c")
const CREAM := Color("f2ead6")

var _voc := ""
var _skill := {}
var _done: Callable

var _veil: ColorRect
var _band: ColorRect
var _en_lbl: Label
var _cn_lbl: Label
var _line_lbl: Label
var _flash: ColorRect
var _trail: Node2D
var _t := 0.0
var _phase := 0
var _line_full := ""
var _line_shown := 0.0


static func play(parent: Node, vocation: String, on_done: Callable) -> void:
	var c := new()
	c._voc = vocation
	c._skill = SkillDB.info_of(vocation)
	c._done = on_done
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(c)
	c._build()


func _build() -> void:
	size = Vector2(1280, 720)

	_veil = ColorRect.new()
	_veil.color = Color(0.012, 0.018, 0.024, 0.0)
	_veil.size = Vector2(1280, 720)
	add_child(_veil)

	# 斜向光带
	_band = ColorRect.new()
	_band.color = Color(GOLD, 0.0)
	_band.size = Vector2(420, 1100)
	_band.position = Vector2(1300, -200)
	_band.pivot_offset = Vector2(210, 550)
	_band.rotation = deg_to_rad(-18.0)
	add_child(_band)

	# 英文大字
	_en_lbl = Label.new()
	_en_lbl.text = str(_skill.get("en", ""))
	_en_lbl.position = Vector2(120, 236)
	_en_lbl.size = Vector2(1040, 110)
	_en_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_en_lbl.add_theme_font_size_override("font_size", 84)
	_en_lbl.add_theme_color_override("font_color", GOLD_HI)
	_en_lbl.modulate.a = 0.0
	_en_lbl.add_theme_constant_override("outline_size", 0)
	add_child(_en_lbl)

	# 中文技能名
	_cn_lbl = Label.new()
	_cn_lbl.text = str(_skill.get("name", ""))
	_cn_lbl.position = Vector2(124, 340)
	_cn_lbl.size = Vector2(700, 80)
	_cn_lbl.add_theme_font_size_override("font_size", 52)
	_cn_lbl.add_theme_color_override("font_color", CREAM)
	_cn_lbl.modulate.a = 0.0
	StoryDB.apply_serif(_cn_lbl)
	add_child(_cn_lbl)

	# 分隔线
	var rule := ColorRect.new()
	rule.color = GOLD
	rule.modulate.a = 0.0
	rule.position = Vector2(124, 428)
	rule.size = Vector2(0, 1)
	rule.name = "Rule"
	add_child(rule)

	# 台词
	_line_lbl = Label.new()
	_line_full = str(_skill.get("line", ""))
	_line_lbl.text = ""
	_line_lbl.position = Vector2(124, 450)
	_line_lbl.size = Vector2(820, 80)
	_line_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_lbl.add_theme_font_size_override("font_size", 22)
	_line_lbl.add_theme_color_override("font_color", Color(0.78, 0.74, 0.64))
	_line_lbl.modulate.a = 0.0
	StoryDB.apply_serif(_line_lbl)
	add_child(_line_lbl)

	# 白闪
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0.0)
	_flash.size = Vector2(1280, 720)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_start()


func _start() -> void:
	# 用多条独立 Tween，避免 parallel()/chain() 链式调用出问题
	var total := _line_full.length()

	var t1 := create_tween()
	t1.tween_property(_veil, "color:a", 0.88, 0.22)

	var t2 := create_tween()
	t2.tween_property(_band, "color:a", 0.30, 0.10)
	t2.tween_property(_band, "position:x", -520.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t2.parallel().tween_property(_band, "color:a", 0.0, 0.30)

	var t3 := create_tween()
	t3.tween_property(_en_lbl, "modulate:a", 0.55, 0.30)
	t3.parallel().tween_property(_en_lbl, "position:x", 124.0, 0.34).from(80.0)

	var t4 := create_tween()
	t4.tween_interval(0.10)
	t4.tween_property(_cn_lbl, "modulate:a", 1.0, 0.26)
	t4.parallel().tween_property($Rule, "size:x", 560.0, 0.30)
	t4.parallel().tween_property($Rule, "modulate:a", 0.55, 0.20)

	var t5 := create_tween()
	t5.tween_interval(0.30)
	t5.tween_property(_line_lbl, "modulate:a", 1.0, 0.22)

	# 台词逐字
	var type_tw := create_tween()
	type_tw.tween_interval(0.45)
	for i in range(total):
		type_tw.tween_callback(func() -> void:
			_line_lbl.text = _line_full.substr(0, i + 1)
		)
		type_tw.tween_interval(0.045)

	# 停留 → 冲击 → 淡出
	var hold := 0.45 + total * 0.045 + 0.40
	var t6 := create_tween()
	t6.tween_interval(hold)
	t6.tween_callback(_impact)
	t6.tween_interval(0.28)

	var t7 := create_tween()
	t7.tween_interval(hold + 0.28)
	t7.tween_property(_veil, "color:a", 0.0, 0.26)
	t7.parallel().tween_property(_en_lbl, "modulate:a", 0.0, 0.20)
	t7.parallel().tween_property(_cn_lbl, "modulate:a", 0.0, 0.20)
	t7.parallel().tween_property(_line_lbl, "modulate:a", 0.0, 0.20)
	t7.parallel().tween_property($Rule, "modulate:a", 0.0, 0.20)
	t7.tween_callback(_finish)


# 冲击帧：白闪 + 屏幕抖
func _impact() -> void:
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.55, 0.04)
	tw.tween_property(_flash, "color:a", 0.0, 0.22)
	# 抖动
	var base := position
	var tw2 := create_tween()
	for i in range(3):
		tw2.tween_property(self, "position", base + Vector2(randf_range(-7, 7), randf_range(-5, 5)), 0.035)
	tw2.tween_property(self, "position", base, 0.05)


func _finish() -> void:
	if _done.is_valid():
		_done.call()
	queue_free()

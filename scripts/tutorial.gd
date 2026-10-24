# ============================================================
# Tutorial —— 新手教程
# ------------------------------------------------------------
# 教学战按回合脚本抽牌：
#   第 1 回合 → 行动牌
#   第 2 回合 → 效果牌
#   第 3 回合 → 遭遇牌
#   第 4 回合 → 无上耀光
# ============================================================

extends Node

const ENEMY := {"name": "原罪*贪婪", "hp": 9999, "attack": 9999, "pattern": [1]}

const TURNS := [
	{"cards": ["晨光", "晨光", "圣辉"], "text": "点击手牌将它打出。【恒光】的加护将使你无惧伤痛"},
	{"cards": ["光之隙", "晨光", "晨光"], "text": "效果牌需要消耗别的手牌，但往往具有更强的效果"},
	{"cards": ["尘光", "晨光", "晨光"], "text": "遭遇牌抽到后会立即使用"},
	{"cards": ["无上耀光"], "text": "我赐予你————「无上耀光」"},
]

var active := false
var turn := 0

var _layer: CanvasLayer
var _label: Label

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 40
	add_child(_layer)

	_label = Label.new()
	_label.position = Vector2(90, 300)
	_label.size = Vector2(1100, 100)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 32)
	_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.70))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 3)
	StoryDB.apply_serif(_label)
	_label.visible = false
	_layer.add_child(_label)

func start() -> void:
	active = true
	turn = 0
	_label.visible = true
	_refresh()

func stop() -> void:
	active = false
	_label.visible = false

func cards_for(t: int) -> Array:
	if t < 0 or t >= TURNS.size():
		return []
	return TURNS[t]["cards"]

func advance() -> void:
	turn += 1
	_refresh()

func notify(event: String) -> void:
	if not active:
		return
	if event == "win":
		_label.text = "光芒照耀天地"

func _refresh() -> void:
	if turn >= TURNS.size():
		_label.text = "光芒照耀天地"
		return
	_label.text = str(TURNS[turn]["text"])

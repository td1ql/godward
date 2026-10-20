extends Node2D

# 三个"牌堆"，用数组表示
var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

# 引用场景里的两个节点（名字必须和场景里一致）
@onready var info_label: Label = $InfoLabel
@onready var draw_button: Button = $DrawButton

func _ready() -> void:
	# 开局给牌堆塞 5 张牌
	draw_pile = ["打击", "打击", "防御", "防御", "打击"]
	# 把按钮的"点击"事件绑定到下面这个函数
	draw_button.pressed.connect(_on_draw_pressed)
	_update_ui()

func _on_draw_pressed() -> void:
	if draw_pile.is_empty():
		info_label.text = "牌堆空了！"
		return
	var card: String = draw_pile.pop_back()
	hand.append(card)
	_update_ui()

func _update_ui() -> void:
	var hand_text := ""
	for c in hand:
		hand_text += c + "  "
	if hand_text == "":
		hand_text = "（空）"
	info_label.text = "牌堆: %d    弃牌: %d\n手牌: %s" % [
		draw_pile.size(), discard_pile.size(), hand_text
	]

extends Node

var _layer: CanvasLayer
var _root: Control

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 200
	add_child(_layer)

func open() -> void:
	if _root:
		return
	_root = Control.new()
	_root.size = Vector2(1280, 720)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.92)
	dim.size = Vector2(1280, 720)
	_root.add_child(dim)

	var cards := GameState.deck
	var title := Label.new()
	title.text = "牌库（%d 张）" % cards.size()
	title.position = Vector2(0, 18)
	title.size = Vector2(1280, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	_root.add_child(title)

	var n := cards.size()
	var per_row := 8
	var rows: int = max(1, int(ceil(float(n) / per_row)))
	var card_h: float = min(160.0, 520.0 / rows - 10.0)
	var card_w: float = min(130.0, card_h / 1.2)
	var gap := 10.0
	var total_w := per_row * card_w + (per_row - 1) * gap
	var start_x := (1280.0 - total_w) / 2.0
	var start_y := 80.0
	for i in range(n):
		@warning_ignore("integer_division")
		var row := i / per_row
		var col := i % per_row
		var btn := CardUI.make_button(cards[i], 14)
		btn.size = Vector2(card_w, card_h)
		btn.position = Vector2(start_x + col * (card_w + gap), start_y + row * (card_h + gap))
		btn.disabled = true
		_root.add_child(btn)

	var close := Button.new()
	close.text = "关闭"
	close.size = Vector2(200, 54)
	close.position = Vector2(540, 645)
	close.pressed.connect(_close)
	_root.add_child(close)
	Modal.apply_ink(close, 18)
func open_piles(draw: Array, hand: Array, discard: Array) -> void:
	_show_columns("牌堆", [
		{"title": "抽牌堆（%d）　顶部在下" % draw.size(), "cards": draw},
		{"title": "手牌（%d）" % hand.size(), "cards": hand},
		{"title": "弃牌堆（%d）　顶部在下" % discard.size(), "cards": discard},
	])

func _show_columns(title_text: String, sections: Array) -> void:
	if _root:
		return
	_root = Control.new()
	_root.size = Vector2(1280, 720)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.92)
	dim.size = Vector2(1280, 720)
	_root.add_child(dim)

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(0, 18)
	title.size = Vector2(1280, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	_root.add_child(title)

	var n := sections.size()
	var col_w := 1180.0 / n
	for i in range(n):
		var sec: Dictionary = sections[i]
		var x := 50.0 + i * col_w

		var head := Label.new()
		head.text = str(sec.get("title", ""))
		head.position = Vector2(x, 80)
		head.size = Vector2(col_w - 20, 30)
		head.add_theme_font_size_override("font_size", 18)
		head.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
		_root.add_child(head)

		var cards: Array = sec["cards"]
		var s := ""
		for j in range(cards.size()):
			s += "%d. %s\n" % [j + 1, str(cards[j])]
		var body := Label.new()
		body.text = s
		body.position = Vector2(x, 116)
		body.size = Vector2(col_w - 20, 520)
		body.add_theme_font_size_override("font_size", 16)
		_root.add_child(body)

	var close := Button.new()
	close.text = "关闭"
	close.size = Vector2(200, 54)
	close.position = Vector2(540, 645)
	close.pressed.connect(_close)
	_root.add_child(close)
	Modal.apply_ink(close, 18)
func open_choose(title_text: String, cards: Array, on_pick: Callable) -> void:
	if _root:
		return
	_root = Control.new()
	_root.size = Vector2(1280, 720)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.92)
	dim.size = Vector2(1280, 720)
	_root.add_child(dim)

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(0, 18)
	title.size = Vector2(1280, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	_root.add_child(title)

	var n := cards.size()
	var per_row := 8
	var rows: int = max(1, int(ceil(float(n) / per_row)))
	var card_h: float = min(150.0, 470.0 / rows - 10.0)
	var card_w: float = min(130.0, card_h / 1.2)
	var gap := 10.0
	var total_w := per_row * card_w + (per_row - 1) * gap
	var start_x := (1280.0 - total_w) / 2.0
	var start_y := 80.0
	for i in range(n):
		@warning_ignore("integer_division")
		var row := i / per_row
		var col := i % per_row
		var btn := CardUI.make_button(cards[i], 14)
		btn.size = Vector2(card_w, card_h)
		btn.position = Vector2(start_x + col * (card_w + gap), start_y + row * (card_h + gap))
		btn.pressed.connect(_on_choose.bind(i, on_pick))
		_root.add_child(btn)

	var skip := Button.new()
	skip.text = "跳过"
	skip.size = Vector2(200, 54)
	skip.position = Vector2(540, 640)
	skip.pressed.connect(_close)
	_root.add_child(skip)
	Modal.apply_ink(skip, 18)

func _on_choose(index: int, on_pick: Callable) -> void:
	on_pick.call(index)
	_close()

func _close() -> void:
	if _root:
		_root.queue_free()
		_root = null

func toggle() -> void:
	if _root:
		_close()
	else:
		open()

class_name HandView
extends Node2D

signal card_pressed(index: int)

var _buttons: Array[Button] = []

func render(cards: Array[String], energy: int, pending_effect: int, pending_selected: Array, animate_last: int = 0) -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	var n := cards.size()
	if n == 0:
		return
	var card_w: float = min(140.0, (1280.0 - 80.0) / n - 8.0)
	var card_h: float = card_w * 1.2
	var spacing := card_w + 8.0
	var total := (n - 1) * spacing + card_w
	var start_x := (1280.0 - total) / 2.0
	for i in range(n):
		var c: String = cards[i]
		var d: Dictionary = CardDB.get_card(c)
		var btn := CardUI.make_button(c)
		btn.size = Vector2(card_w, card_h)
		btn.position = Vector2(start_x + i * spacing, 438)
		if pending_effect >= 0:
			if i == pending_effect:
				btn.modulate = Color(1, 1, 0.55, 1)
			elif pending_selected.has(i):
				btn.modulate = Color(0.6, 1, 0.6, 1)
			else:
				btn.modulate = Color(1, 1, 1, 0.75)
		else:
			btn.disabled = energy < d["cost"]
		btn.pressed.connect(_on_press.bind(i))
		add_child(btn)
		_buttons.append(btn)
	CardAnim.play(self, _buttons, animate_last)

func hide_cards() -> void:
	visible = false

func show_cards() -> void:
	visible = true

func _on_press(index: int) -> void:
	card_pressed.emit(index)

func take_button(index: int) -> Button:
	if index < 0 or index >= _buttons.size():
		return null
	var b := _buttons[index]
	_buttons.remove_at(index)
	return b

extends Node2D

const CENTER := Vector2(640, 360)
const RADIUS := 230.0
const NODE_SIZE := Vector2(140, 64)
const PAN_TIME := 0.45
const FADE_TIME := 0.22

var nodes := {}
var node_buttons := {}
var button_base := {}
var current_id := 0
var next_id := 0
var is_moving := false
var map_offset := Vector2.ZERO
var pan_target := Vector2.ZERO
var overlay: Control

func _ready() -> void:
	var hint := Label.new()
	hint.position = Vector2(20, 20)
	hint.add_theme_font_size_override("font_size", 18)
	hint.text = "选择要前往的节点"
	add_child(hint)

	if not GameState.map_generated:
		_generate_map()
		GameState.map_nodes = nodes
		GameState.map_generated = true
		GameState.current_node_id = 0
	else:
		nodes = GameState.map_nodes

	current_id = GameState.current_node_id
	_rebuild_view()
	GameState.save_game()

func _process(_delta: float) -> void:
	if is_moving:
		queue_redraw()

func _generate_map() -> void:
	nodes.clear()
	next_id = 1
	nodes[0] = {"type": "start", "children": [], "depth": 0}
	_gen_children(0, 1, MapDB.ROOT_BRANCHES)

func _gen_children(parent_id: int, depth: int, count: int) -> void:
	if depth > MapDB.MAX_DEPTH:
		return
	for i in range(count):
		var id := next_id
		next_id += 1
		nodes[id] = {"type": _pick_type(depth), "children": [], "depth": depth}
		nodes[parent_id]["children"].append(id)
		if depth < MapDB.MAX_DEPTH:
			_gen_children(id, depth + 1, randi_range(MapDB.MIN_BRANCHES, MapDB.MAX_BRANCHES))

func _pick_type(depth: int) -> String:
	return MapDB.pick_type(depth)

func _rebuild_view() -> void:
	map_offset = Vector2.ZERO
	pan_target = Vector2.ZERO
	button_base.clear()
	for b in node_buttons.values():
		b.visible = false
		b.queue_free()
	node_buttons.clear()

	_make_node_button(current_id, CENTER)

	var kids: Array = nodes[current_id]["children"]
	var n := kids.size()
	for i in range(n):
		var angle := -PI / 2.0 + i * TAU / n
		var pos := CENTER + Vector2(cos(angle), sin(angle)) * RADIUS
		_make_node_button(kids[i], pos)

	queue_redraw()

func _make_node_button(id: int, pos: Vector2) -> Button:
	var info: Dictionary = MapDB.info_of(nodes[id]["type"])
	var b := Button.new()
	b.text = info["label"]
	b.size = NODE_SIZE
	button_base[id] = pos - NODE_SIZE / 2.0
	b.position = button_base[id] + map_offset
	b.modulate.a = 1.0
	b.add_theme_color_override("font_color", info["color"])
	b.add_theme_font_size_override("font_size", 20)
	if id != current_id:
		b.pressed.connect(_on_node_pressed.bind(id))
	add_child(b)
	node_buttons[id] = b
	return b

func _set_pan(p: float) -> void:
	map_offset = pan_target * p
	for id in node_buttons:
		node_buttons[id].position = button_base[id] + map_offset
	queue_redraw()

func _on_node_pressed(id: int) -> void:
	if is_moving or id == current_id:
		return
	is_moving = true
	AudioManager.play("click")
	var kids: Array = nodes[current_id]["children"]
	var index := kids.find(id)
	var n := kids.size()
	var angle := -PI / 2.0 + index * TAU / n
	var dest_local := CENTER + Vector2(cos(angle), sin(angle)) * RADIUS
	pan_target = CENTER - dest_local

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_set_pan, 0.0, 1.0, PAN_TIME)
	tw.finished.connect(_after_pan.bind(id))

func _after_pan(id: int) -> void:
	var tw := create_tween().set_parallel(true)
	for other_id in node_buttons.keys():
		if other_id == id:
			continue
		tw.tween_property(node_buttons[other_id], "modulate:a", 0.0, FADE_TIME)
	tw.finished.connect(_after_fade_out.bind(id))

func _after_fade_out(id: int) -> void:
	for other_id in node_buttons.keys():
		if other_id == id:
			continue
		var b: Button = node_buttons[other_id]
		b.visible = false
		b.queue_free()

	var center_btn: Button = node_buttons[id]
	current_id = id
	GameState.current_node_id = id
	GameState.save_game()
	center_btn.position = CENTER - NODE_SIZE / 2.0
	center_btn.modulate.a = 1.0

	node_buttons.clear()
	button_base.clear()
	node_buttons[id] = center_btn
	button_base[id] = CENTER - NODE_SIZE / 2.0
	map_offset = Vector2.ZERO
	pan_target = Vector2.ZERO

	var t: String = nodes[id]["type"]
	if t == "battle" or t == "elite" or t == "boss":
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return

	if t == "shop" or t == "rest" or t == "event":
		_show_encounter(t)
		return

	_continue_children()

func _continue_children() -> void:
	var kids: Array = nodes[current_id]["children"]
	var n := kids.size()
	var tw := create_tween().set_parallel(true)
	for i in range(n):
		var angle := -PI / 2.0 + i * TAU / n
		var pos := CENTER + Vector2(cos(angle), sin(angle)) * RADIUS
		var child_btn := _make_node_button(kids[i], pos)
		child_btn.modulate.a = 0.0
		tw.tween_property(child_btn, "modulate:a", 1.0, FADE_TIME)
	tw.finished.connect(_after_fade_in)
	queue_redraw()

func _after_fade_in() -> void:
	is_moving = false

func _draw() -> void:
	if not nodes.has(current_id):
		return
	draw_circle(CENTER, 92, Color(0.35, 0.55, 0.95, 0.10))
	var from_pos: Vector2 = CENTER + map_offset
	var kids: Array = nodes[current_id]["children"]
	for kid_id in kids:
		if not node_buttons.has(kid_id):
			continue
		var b: Button = node_buttons[kid_id]
		if not b.visible:
			continue
		var to_pos: Vector2 = b.position + NODE_SIZE / 2.0
		draw_line(from_pos, to_pos, Color(0.45, 0.55, 0.75, b.modulate.a), 3.0)
# ========== 遭遇界面：商店 / 休息 / 事件 ==========
func _show_encounter(t: String) -> void:
	overlay = Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var panel := ColorRect.new()
	panel.color = Color(0.13, 0.14, 0.19)
	panel.position = Vector2(390, 90)
	panel.size = Vector2(500, 540)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(420, 120)
	vbox.size = Vector2(440, 480)
	overlay.add_child(vbox)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(440, 100)
	body.add_theme_font_size_override("font_size", 18)
	vbox.add_child(body)

	match t:
		"rest":
			_encounter_rest(title, body, vbox)
		"event":
			_encounter_event(title, body, vbox)
		"shop":
			_encounter_shop(title, body, vbox)

func _encounter_rest(title: Label, body: Label, vbox: VBoxContainer) -> void:
	var heal := int(GameState.player_max_hp * RunConfig.REST_HEAL_RATIO)
	GameState.player_hp = min(GameState.player_max_hp, GameState.player_hp + heal)
	title.text = "休息"
	body.text = "你在篝火旁坐下，恢复了 %d 点生命。\n当前 HP: %d / %d" % [heal, GameState.player_hp, GameState.player_max_hp]
	var b := Button.new()
	b.text = "继续前进"
	b.pressed.connect(_close_encounter)
	vbox.add_child(b)

func _encounter_event(title: Label, body: Label, vbox: VBoxContainer) -> void:
	var ev: Dictionary = EventDB.pick()
	title.text = "事件"
	body.text = ev["text"]
	for c in ev["choices"]:
		var b := Button.new()
		b.text = c["label"]
		b.pressed.connect(_apply_event_choice.bind(c))
		vbox.add_child(b)

func _apply_event_choice(c: Dictionary) -> void:
	if c.has("hp"):
		var h: int = c["hp"]
		GameState.player_hp = clamp(GameState.player_hp + h, 1, GameState.player_max_hp)
	if c.has("gold"):
		GameState.gold += c["gold"]
	_close_encounter()

func _encounter_shop(title: Label, body: Label, vbox: VBoxContainer) -> void:
	var cards: Array = ShopDB.pick_cards()
	title.text = "商店"
	body.text = "金币: %d\n挑一张卡牌加入你的牌组吧。" % GameState.gold
	for card_name in cards:
		var price: int = CardDB.price_of(card_name)
		var b := Button.new()
		b.text = "购买 %s（%d 金币）" % [card_name, price]
		b.disabled = GameState.gold < price
		b.pressed.connect(_buy_card.bind(card_name, price, b))
		vbox.add_child(b)
	var leave := Button.new()
	leave.text = "离开"
	leave.pressed.connect(_close_encounter)
	vbox.add_child(leave)

func _buy_card(card_name: String, price: int, b: Button) -> void:
	if GameState.gold < price:
		return
	GameState.gold -= price
	GameState.deck.append(card_name)
	b.disabled = true
	b.text = "已购买 %s（剩余 %d 金币）" % [card_name, GameState.gold]

func _close_encounter() -> void:
	if overlay:
		overlay.queue_free()
		overlay = null
	GameState.save_game()
	_continue_children()

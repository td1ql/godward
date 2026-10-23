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
var gold_label: Label
var hp_label: Label
var moral_label: Label

func _ready() -> void:
	var hint := Label.new()
	var back := Button.new()
	back.text = "返回主菜单"
	back.position = Vector2(1080, 20)
	back.size = Vector2(170, 40)
	back.pressed.connect(_on_back_to_menu)
	add_child(back)
	hint.position = Vector2(20, 20)
	hint.add_theme_font_size_override("font_size", 18)
	hint.text = "选择要前往的节点"
	add_child(hint)
	gold_label = Label.new()
	gold_label.position = Vector2(20, 50)
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.text = "金币: %d" % GameState.gold
	add_child(gold_label)
	hp_label = Label.new()
	hp_label.position = Vector2(20, 80)
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_label.text = "HP: %d / %d" % [GameState.player_hp, GameState.player_max_hp]
	add_child(hp_label)
	moral_label = Label.new()
	moral_label.position = Vector2(20, 110)
	moral_label.add_theme_font_size_override("font_size", 18)
	moral_label.text = Morality.summary()
	add_child(moral_label)
	var deck_btn := Button.new()
	deck_btn.text = "牌库"
	deck_btn.position = Vector2(20, 120)
	deck_btn.size = Vector2(110, 40)
	deck_btn.pressed.connect(DeckViewer.toggle)
	add_child(deck_btn)



	if not GameState.map_generated:
		_generate_map()
		GameState.map_nodes = nodes
		GameState.map_generated = true
		GameState.current_node_id = 0
	else:
		nodes = GameState.map_nodes
		next_id = 0
		for k in nodes.keys():
			next_id = max(next_id, int(k) + 1)

	current_id = GameState.current_node_id
	_ensure_children(current_id)
	_rebuild_view()
	GameState.save_game()
	if GameState.pending_node == current_id:
		_reopen_pending()

func _reopen_pending() -> void:
	var kind: String = str(GameState.pending_snapshot.get("kind", ""))
	if kind == "battle" or kind == "contestant_fight" or kind == "pope":
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	var t: String = nodes[current_id]["type"]
	if t == "shop" or t == "rest" or t == "event" or t == "contestant" or t == "remnant":
		_show_encounter(t)
		return
	GameState.pending_node = -1
	GameState.pending_snapshot = {}
	GameState.save_game()

func _process(_delta: float) -> void:
	_update_hud()
	if is_moving:
		queue_redraw()

func _generate_map() -> void:
	nodes.clear()
	nodes[0] = {"type": "start", "children": [], "depth": 0}
	next_id = 1
	_ensure_children(0)
	GameState.map_nodes = nodes
	GameState.map_generated = true
	GameState.current_node_id = 0

func _gen_children(parent_id: int, depth: int, count: int) -> void:
	if depth > MapDB.max_depth_of(GameState.act):
		return
	for i in range(count):
		while nodes.has(next_id):
			next_id += 1
		var id := next_id
		next_id += 1
		var parent_type: String = nodes[parent_id]["type"]
		var t: String = _pick_type(depth)
		if (t == "elite" or t == "rest") and t == parent_type:
			t = "battle"
		nodes[id] = {"type": t, "children": [], "depth": depth}
		nodes[parent_id]["children"].append(id)

func _ensure_children(id: int) -> void:
	if not nodes.has(id):
		return
	var d: int = int(nodes[id]["depth"])
	if d >= MapDB.max_depth_of(GameState.act):
		return
	if not nodes[id]["children"].is_empty():
		return
	var count: int = MapDB.ROOT_BRANCHES if d == 0 else randi_range(MapDB.MIN_BRANCHES, MapDB.MAX_BRANCHES)
	_gen_children(id, d + 1, count)

func _prune(id: int) -> void:
	var keep := {}
	keep[id] = nodes[id]
	for child in nodes[id]["children"]:
		if nodes.has(child):
			keep[child] = nodes[child]
	nodes = keep

func _pick_type(depth: int) -> String:
	return MapDB.pick_type(depth, GameState.act)

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
	if not nodes.has(id) or not nodes.has(current_id):
		is_moving = false
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
	GameState.pending_node = id
	center_btn.position = CENTER - NODE_SIZE / 2.0
	center_btn.modulate.a = 1.0

	node_buttons.clear()
	button_base.clear()
	node_buttons[id] = center_btn
	button_base[id] = CENTER - NODE_SIZE / 2.0
	map_offset = Vector2.ZERO
	pan_target = Vector2.ZERO

	_prune(id)
	_ensure_children(id)
	GameState.map_nodes = nodes
	GameState.save_game()

	var t: String = nodes[id]["type"]
	if t == "battle" or t == "elite" or t == "boss" or t == "divine" or t == "divine_elite" or t == "pope":
		if GameState.pending_snapshot.is_empty():
			GameState.pending_snapshot = {"kind": "battle", "enemy": EnemyDB.pick_for_node(t)}
			GameState.save_game()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return

	if t == "shop" or t == "rest" or t == "event" or t == "contestant" or t == "remnant":
		_show_encounter(t)
		return

	GameState.pending_node = -1
	GameState.save_game()
	_continue_children()

func _continue_children() -> void:
	var stale: Array = []
	for id in node_buttons.keys():
		if id != current_id:
			stale.append(id)
	for id in stale:
		var old_btn: Button = node_buttons[id]
		old_btn.queue_free()
		node_buttons.erase(id)
		button_base.erase(id)

	var kids: Array = nodes[current_id]["children"]
	var n := kids.size()
	if n == 0:
		is_moving = false
		queue_redraw()
		return
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
	if overlay:
		overlay.queue_free()
		overlay = null
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
		"remnant":
			_encounter_remnant(title, body, vbox)
		"rest":
			_encounter_rest(title, body, vbox)
		"event":
			_encounter_event(title, body, vbox)
		"shop":
			_encounter_shop(title, body, vbox)
		"contestant":
			_encounter_contestant(title, body, vbox)

func _encounter_rest(title: Label, body: Label, vbox: VBoxContainer) -> void:
	title.text = "休息"
	var heal := int(GameState.player_max_hp * RunConfig.REST_HEAL_RATIO)
	body.text = "你可以在篝火旁休息，或者整理一下牌组。\n当前 HP: %d / %d" % [GameState.player_hp, GameState.player_max_hp]

	var rest := Button.new()
	rest.text = "休息（回复 %d HP）" % heal
	rest.pressed.connect(_rest_heal.bind(heal, body))
	vbox.add_child(rest)

	var discard := Button.new()
	discard.text = "弃掉一张牌（不休息）"
	discard.pressed.connect(_rest_discard)
	vbox.add_child(discard)

	var leave := Button.new()
	leave.text = "离开"
	leave.pressed.connect(_close_encounter)
	vbox.add_child(leave)

func _rest_heal(heal: int, body: Label) -> void:
	GameState.player_hp = min(GameState.player_max_hp, GameState.player_hp + heal)
	body.text = "你在篝火旁睡了一会儿，恢复了 %d 点生命。\n当前 HP: %d / %d" % [heal, GameState.player_hp, GameState.player_max_hp]
	_update_hud()
	_close_encounter()

func _rest_discard() -> void:
	_close_encounter()
	DeckViewer.open_choose("弃掉一张牌", GameState.deck, _discard_from_rest)

func _discard_from_rest(index: int) -> void:
	if index >= 0 and index < GameState.deck.size():
		var removed: String = GameState.deck[index]
		GameState.deck.remove_at(index)
		Toast.show_text("弃掉了「%s」" % removed, 2.5)
	GameState.save_game()

func _encounter_event(title: Label, body: Label, vbox: VBoxContainer) -> void:
	var ev: Dictionary
	if GameState.pending_snapshot.get("kind", "") == "event":
		ev = GameState.pending_snapshot["event"]
	else:
		ev = EventDB.pick(GameState.act)
		GameState.pending_snapshot = {"kind": "event", "event": ev, "path": []}
		GameState.save_game()

	var node: Dictionary = _event_node(ev)
	title.text = "事件"
	body.text = str(node.get("text", "")) + "\n\n（当前金币: %d）" % GameState.gold

	var choices: Array = node.get("choices", [])
	for i in range(choices.size()):
		var c: Dictionary = choices[i]
		var b := Button.new()
		b.text = str(c.get("label", "..."))
		var cost: int = int(c.get("gold", 0))
		if cost < 0 and GameState.gold + cost < 0:
			b.disabled = true
			b.text += "（金币不足）"
		b.pressed.connect(_pick_event_choice.bind(i, c))
		if not Morality.meets(c):
			b.disabled = true
			b.text += "（%s）" % Morality.req_text(c)
		vbox.add_child(b)

func _event_node(ev: Dictionary) -> Dictionary:
	var node := ev
	for i in GameState.pending_snapshot.get("path", []):
		var choices: Array = node.get("choices", [])
		var idx: int = int(i)
		if idx < 0 or idx >= choices.size():
			break
		var nxt: Dictionary = choices[idx].get("next", {})
		if nxt.is_empty():
			break
		node = nxt
	return node

func _pick_event_choice(index: int, c: Dictionary) -> void:
	if not Reward.can_apply(c):
		Toast.show_text("金币不足。")
		return
	Reward.apply(c)

	var nxt: Dictionary = c.get("next", {})
	if nxt.is_empty():
		_close_encounter()
		return

	var path: Array = GameState.pending_snapshot.get("path", [])
	path.append(index)
	GameState.pending_snapshot["path"] = path
	GameState.save_game()
	_show_encounter("event")

func _encounter_remnant(title: Label, body: Label, vbox: VBoxContainer) -> void:
	var r: Dictionary
	if GameState.pending_snapshot.get("kind", "") == "remnant":
		r = GameState.pending_snapshot["remnant"]
	else:
		r = RemnantDB.pick()
		GameState.pending_snapshot = {"kind": "remnant", "remnant": r}
		GameState.save_game()

	title.text = "遗骸　·　" + str(r["name"])
	body.text = str(r["text"])

	var take := Button.new()
	take.text = "收下遗物"
	take.pressed.connect(_take_remnant.bind(r))
	vbox.add_child(take)

	var leave := Button.new()
	leave.text = "离开"
	leave.pressed.connect(_close_encounter)
	vbox.add_child(leave)

func _take_remnant(r: Dictionary) -> void:
	var summary := Reward.apply(r)
	Toast.show_text("%s\n%s" % [str(r["name"]), summary], 3.0)
	_close_encounter()

func _encounter_contestant(title: Label, body: Label, vbox: VBoxContainer) -> void:
	var available: Array = []
	for id in GameState.contestants:
		if GameState.met_contestants.has(id) or GameState.eliminated.has(id):
			continue
		available.append(id)
	if available.is_empty():
		title.text = "参赛者"
		body.text = "这里空无一人，只剩风穿过神域的裂隙。"
		var leave := Button.new()
		leave.text = "离开"
		leave.pressed.connect(_close_encounter)
		vbox.add_child(leave)
		return

		if not Morality.meets(c):
			b.disabled = true
			b.text += "（%s）" % Morality.req_text(c)

	var id: String = ""
	if GameState.pending_snapshot.get("kind", "") == "contestant":
		id = str(GameState.pending_snapshot["id"])
	var valid := GameState.contestants.has(id) and not GameState.met_contestants.has(id) and not GameState.eliminated.has(id)
	if id == "" or not valid:
		id = available[randi() % available.size()]
		GameState.pending_snapshot = {"kind": "contestant", "id": id}
		GameState.save_game()
	var c: Dictionary = ContestantDB.scaled(id)
	title.text = "%s　·　%s" % [c["name"], c["trait"]]
	body.text = c["desc"] + "\n\n（场上还有 %d 名参赛者）" % _alive_count()
	body.text += "\n\n" + Morality.attitude()

	for choice in c["choices"]:
		var b := Button.new()
		b.text = choice["label"]
		b.pressed.connect(_contestant_choice.bind(id, choice))
		vbox.add_child(b)

func _alive_count() -> int:
	var n := 0
	for id in GameState.contestants:
		if not GameState.eliminated.has(id):
			n += 1
	return n

func _resolve_choice(c: Dictionary) -> Dictionary:
	if c.has("random"):
		var opts: Array = c["random"]
		var picked: Dictionary = opts[randi() % opts.size()]
		var merged := picked.duplicate()
		merged["result"] = c.get("result", "talk")
		if c.get("ally", false):
			merged["ally"] = true
		return merged
	return c

func _contestant_choice(id: String, choice: Dictionary) -> void:
	var result := _resolve_choice(choice)

	if result.get("result", "talk") == "fight":
		_fight_contestant(id)
		return

	if not Reward.can_apply(result):
		Toast.show_text("金币不足。")
		return

	GameState.met_contestants.append(id)
	var summary := Reward.apply(result, id)
	Toast.show_text("%s\n%s" % [str(result.get("text", "")), summary], 3.2)
	_close_encounter()

func _maybe_eliminate() -> void:
	var pool: Array = []
	for id in GameState.contestants:
		if GameState.met_contestants.has(id) or GameState.eliminated.has(id):
			continue
		pool.append(id)
	if pool.is_empty():
		return
	if randf() < 0.15:
		var id: String = pool[randi() % pool.size()]
		GameState.eliminated.append(id)
		Toast.show_text("%s 被淘汰了。" % ContestantDB.name_of(id))

func _encounter_shop(title: Label, body: Label, vbox: VBoxContainer) -> void:
	var cards: Array
	if GameState.pending_snapshot.get("kind", "") == "shop":
		cards = GameState.pending_snapshot["cards"]
	else:
		cards = ShopDB.pick_cards(GameState.act)
		GameState.pending_snapshot = {"kind": "shop", "cards": cards}
		GameState.save_game()
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

func _fight_contestant(id: String) -> void:
	var c: Dictionary = ContestantDB.get_contestant(id)
	GameState.pending_enemy = {
		"name": c["name"],
		"hp": int(c["hp"]),
		"attack": int(c["attack"]),
		"pattern": c.get("pattern", [1]),
		"on_hit": c.get("on_hit", {}),
	}
	GameState.pending_contestant = id
	GameState.pending_snapshot = {
		"kind": "contestant_fight",
		"id": id,
		"enemy": GameState.pending_enemy,
	}
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

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
	GameState.pending_node = -1
	GameState.pending_snapshot = {}
	GameState.save_game()
	_update_hud()
	_maybe_eliminate()
	_continue_children()

func _on_back_to_menu() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _update_hud() -> void:
	if gold_label:
		gold_label.text = "金币: %d" % GameState.gold
	if hp_label:
		hp_label.text = "HP: %d / %d" % [GameState.player_hp, GameState.player_max_hp]
	if moral_label:
		moral_label.text = Morality.summary()

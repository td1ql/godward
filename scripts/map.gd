extends Node2D

# ---------- 世界布局 ----------
const NODE_SIZE := Vector2(66, 66)
const RADIUS := 210.0
const ZOOM := 1.45
const WALK_TIME := 0.55
const FADE_TIME := 0.22

var nodes := {}
var node_buttons := {}
var world_pos := {}
var current_id := 0
var next_id := 0
var is_moving := false
var overlay: Control
var gold_label: Label
var hp_label: Label
var moral_label: Label

var ui_layer: CanvasLayer
var world: Node2D
var camera: Camera2D
var player_marker: Panel
var bg_rect: TextureRect
var edge_root: Node2D

func _ready() -> void:
	world = Node2D.new()
	add_child(world)

	bg_rect = TextureRect.new()
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	var map_bg := "res://assets/art/bg/bg_map_%d.webp" % GameState.act
	if not ResourceLoader.exists(map_bg):
		map_bg = "res://assets/art/bg/bg_map.webp"
	if ResourceLoader.exists(map_bg):
		bg_rect.texture = load(map_bg)
	world.add_child(bg_rect)

	edge_root = Node2D.new()
	edge_root.z_index = 0
	world.add_child(edge_root)

	player_marker = Panel.new()
	player_marker.size = Vector2(56, 56)
	player_marker.z_index = 5
	var mk := StyleBoxFlat.new()
	mk.bg_color = Color(0.11, 0.09, 0.07, 0.96)
	mk.border_width_left = 2
	mk.border_width_right = 2
	mk.border_width_top = 2
	mk.border_width_bottom = 2
	mk.border_color = Color(0.82, 0.70, 0.44)
	mk.corner_radius_top_left = 28
	mk.corner_radius_top_right = 28
	mk.corner_radius_bottom_left = 28
	mk.corner_radius_bottom_right = 28
	mk.shadow_color = Color(0.08, 0.06, 0.03, 0.55)
	mk.shadow_size = 9
	player_marker.add_theme_stylebox_override("panel", mk)
	world.add_child(player_marker)

	var pl := Label.new()
	pl.text = "你"
	pl.size = Vector2(56, 56)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pl.add_theme_font_size_override("font_size", 22)
	pl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	StoryDB.apply_serif(pl)
	player_marker.add_child(pl)

	camera = Camera2D.new()
	camera.zoom = Vector2(ZOOM, ZOOM)
	add_child(camera)
	camera.make_current()

	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var plate := Panel.new()
	plate.position = Vector2(8, 8)
	plate.size = Vector2(310, 200)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.94, 0.90, 0.80, 0.92)
	ps.border_width_left = 1
	ps.border_width_right = 1
	ps.border_width_top = 1
	ps.border_width_bottom = 1
	ps.border_color = Color(0.48, 0.37, 0.18, 0.55)
	ps.set_corner_radius_all(3)
	ps.shadow_color = Color(0.10, 0.07, 0.03, 0.35)
	ps.shadow_size = 6
	plate.add_theme_stylebox_override("panel", ps)
	hud.add_child(plate)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)

	var hint := Label.new()
	hint.text = "选择要前往的节点"
	hint.position = Vector2(20, 20)
	hint.add_theme_font_size_override("font_size", 20)
	hud.add_child(hint)

	gold_label = Label.new()
	gold_label.position = Vector2(20, 52)
	gold_label.text = "金币：%d" % GameState.gold
	hud.add_child(gold_label)

	hp_label = Label.new()
	hp_label.position = Vector2(20, 84)
	hp_label.text = "HP：%d / %d" % [GameState.player_hp, GameState.player_max_hp]
	hud.add_child(hp_label)

	moral_label = Label.new()
	moral_label.position = Vector2(20, 116)
	moral_label.text = Morality.summary()
	hud.add_child(moral_label)

	var deck_btn := Button.new()
	deck_btn.text = "牌库"
	deck_btn.position = Vector2(20, 152)
	deck_btn.size = Vector2(120, 44)
	deck_btn.pressed.connect(DeckViewer.toggle)
	UiKit.ghost_button(deck_btn, 18)
	hud.add_child(deck_btn)

	NavMenu.attach(hud, [
		{"text": "牌库", "action": func() -> void: DeckViewer.toggle()},
		{"text": "地图说明", "action": func() -> void: _show_map_hint()},
		{"text": "返回主菜单", "action": Callable(self, "_on_back_to_menu")},
	])

	for lb in [hint, gold_label, hp_label, moral_label]:
		lb.add_theme_color_override("font_color", Color(0.17, 0.13, 0.08))
		lb.add_theme_font_size_override("font_size", 23)
		StoryDB.apply_serif(lb)

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
	_ensure_positions()
	_rebuild_view()
	_snap_camera()
	GameState.save_game()
	if GameState.pending_node == current_id:
		_reopen_pending()

# ---------- 世界坐标 ----------
func _ensure_positions() -> void:
	if not world_pos.has(0):
		world_pos[0] = Vector2.ZERO
	var changed := true
	var guard := 0
	while changed and guard < 60:
		changed = false
		guard += 1
		for id in nodes.keys():
			if world_pos.has(id):
				continue
			var pid := _parent_of(id)
			if pid < 0 or not world_pos.has(pid):
				continue
			var sibs: Array = nodes[pid]["children"]
			var idx := sibs.find(id)
			var n := sibs.size()
			var angle := -PI / 2.0 + float(idx) * TAU / float(n)
			world_pos[id] = world_pos[pid] + Vector2(cos(angle), sin(angle)) * RADIUS
			changed = true

func _parent_of(id: int) -> int:
	for pid in nodes.keys():
		if (nodes[pid]["children"] as Array).has(id):
			return pid
	return -1

func _update_bg() -> void:
	if world_pos.is_empty():
		return
	var mn := Vector2(99999, 99999)
	var mx := Vector2(-99999, -99999)
	for p in world_pos.values():
		mn.x = min(mn.x, p.x)
		mn.y = min(mn.y, p.y)
		mx.x = max(mx.x, p.x)
		mx.y = max(mx.y, p.y)
	mn -= Vector2(560, 560)
	mx += Vector2(560, 560)
	bg_rect.position = mn
	bg_rect.size = mx - mn

func _snap_camera() -> void:
	if world_pos.has(current_id):
		player_marker.position = world_pos[current_id] - player_marker.size / 2.0
		camera.position = world_pos[current_id]

func _rebuild_view() -> void:
	for b in node_buttons.values():
		if is_instance_valid(b):
			b.queue_free()
	node_buttons.clear()
	for c in edge_root.get_children():
		c.queue_free()

	var path := _path_to_current()

	var i := 0
	while i < path.size() - 1:
		_add_edge(path[i], path[i + 1])
		i += 1
	for cid in nodes[current_id]["children"]:
		_add_edge(current_id, cid)

	var visible_ids: Array = path.duplicate()
	for cid in nodes[current_id]["children"]:
		if not visible_ids.has(cid):
			visible_ids.append(cid)

	for id in visible_ids:
		if nodes.has(id) and world_pos.has(id):
			_make_node_button(id, world_pos[id])

	_update_bg()

func _path_to_current() -> Array:
	var out: Array = []
	var id := current_id
	var guard := 0
	while id >= 0 and guard < 60:
		out.append(id)
		guard += 1
		if id == 0:
			break
		id = _parent_of(id)
	return out

func _add_edge(a: int, b: int) -> void:
	if not world_pos.has(a) or not world_pos.has(b):
		return
	var ln := Line2D.new()
	ln.points = PackedVector2Array([world_pos[a], world_pos[b]])
	ln.width = 3.0
	ln.default_color = Color(0.24, 0.16, 0.09, 0.55)
	edge_root.add_child(ln)

func _make_node_button(id: int, pos: Vector2) -> Button:
	var t := str(nodes[id]["type"])
	var info: Dictionary = MapDB.info_of(t)
	var b := Button.new()
	b.size = NODE_SIZE
	b.position = pos - NODE_SIZE / 2.0
	b.focus_mode = Control.FOCUS_NONE

	var icon_path := "res://assets/art/node/%s.webp" % t
	if ResourceLoader.exists(icon_path):
		b.icon = load(icon_path)
		b.expand_icon = true
	else:
		b.text = str(info["label"])
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", Color(0.98, 0.95, 0.86))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	StoryDB.apply_serif(b)

	var clickable: bool = (nodes[current_id]["children"] as Array).has(id)
	if clickable:
		b.pressed.connect(_on_node_pressed.bind(id))
		b.mouse_entered.connect(func() -> void: b.modulate = Color(1.28, 1.2, 1.06, 1.0))
		b.mouse_exited.connect(func() -> void: b.modulate = Color(1, 1, 1, 1))
	elif id != current_id:
		b.modulate = Color(1, 1, 1, 0.45)

	world.add_child(b)
	node_buttons[id] = b
	return b

# ---------- 移动 ----------
func _on_node_pressed(id: int) -> void:
	if is_moving or id == current_id:
		return
	if not (nodes[current_id]["children"] as Array).has(id):
		return
	is_moving = true
	AudioManager.play("click")
	var from: Vector2 = world_pos[current_id]
	var to: Vector2 = world_pos[id]
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_walk.bind(from, to), 0.0, 1.0, WALK_TIME)
	tw.finished.connect(_after_walk.bind(id))

func _walk(t: float, from: Vector2, to: Vector2) -> void:
	var p := from.lerp(to, t)
	player_marker.position = p - player_marker.size / 2.0
	camera.position = p

func _after_walk(id: int) -> void:
	current_id = id
	GameState.current_node_id = id
	GameState.pending_node = id
	_ensure_children(id)
	_ensure_positions()
	GameState.map_nodes = nodes
	GameState.save_game()
	_rebuild_view()
	is_moving = false
	_trigger_node(id)

func _trigger_node(id: int) -> void:
	var t: String = str(nodes[id]["type"])
	if t == "battle" or t == "elite" or t == "boss" or t == "divine" or t == "divine_elite" or t == "pope":
		if GameState.pending_snapshot.is_empty():
			GameState.pending_snapshot = {"kind": "battle", "enemy": EnemyDB.pick_for_node(t, int(nodes[id]["depth"]))}
			GameState.save_game()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	if t == "shop" or t == "rest" or t == "event" or t == "contestant" or t == "remnant":
		_show_encounter(t)
		return
	GameState.pending_node = -1
	GameState.save_game()

func _process(_delta: float) -> void:
	_update_hud()

# ---------- 生成 ----------
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

func _pick_type(depth: int) -> String:
	return MapDB.pick_type(depth, GameState.act)

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
# ========== 遭遇界面：商店 / 休息 / 事件 ==========
func _show_encounter(t: String) -> void:
	if overlay:
		overlay.queue_free()
		overlay = null
	overlay = Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(250, 56)
	panel.size = Vector2(780, 608)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.09, 0.10, 0.13, 0.96)
	ps.border_width_left = 2
	ps.border_width_right = 2
	ps.border_width_top = 2
	ps.border_width_bottom = 2
	ps.border_color = Color(0.55, 0.44, 0.24, 0.55)
	ps.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", ps)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(286, 86)
	vbox.size = Vector2(708, 548)
	vbox.add_theme_constant_override("separation", 10)
	overlay.add_child(vbox)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.93, 0.87, 0.71))
	StoryDB.apply_serif(title)
	vbox.add_child(title)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(708, 70)
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.80, 0.76, 0.66))
	StoryDB.apply_serif(body)
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
		"wealth":
			_encounter_wealth(title, body, vbox)
		"god":
			_encounter_god(title, body, vbox)
		"shell":
			_encounter_shell(title, body, vbox)
		"contestant":
			_encounter_contestant(title, body, vbox)


const WEALTH_GOODS := [
	{"key": "hp",     "name": "寿命", "price": 90,  "desc": "最大生命 +10"},
	{"key": "str",    "name": "力气", "price": 110, "desc": "每场战斗开局 +1 力量"},
	{"key": "draw",   "name": "眼力", "price": 90,  "desc": "每回合多抽 1 张"},
	{"key": "forget", "name": "遗忘", "price": 80,  "desc": "删掉一张牌"},
]

func _encounter_wealth(title: Label, body: Label, vbox: VBoxContainer) -> void:
	title.text = "财富之神"
	body.text = "「你带来什么？」\n他的手心朝上，一直没合上。"
	for g in WEALTH_GOODS:
		var key: String = str(g["key"])
		var b := _ink_button("%s　%d 金　—— %s" % [str(g["name"]), int(g["price"]), str(g["desc"])])
		b.pressed.connect(_buy_wealth.bind(g))
		vbox.add_child(b)
	var leave := _ink_button("离开")
	leave.pressed.connect(_close_encounter)
	vbox.add_child(leave)

func _buy_wealth(g: Dictionary) -> void:
	var price: int = int(g["price"])
	if GameState.gold < price:
		Toast.show_text("金币不足。")
		return
	GameState.gold -= price
	match str(g["key"]):
		"hp":
			GameState.wealth_hp += 10
			GameState.recompute_max_hp()
			GameState.player_hp = min(GameState.player_max_hp, GameState.player_hp + 10)
		"str":
			GameState.wealth_str += 1
		"draw":
			GameState.wealth_draw += 1
		"forget":
			GameState.save_game()
			DeckViewer.open_choose("忘掉一张牌", GameState.deck, _forget_one)
			return
	GameState.save_game()
	Toast.show_text("%s\n已生效。" % str(g["desc"]), 3.0)
	_close_encounter()

func _forget_one(index: int) -> void:
	if index >= 0 and index < GameState.deck.size():
		var c: String = GameState.deck[index]
		GameState.deck.remove_at(index)
		Toast.show_text("你忘了「%s」。" % c, 3.0)
	GameState.save_game()
	_close_encounter()

func _encounter_god(title: Label, body: Label, vbox: VBoxContainer) -> void:
	var g: Dictionary = EnemyDB.pick_for_node("god", 0)
	title.text = str(g.get("name", "疯狂的神"))
	var organ := str(g.get("organ", ""))
	body.text = "它还在呼吸。\n它身上少了点什么。\n\n（击败它可以取走「%s」）" % organ
	var fight := _ink_button("和它动手")
	fight.pressed.connect(func() -> void: _start_battle_with(g))
	vbox.add_child(fight)
	var leave := _ink_button("绕开")
	leave.pressed.connect(_close_encounter)
	vbox.add_child(leave)

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
	if ev.get("pick_contestant", false) and not GameState.pending_snapshot.has("picked"):
		var pool: Array = []
		for cid in GameState.contestants:
			if not GameState.eliminated.has(cid) and not GameState.met_contestants.has(cid):
				pool.append(cid)
		if pool.is_empty():
			for cid in GameState.contestants:
				if not GameState.eliminated.has(cid):
					pool.append(cid)
		if not pool.is_empty():
			GameState.pending_snapshot["picked"] = str(pool[randi() % pool.size()])
			GameState.save_game()

	var picked_name := ""
	if GameState.pending_snapshot.has("picked"):
		picked_name = ContestantDB.name_of(str(GameState.pending_snapshot["picked"]))
	title.text = "事件"
	body.text = str(node.get("text", "")).replace("{name}", picked_name) + "\n\n（当前金币: %d）" % GameState.gold

	var choices: Array = node.get("choices", [])
	for i in range(choices.size()):
		var c: Dictionary = choices[i]
		var b := Button.new()
		b.text = str(c.get("label", "...")).replace("{name}", picked_name)
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
	if not Morality.meets(c):
		Toast.show_text("条件不足。")
		return
	if not Reward.can_apply(c):
		Toast.show_text("金币不足。")
		return
	Reward.apply(c)

	var picked: String = str(GameState.pending_snapshot.get("picked", ""))
	if picked != "":
		if c.get("kill_picked", false) and not GameState.eliminated.has(picked):
			GameState.eliminated.append(picked)
			Morality.add(-5, 10)
		if c.get("meet_picked", false) and not GameState.met_contestants.has(picked):
			GameState.met_contestants.append(picked)
		if c.get("ally_picked", false) and not GameState.allies.has(picked):
			GameState.allies.append(picked)
			Toast.show_text("「%s」成为了你的盟友" % ContestantDB.name_of(picked), 2.5)

	if int(c.get("discard", 0)) > 0 and not GameState.deck.is_empty():
		_close_encounter()
		DeckViewer.open_choose("弃掉一张牌", GameState.deck, _discard_from_rest)
		return

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

	title.text = str(r["name"])
	var open_line := str(r.get("open", ""))
	var rest := str(r["text"])
	body.text = open_line + "\n\n" + rest

	var take := _ink_button("带走它")
	take.pressed.connect(_take_remnant.bind(r))
	vbox.add_child(take)

	var leave := _ink_button("留在这里")
	leave.pressed.connect(_close_encounter)
	vbox.add_child(leave)

func _take_remnant(r: Dictionary) -> void:
	var summary := Reward.apply(r)
	Toast.show_text("%s\n%s" % [str(r["name"]), summary], 3.0)
	_close_encounter()

func _encounter_contestant(title: Label, body: Label, vbox: VBoxContainer) -> void:
	if GameState.act == 3:
		_encounter_contestant_act3(title, body, vbox)
		return
	var available: Array = []
	for cid in GameState.contestants:
		if GameState.eliminated.has(cid):
			continue
		available.append(cid)
	if available.is_empty():
		title.text = "参赛者"
		body.text = "这里空无一人，只剩风穿过神域的裂隙。"
		var leave := Button.new()
		leave.text = "离开"
		leave.pressed.connect(_close_encounter)
		vbox.add_child(leave)
		return

	var id: String = ""
	if GameState.pending_snapshot.get("kind", "") == "contestant":
		id = str(GameState.pending_snapshot["id"])
	var valid := GameState.contestants.has(id) and not GameState.eliminated.has(id)
	if id == "" or not valid:
		id = available[randi() % available.size()]
		var meet: int = int(GameState.meet_count.get(id, 0))
		GameState.pending_snapshot = {"kind": "contestant", "id": id, "meet": meet}
		GameState.meet_count[id] = meet + 1
		GameState.save_game()

	var meet_now: int = int(GameState.pending_snapshot.get("meet", 0))
	var c: Dictionary = ContestantDB.scaled(id)
	var scene: Dictionary = ContestantDB.scene_for(id, meet_now)
	if scene.get("auto_fight", false):
		Toast.show_text("「%s」先动手了。" % str(c["name"]), 2.0)
		_fight_contestant(id)
		return

	title.text = "%s　·　%s" % [c["name"], c["trait"]]
	body.text = str(scene["text"]) + "\n\n（场上还有 %d 名参赛者）" % _alive_count()
	body.text += "\n\n" + Morality.attitude()

	var choices: Array = scene["choices"]
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var b := Button.new()
		b.text = str(choice.get("label", "..."))
		if not Morality.meets(choice):
			b.disabled = true
			b.text += "（%s）" % Morality.req_text(choice)
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
	var d := ContestantDB.impression_delta(id, result)
	GameState.impressions[id] = clampi(int(GameState.impressions.get(id, 0)) + d, -100, 100)
	var summary := Reward.apply(result, id)
	var hint := ""
	if d >= 30:
		hint = "\n他记住了你。"
	elif d >= 12:
		hint = "\n他看了你一眼。"
	elif d <= -12:
		hint = "\n他往后退了半步。"
	Toast.show_text("%s\n%s%s" % [str(result.get("text", "")), summary, hint], 3.2)
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
	title.text = "商 店"
	body.text = "金币：%d　　挑一张，加入你的牌组。" % GameState.gold

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(700, 300)
	vbox.add_child(row)

	for card_name in cards:
		var price: int = CardDB.price_of(card_name)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		row.add_child(col)

		var card := CardUI.make_button(card_name, 16)
		card.custom_minimum_size = Vector2(176, 258)
		card.size = Vector2(176, 258)
		card.disabled = GameState.gold < price
		card.pressed.connect(_buy_card.bind(card_name, price, card, body))
		col.add_child(card)

		var tag := Label.new()
		tag.text = "%d 金币" % price
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_theme_font_size_override("font_size", 19)
		tag.add_theme_color_override("font_color", Color(0.90, 0.79, 0.50))
		StoryDB.apply_serif(tag)
		col.add_child(tag)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(gap)

	var leave := _ink_button("离 开")
	leave.pressed.connect(_close_encounter)
	vbox.add_child(leave)

func _ink_button(content: String) -> Button:
	return UiKit.ink_button(content)


func _start_battle_with(data: Dictionary) -> void:
	GameState.pending_enemy = data
	GameState.pending_snapshot = {"kind": "battle", "enemy": data}
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# ===== 第三幕：只有两个选项 =====
func _act3_pool() -> Array:
	var out: Array = []
	for id in ContestantDB.CONTESTANTS:
		if GameState.eliminated.has(id):
			continue
		if GameState.allies.has(id):
			continue
		out.append(id)
	return out

func _encounter_contestant_act3(title: Label, body: Label, vbox: VBoxContainer) -> void:
	var pool := _act3_pool()
	if pool.is_empty():
		title.text = "没有别人了"
		body.text = "路上只有你。"
		var go := _ink_button("继续")
		go.pressed.connect(_close_encounter)
		vbox.add_child(go)
		return

	var id: String = str(pool[randi() % pool.size()])
	var c: Dictionary = ContestantDB.get_contestant(id)
	title.text = str(c["name"])
	body.text = str(c["desc"]) + "\n\n诸神下来之后，没有人再守规矩。"

	var kill := _ink_button("杀死他")
	kill.pressed.connect(func() -> void: _fight_contestant(id))
	vbox.add_child(kill)

	var ally := _ink_button("结盟")
	ally.pressed.connect(func() -> void: _ally_contestant(id))
	vbox.add_child(ally)

func _ally_contestant(id: String) -> void:
	if not GameState.allies.has(id):
		GameState.allies.append(id)
	GameState.divinity = clampi(GameState.divinity - 5, 0, 100)
	GameState.save_game()
	Toast.show_text("「%s」站到了你身后。" % ContestantDB.name_of(id), 3.0)
	_close_encounter()


# ===== 第三幕：空壳（没有器官的尸骸）=====
const SHELLS := [
	{
		"text": "一具跪着的尸体。\n手心朝上，像在等什么东西。",
		"choices": [
			{"label": "拿走它的手指", "max_hp": -8, "str": 2, "text": "你把指节拧了下来。\n它们在你手里还是弯的。"},
			{"label": "让它继续等", "hp": 15, "moral": 5, "text": "你在它对面坐了一会。\n走的时候，伤口没那么疼了。"},
			{"label": "把它推倒", "gold": 40, "moral": -6, "text": "它倒了。\n身下的土里埋着钱。"},
		],
	},
	{
		"text": "一具站着的尸体。\n脸朝天，嘴张着。",
		"choices": [
			{"label": "抬头看", "divinity": 10, "text": "天上什么也没有。\n但你看了很久。"},
			{"label": "挖出它的眼睛", "gold": 25, "moral": -4, "text": "眼睛还是湿的。\n有人会要。"},
			{"label": "把它的嘴合上", "hp": 10, "moral": 6, "text": "合不严。\n你试了三次。"},
		],
	},
	{
		"text": "一具蜷缩的尸体。\n怀里抱着什么东西。",
		"choices": [
			{"label": "掰开它的手", "random_cards": 1, "moral": -3, "text": "是一张牌。\n上面有它的体温。"},
			{"label": "连它带东西一起埋了", "gold": 20, "moral": 8, "text": "你挖了一个浅坑。\n够用了。"},
		],
	},
	{
		"text": "一具没有头的尸体。\n还握着剑，握得很紧。",
		"choices": [
			{"label": "拿走那把剑", "str": 1, "max_hp": -5, "text": "剑很重。\n拿起来之后，你的手一直在抖。"},
			{"label": "把剑留在原地", "hp": 12, "text": "你松开了它的手指。\n一根，一根。"},
		],
	},
]

func _encounter_shell(title: Label, body: Label, vbox: VBoxContainer) -> void:
	var s: Dictionary = SHELLS[randi() % SHELLS.size()]
	title.text = "空壳"
	body.text = str(s["text"])
	for c in s["choices"]:
		var b := _ink_button(str(c["label"]))
		b.pressed.connect(_take_shell.bind(c, body))
		vbox.add_child(b)
	var leave := _ink_button("绕过去")
	leave.pressed.connect(_close_encounter)
	vbox.add_child(leave)

func _take_shell(c: Dictionary, body: Label) -> void:
	if c.has("max_hp"):
		GameState.wealth_hp += int(c["max_hp"])
		GameState.recompute_max_hp()
		GameState.player_hp = min(GameState.player_hp, GameState.player_max_hp)
	if c.has("hp"):
		GameState.player_hp = clampi(GameState.player_hp + int(c["hp"]), 1, GameState.player_max_hp)
	if c.has("gold"):
		GameState.gold = max(0, GameState.gold + int(c["gold"]))
	if c.has("str"):
		GameState.wealth_str += int(c["str"])
	if c.has("moral"):
		Morality.add(int(c["moral"]), 0)
	if c.has("divinity"):
		GameState.divinity = clampi(GameState.divinity + int(c["divinity"]), 0, 100)
	if c.has("random_cards"):
		for i in range(int(c["random_cards"])):
			var pool: Array = CardDB.reward_pool()
			if not pool.is_empty():
				GameState.deck.append(str(pool[randi() % pool.size()]))
	GameState.save_game()
	Toast.show_text(str(c.get("text", "")), 3.5)
	_close_encounter()

func _fight_contestant(id: String) -> void:
	var c: Dictionary = ContestantDB.get_contestant(id)
	GameState.pending_enemy = {
		"name": c["name"],
		"hp": int(c["hp"]),
		"attack": int(c["attack"]),
		"pattern": c.get("pattern", [1]),
		"on_hit": c.get("on_hit", {}),
		"domain": c.get("domain", {}),
	}
	GameState.pending_contestant = id
	GameState.pending_snapshot = {
		"kind": "contestant_fight",
		"id": id,
		"enemy": GameState.pending_enemy,
	}
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _buy_card(card_name: String, price: int, b: Button, body: Label) -> void:
	if GameState.gold < price:
		return
	GameState.gold -= price
	GameState.deck.append(card_name)
	b.disabled = true
	b.modulate = Color(0.50, 0.50, 0.50, 0.85)
	body.text = "金币：%d　　挑一张，加入你的牌组。" % GameState.gold
	AudioManager.play("click")

func _close_encounter() -> void:
	if overlay:
		overlay.queue_free()
		overlay = null
	GameState.pending_node = -1
	GameState.pending_snapshot = {}
	GameState.save_game()
	_update_hud()
	_maybe_eliminate()
	_rebuild_view()
	is_moving = false

func _show_map_hint() -> void:
	MapHelp.open(ui_layer)

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

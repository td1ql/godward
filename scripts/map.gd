extends Node2D

const CENTER := Vector2(640, 360)
const RADIUS := 230.0
const NODE_SIZE := Vector2(140, 64)
const MAX_DEPTH := 4
const PAN_TIME := 0.45
const FADE_TIME := 0.22

const TYPE_INFO := {
	"start": {"label": "起点", "color": Color(0.85, 0.85, 0.85)},
	"battle": {"label": "战斗", "color": Color(0.95, 0.45, 0.45)},
	"elite": {"label": "精英", "color": Color(0.75, 0.45, 0.95)},
	"shop": {"label": "商店", "color": Color(0.95, 0.85, 0.35)},
	"event": {"label": "事件", "color": Color(0.45, 0.75, 0.95)},
	"rest": {"label": "休息", "color": Color(0.45, 0.9, 0.55)},
	"boss": {"label": "首领", "color": Color(1.0, 0.25, 0.25)},
}

var nodes := {}
var node_buttons := {}
var button_base := {}
var current_id := 0
var next_id := 0
var is_moving := false
var map_offset := Vector2.ZERO
var pan_target := Vector2.ZERO

func _ready() -> void:
	var hint := Label.new()
	hint.position = Vector2(20, 20)
	hint.add_theme_font_size_override("font_size", 18)
	hint.text = "选择要前往的节点"
	add_child(hint)
	_generate_map()
	_rebuild_view()
func _process(_delta: float) -> void:
	if is_moving:
		queue_redraw()
func _generate_map() -> void:
	nodes.clear()
	next_id = 1
	nodes[0] = {"type": "start", "children": [], "depth": 0}
	_gen_children(0, 1, 5)

func _gen_children(parent_id: int, depth: int, count: int) -> void:
	if depth > MAX_DEPTH:
		return
	for i in range(count):
		var id := next_id
		next_id += 1
		nodes[id] = {"type": _pick_type(depth), "children": [], "depth": depth}
		nodes[parent_id]["children"].append(id)
		if depth < MAX_DEPTH:
			_gen_children(id, depth + 1, randi_range(2, 4))

func _pick_type(depth: int) -> String:
	if depth >= MAX_DEPTH:
		return "boss"
	match depth:
		1:
			return "battle"
		2:
			var pool := ["battle", "battle", "event"]
			return pool[randi() % pool.size()]
		3:
			var pool := ["elite", "shop", "rest", "event"]
			return pool[randi() % pool.size()]
		_:
			return "battle"

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
	var info: Dictionary = TYPE_INFO[nodes[id]["type"]]
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
	var kids: Array = nodes[current_id]["children"]
	var index := kids.find(id)
	var n := kids.size()
	var angle := -PI / 2.0 + index * TAU / n
	var dest_local := CENTER + Vector2(cos(angle), sin(angle)) * RADIUS
	pan_target = CENTER - dest_local

	# 第一阶段：整张地图平移，把选中节点送到中心（玩家不动）
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_set_pan, 0.0, 1.0, PAN_TIME)
	tw.finished.connect(_after_pan.bind(id))

func _after_pan(id: int) -> void:
	# 第二阶段：除选中节点外，其他节点淡出
	var tw := create_tween().set_parallel(true)
	for other_id in node_buttons.keys():
		if other_id == id:
			continue
		tw.tween_property(node_buttons[other_id], "modulate:a", 0.0, FADE_TIME)
	tw.finished.connect(_after_fade_out.bind(id))

func _after_fade_out(id: int) -> void:
	# 清掉旧节点，只保留被选中的那个作为新中心
	for other_id in node_buttons.keys():
		if other_id == id:
			continue
		var b: Button = node_buttons[other_id]
		b.visible = false
		queue_redraw()
		b.queue_free()

	var center_btn: Button = node_buttons[id]
	current_id = id
	center_btn.position = CENTER - NODE_SIZE / 2.0
	center_btn.modulate.a = 1.0

	node_buttons.clear()
	button_base.clear()
	node_buttons[id] = center_btn
	button_base[id] = CENTER - NODE_SIZE / 2.0
	map_offset = Vector2.ZERO
	pan_target = Vector2.ZERO

	# 第三阶段：新子节点从透明淡入
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

func _after_fade_in() -> void:
	is_moving = false

func _draw() -> void:
	if not nodes.has(current_id):
		return
	# 玩家固定标记
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

# ============================================================
# NpcView —— 英雄 NPC 的对话界面（galgame 式）
# ------------------------------------------------------------
#   NpcView.open(map_node, "阿喀琉斯", on_leave)
#   on_leave(action, npc_id)  action = "leave" / "fight" / "bond"
#
# 布局（自上而下）：
#   左：立绘（有 hero 图用图，没有用剪影占位）
#   右上：NPC 名字 + 称号
#   右中：选项区（话题 / 回答都出现在这里，紧贴对话框上方）
#   右下：对话框（NPC 说什么）
#   底部：拔刀 / 离开
# ============================================================

class_name NpcView
extends RefCounted

const BOX_BG := Color(0.055, 0.05, 0.048, 1.0)
const BOX_EDGE := Color(0.62, 0.50, 0.28)
const TEXT := Color(0.92, 0.88, 0.78)
const DIM := Color(0.58, 0.54, 0.46)
const GOLD := Color(0.95, 0.86, 0.62)

const PORTRAIT_POS := Vector2(92, 104)
const PORTRAIT_SIZE := Vector2(340, 470)
const OPT_X := 470.0
const OPT_W := 760.0
const OPT_BOTTOM := 470.0     # 选项区贴着对话框上沿
const BOX_Y := 486.0
const BOX_H := 168.0


static func open(parent: Node, npc_id: String, on_leave: Callable) -> void:
	if not NpcDB.has(npc_id):
		Toast.show_text("（这个人的故事还没写。）", 2.0)
		return
	var box := Box.new()
	box.parent = parent
	box.npc_id = npc_id
	box.on_leave = on_leave
	box.favor = int(GameState.impressions.get(npc_id, 0))
	box.seen = GameState.npc_seen.get(npc_id, [])
	box.build()


class Box:
	var parent: Node
	var npc_id := ""
	var on_leave: Callable
	var favor := 0
	var seen: Array = []

	var overlay: Control
	var line_lbl: Label
	var favor_lbl: Label
	var mood_lbl: Label
	var opt_root: VBoxContainer
	var mode := "topics"        # topics / responses
	var current_topic: Dictionary = {}

	func build() -> void:
		overlay = Control.new()
		overlay.size = Vector2(1280, 720)
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		overlay.z_index = 120
		parent.add_child(overlay)

		var bg := ColorRect.new()
		bg.color = Color(0.035, 0.032, 0.03, 1.0)
		bg.size = Vector2(1280, 720)
		overlay.add_child(bg)

		# ---- 立绘 ----
		var pic := TextureRect.new()
		var path := NpcDB.portrait_of(npc_id)
		if ResourceLoader.exists(path):
			pic.texture = load(path)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.position = NpcView.PORTRAIT_POS
		pic.size = NpcView.PORTRAIT_SIZE
		overlay.add_child(pic)
		frame(NpcView.PORTRAIT_POS, NpcView.PORTRAIT_SIZE)

		# ---- 右上角名字 ----
		var name_lbl := Label.new()
		name_lbl.text = npc_id
		name_lbl.position = Vector2(470, 56)
		name_lbl.size = Vector2(400, 46)
		name_lbl.add_theme_font_size_override("font_size", 34)
		name_lbl.add_theme_color_override("font_color", GOLD)
		name_lbl.add_theme_constant_override("outline_size", 3)
		name_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.04))
		StoryDB.apply_serif(name_lbl)
		overlay.add_child(name_lbl)

		var title := Label.new()
		title.text = NpcDB.title_of(npc_id)
		title.position = Vector2(470, 100)
		title.size = Vector2(400, 26)
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", DIM)
		StoryDB.apply_serif(title)
		overlay.add_child(title)

		mood_lbl = Label.new()
		mood_lbl.position = Vector2(470, 132)
		mood_lbl.size = Vector2(700, 28)
		mood_lbl.add_theme_font_size_override("font_size", 17)
		mood_lbl.add_theme_color_override("font_color", Color(0.72, 0.66, 0.52))
		StoryDB.apply_serif(mood_lbl)
		overlay.add_child(mood_lbl)

		favor_lbl = Label.new()
		favor_lbl.position = Vector2(1060, 60)
		favor_lbl.size = Vector2(160, 26)
		favor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		favor_lbl.add_theme_font_size_override("font_size", 15)
		favor_lbl.add_theme_color_override("font_color", DIM)
		StoryDB.apply_serif(favor_lbl)
		overlay.add_child(favor_lbl)

		# ---- 选项区（贴着对话框上沿，从下往上长）----
		opt_root = VBoxContainer.new()
		opt_root.position = Vector2(NpcView.OPT_X, 160)
		opt_root.size = Vector2(NpcView.OPT_W, NpcView.OPT_BOTTOM - 160)
		opt_root.custom_minimum_size = Vector2(NpcView.OPT_W, NpcView.OPT_BOTTOM - 160)
		opt_root.alignment = BoxContainer.ALIGNMENT_END
		opt_root.add_theme_constant_override("separation", 8)
		overlay.add_child(opt_root)

		# ---- 对话框 ----
		var panel := Panel.new()
		panel.position = Vector2(NpcView.OPT_X, NpcView.BOX_Y)
		panel.size = Vector2(NpcView.OPT_W, NpcView.BOX_H)
		var sb := StyleBoxFlat.new()
		sb.bg_color = NpcView.BOX_BG
		sb.border_color = NpcView.BOX_EDGE
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", sb)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(panel)

		line_lbl = Label.new()
		line_lbl.text = NpcDB.greeting_of(npc_id)
		line_lbl.position = Vector2(24, 22)
		line_lbl.size = Vector2(NpcView.OPT_W - 48, NpcView.BOX_H - 40)
		line_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line_lbl.add_theme_font_size_override("font_size", 20)
		line_lbl.add_theme_color_override("font_color", TEXT)
		StoryDB.apply_serif(line_lbl)
		panel.add_child(line_lbl)

		# ---- 底部按钮 ----
		var fight := Button.new()
		fight.text = NpcDB.FIGHT_LABEL
		fight.position = Vector2(470, 660)
		fight.size = Vector2(230, 44)
		fight.add_theme_font_size_override("font_size", 17)
		UiKit.ghost_button(fight, 17)
		fight.pressed.connect(func() -> void:
			close()
			on_leave.call("fight", npc_id)
		)
		overlay.add_child(fight)

		var leave := Button.new()
		leave.text = NpcDB.LEAVE_LABEL
		leave.position = Vector2(1000, 660)
		leave.size = Vector2(230, 44)
		leave.add_theme_font_size_override("font_size", 17)
		UiKit.ghost_button(leave, 17)
		leave.pressed.connect(func() -> void:
			close()
			on_leave.call("leave", npc_id)
		)
		overlay.add_child(leave)

		show_topics()

	func close() -> void:
		if overlay != null and is_instance_valid(overlay):
			overlay.queue_free()

	# ---------- 话题列表 ----------
	func show_topics() -> void:
		mode = "topics"
		current_topic = {}
		clear_opt()
		favor_lbl.text = "好感 %d" % favor
		mood_lbl.text = NpcDB.mood_of(npc_id, favor)

		for tp in NpcDB.available_topics(npc_id, favor, seen):
			var b := _opt_button(str(tp.get("label", "")), 17, NpcView.TEXT)
			b.pressed.connect(func() -> void: pick_topic(tp))
			opt_root.add_child(b)

		if GameState.allies.has(npc_id):
			var yes := Label.new()
			yes.text = "（他已经跟在你后面了）"
			yes.custom_minimum_size = Vector2(0, 32)
			yes.add_theme_font_size_override("font_size", 15)
			yes.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
			StoryDB.apply_serif(yes)
			opt_root.add_child(yes)
		elif NpcDB.can_bond(npc_id, favor):
			var bond := _opt_button("「跟我一起走。」", 19, NpcView.GOLD)
			bond.pressed.connect(func() -> void: do_bond())
			opt_root.add_child(bond)
		elif NpcDB.available_topics(npc_id, favor, seen).is_empty():
			var done := Label.new()
			done.text = "（他不再说话了。你们之间只剩风。）" if not NpcDB.has_locked_topics(npc_id, favor, seen) else "（他好像还有话，但没说。）"
			done.custom_minimum_size = Vector2(0, 32)
			done.add_theme_font_size_override("font_size", 15)
			done.add_theme_color_override("font_color", NpcView.DIM)
			StoryDB.apply_serif(done)
			opt_root.add_child(done)

	# ---------- 点开一个话题：说话 + 弹出回答 ----------
	func pick_topic(tp: Dictionary) -> void:
		current_topic = tp
		line_lbl.text = NpcDB.line_of(npc_id, tp)
		mood_lbl.text = "—— " + NpcDB.action_of(npc_id, tp)
		if not seen.has(str(tp.get("id", ""))):
			seen.append(str(tp.get("id", "")))
			GameState.npc_seen[npc_id] = seen
			GameState.save_game()
		show_responses()

	func show_responses() -> void:
		mode = "responses"
		clear_opt()
		favor_lbl.text = "好感 %d" % favor
		for r in current_topic.get("responses", []):
			var b := _opt_button(str(r.get("label", "")), 17, NpcView.TEXT)
			b.pressed.connect(func() -> void: pick_response(r))
			opt_root.add_child(b)

	# ---------- 选一个回答：NPC 回应 ----------
	func pick_response(r: Dictionary) -> void:
		line_lbl.text = str(r.get("text", ""))
		favor = clampi(favor + int(r.get("favor", 0)), 0, 100)
		GameState.impressions[npc_id] = favor
		GameState.save_game()
		show_topics()

	func do_bond() -> void:
		line_lbl.text = "他沉默了很久。\n「……好。」\n他把刀别回腰上，走到你后面半步。"
		if not GameState.allies.has(npc_id):
			GameState.allies.append(npc_id)
		Morality.add(8, 0)
		GameState.save_game()
		Toast.show_text("「%s」站到了你身后。" % npc_id, 3.0)
		on_leave.call("bond", npc_id)

	# ---------- 工具 ----------
	func clear_opt() -> void:
		for ch in opt_root.get_children():
			opt_root.remove_child(ch)
			ch.queue_free()

	func _opt_button(text: String, size_px: int, color: Color) -> Button:
		var b := Button.new()
		b.text = text
		b.custom_minimum_size = Vector2(0, 40)
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiKit.ghost_button(b, size_px)
		b.add_theme_color_override("font_color", color)
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.78))
		return b

	func frame(pos: Vector2, size: Vector2) -> void:
		var p := Panel.new()
		p.position = pos
		p.size = size
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = NpcView.BOX_EDGE
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(3)
		p.add_theme_stylebox_override("panel", sb)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(p)

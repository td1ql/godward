# ============================================================
# NpcView —— 英雄 NPC 的对话界面（galgame 式）
# ------------------------------------------------------------
#   NpcView.open(map_node, "阿喀琉斯", on_leave)
#
#   on_leave(action, npc_id)
#     action = "leave" / "fight" / "bond"
#
# 布局：
#   左边   立绘（有 hero 图用图，没有就用剪影占位）+ 金框
#   右下   对话框（名字 + 好感 + 台词）
#   右侧   可聊话题（好感不够的不出现）
#   底部   拔刀 / 离开
# ============================================================

class_name NpcView
extends RefCounted

const BOX_BG := Color(0.06, 0.05, 0.05, 0.94)
const BOX_EDGE := Color(0.62, 0.50, 0.28)
const TEXT := Color(0.92, 0.88, 0.78)
const DIM := Color(0.58, 0.54, 0.46)
const GOLD := Color(0.95, 0.86, 0.62)


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
	var topics_root: VBoxContainer

	func build() -> void:
		overlay = Control.new()
		overlay.size = Vector2(1280, 720)
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		overlay.z_index = 120
		parent.add_child(overlay)

		var bg := ColorRect.new()
		bg.color = Color(0.03, 0.03, 0.04, 0.97)
		bg.size = Vector2(1280, 720)
		overlay.add_child(bg)

		# 立绘
		var pic := TextureRect.new()
		var path := NpcDB.portrait_of(npc_id)
		if ResourceLoader.exists(path):
			pic.texture = load(path)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.position = Vector2(96, 60)
		pic.size = Vector2(360, 500)
		pic.modulate = Color(1, 1, 1, 0.92)
		overlay.add_child(pic)
		frame(Vector2(96, 60), Vector2(360, 500))

		var title := Label.new()
		title.text = NpcDB.title_of(npc_id)
		title.position = Vector2(480, 68)
		title.size = Vector2(400, 28)
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", DIM)
		StoryDB.apply_serif(title)
		overlay.add_child(title)

		# 对话框
		var panel := Panel.new()
		panel.position = Vector2(470, 400)
		panel.size = Vector2(760, 180)
		var sb := StyleBoxFlat.new()
		sb.bg_color = BOX_BG
		sb.border_color = BOX_EDGE
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", sb)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(panel)

		var name_lbl := Label.new()
		name_lbl.text = npc_id
		name_lbl.position = Vector2(20, 8)
		name_lbl.size = Vector2(300, 32)
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.add_theme_color_override("font_color", GOLD)
		name_lbl.add_theme_constant_override("outline_size", 2)
		name_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.04))
		StoryDB.apply_serif(name_lbl)
		panel.add_child(name_lbl)

		favor_lbl = Label.new()
		favor_lbl.position = Vector2(560, 12)
		favor_lbl.size = Vector2(180, 26)
		favor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		favor_lbl.add_theme_font_size_override("font_size", 15)
		favor_lbl.add_theme_color_override("font_color", DIM)
		StoryDB.apply_serif(favor_lbl)
		panel.add_child(favor_lbl)

		line_lbl = Label.new()
		line_lbl.text = "他站在那里，没有看你。"
		line_lbl.position = Vector2(20, 50)
		line_lbl.size = Vector2(720, 120)
		line_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line_lbl.add_theme_font_size_override("font_size", 19)
		line_lbl.add_theme_color_override("font_color", TEXT)
		StoryDB.apply_serif(line_lbl)
		panel.add_child(line_lbl)

		# 话题列表
		topics_root = VBoxContainer.new()
		topics_root.position = Vector2(472, 104)
		topics_root.size = Vector2(756, 280)
		topics_root.custom_minimum_size = Vector2(756, 280)
		topics_root.add_theme_constant_override("separation", 6)
		overlay.add_child(topics_root)

		# 底部按钮
		var fight := Button.new()
		fight.text = NpcDB.FIGHT_LABEL
		fight.position = Vector2(472, 642)
		fight.size = Vector2(240, 46)
		fight.focus_mode = Control.FOCUS_NONE
		fight.add_theme_font_size_override("font_size", 17)
		UiKit.ghost_button(fight, 17)
		fight.pressed.connect(func() -> void:
			close()
			on_leave.call("fight", npc_id)
		)
		overlay.add_child(fight)

		var leave := Button.new()
		leave.text = NpcDB.LEAVE_LABEL
		leave.position = Vector2(988, 642)
		leave.size = Vector2(240, 46)
		leave.focus_mode = Control.FOCUS_NONE
		leave.add_theme_font_size_override("font_size", 17)
		UiKit.ghost_button(leave, 17)
		leave.pressed.connect(func() -> void:
			close()
			on_leave.call("leave", npc_id)
		)
		overlay.add_child(leave)

		refresh()

	func close() -> void:
		if overlay != null and is_instance_valid(overlay):
			overlay.queue_free()

	# 重建话题按钮
	func refresh() -> void:
		for ch in topics_root.get_children():
			ch.queue_free()
		favor_lbl.text = "好感 %d" % favor

		for tp in NpcDB.available_topics(npc_id, favor, seen):
			var b := Button.new()
			b.text = str(tp.get("label", ""))
			b.custom_minimum_size = Vector2(0, 42)
			b.focus_mode = Control.FOCUS_NONE
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 17)
			UiKit.ghost_button(b, 17)
			b.pressed.connect(func() -> void: pick(tp))
			topics_root.add_child(b)

		if GameState.allies.has(npc_id):
			var yes := Label.new()
			yes.text = "（他已经跟在你后面了）"
			yes.custom_minimum_size = Vector2(0, 34)
			yes.add_theme_font_size_override("font_size", 15)
			yes.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
			StoryDB.apply_serif(yes)
			topics_root.add_child(yes)
		elif NpcDB.can_bond(npc_id, favor):
			var bond := Button.new()
			bond.text = "「跟我一起走。」"
			bond.custom_minimum_size = Vector2(0, 46)
			bond.focus_mode = Control.FOCUS_NONE
			bond.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bond.add_theme_font_size_override("font_size", 19)
			bond.add_theme_color_override("font_color", GOLD)
			UiKit.ghost_button(bond, 19)
			bond.pressed.connect(func() -> void: do_bond())
			topics_root.add_child(bond)

	func pick(tp: Dictionary) -> void:
		line_lbl.text = str(tp.get("text", ""))
		favor += int(tp.get("favor", 0))
		seen.append(str(tp.get("id", "")))
		GameState.impressions[npc_id] = favor
		GameState.npc_seen[npc_id] = seen
		GameState.save_game()
		refresh()

	func do_bond() -> void:
		line_lbl.text = "他沉默了很久。\n「……好。」\n他把刀别回腰上，走到你后面半步。"
		if not GameState.allies.has(npc_id):
			GameState.allies.append(npc_id)
		Morality.add(8, 0)
		GameState.save_game()
		Toast.show_text("「%s」站到了你身后。" % npc_id, 3.0)
		refresh()
		on_leave.call("bond", npc_id)

	# 画一圈金框
	func frame(pos: Vector2, size: Vector2) -> void:
		var p := Panel.new()
		p.position = pos
		p.size = size
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = BOX_EDGE
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(3)
		p.add_theme_stylebox_override("panel", sb)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(p)

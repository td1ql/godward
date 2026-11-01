class_name MapHelp
extends RefCounted

# ============================================================
# MapHelp —— 「地图」说明弹窗：图例 + 规则
# 图标和地图节点共用 MapNode（全部代码绘制）
# ============================================================

const MapNode = preload("res://scripts/map_node.gd")
const ArkPanel = preload("res://scripts/ark_panel.gd")

const COLS := 2
const CELL_W := 520.0
const CELL_H := 86.0

const BY_ACT := {
	1: ["battle", "elite", "boss", "event", "shop", "rest", "npc", "start"],
	2: ["divine", "divine_elite", "pope", "event", "shop", "rest", "remnant", "start"],
	3: ["battle", "god", "wealth", "shell", "npc", "event", "serpent"],
}

const NOTE := {
	"battle": "普通的敌人。",
	"elite": "更强的敌人，给更好的东西。",
	"boss": "这一层的守门人。",
	"event": "说不清会发生什么。",
	"shop": "用金币换牌，或者删掉一张。",
	"rest": "恢复，或者做点别的。",
	"npc": "和你一样在逐神的人。",
	"remnant": "过去某一世的你。",
	"divine": "神国的造物。",
	"divine_elite": "神国的守卫。",
	"pope": "他在教堂里等你。",
	"start": "你从这里出发。",
	"god": "疯了的神。打赢它，拿走它的一部分。",
	"wealth": "用金币换属性。它只收金币。",
	"shell": "没有器官的尸骸。拿走什么，就得放下什么。",
	"serpent": "啃咬世界树的那条蛇。",
}

const TITLE_CN := {
	1: "第一幕 · 人间",
	2: "第二幕 · 伪神国",
	3: "第三幕 · 神明之土",
}
const TITLE_EN := {
	1: "ACT I  ·  THE WORLD OF MEN",
	2: "ACT II  ·  THE FALSE DIVINE REALM",
	3: "ACT III  ·  THE LAND OF GODS",
}


static func open(parent: Node) -> void:
	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 200
	parent.add_child(overlay)

	# 底：深墨 + 很淡的网格
	var bg := ColorRect.new()
	bg.color = Color(0.024, 0.035, 0.047, 0.96)
	bg.size = Vector2(1280, 720)
	overlay.add_child(bg)

	# 主面板
	var plate := ArkPanel.new()
	plate.position = Vector2(70, 54)
	plate.size = Vector2(1140, 612)
	plate.cut = 34.0
	plate.alpha = 0.55
	overlay.add_child(plate)

	# 左上：章节标题
	var act: int = GameState.act
	var t_cn := Label.new()
	t_cn.text = str(TITLE_CN.get(act, TITLE_CN[1]))
	t_cn.position = Vector2(106, 82)
	t_cn.size = Vector2(520, 40)
	t_cn.add_theme_font_size_override("font_size", 30)
	t_cn.add_theme_color_override("font_color", Color(0.90, 0.76, 0.44))
	StoryDB.apply_serif(t_cn)
	overlay.add_child(t_cn)

	var t_en := Label.new()
	t_en.text = str(TITLE_EN.get(act, TITLE_EN[1]))
	t_en.position = Vector2(108, 120)
	t_en.size = Vector2(560, 24)
	t_en.add_theme_font_size_override("font_size", 13)
	t_en.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42))
	overlay.add_child(t_en)

	# 右上：规则说明
	var tip := Label.new()
	tip.text = "点击有连线相连的节点前进。\n走过的路会留在图上。"
	tip.position = Vector2(700, 88)
	tip.size = Vector2(470, 60)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tip.add_theme_font_size_override("font_size", 15)
	tip.add_theme_color_override("font_color", Color(0.70, 0.66, 0.56))
	StoryDB.apply_serif(tip)
	overlay.add_child(tip)

	# 分隔线
	var line := ColorRect.new()
	line.color = Color(0.79, 0.66, 0.42, 0.35)
	line.position = Vector2(106, 156)
	line.size = Vector2(1068, 1)
	overlay.add_child(line)

	# 图例
	var grid_x := 106.0
	var grid_y := 186.0
	var order: Array = BY_ACT.get(act, BY_ACT[1])
	for i in range(order.size()):
		var t: String = order[i]
		if not MapDB.TYPE_INFO.has(t):
			continue
		var info: Dictionary = MapDB.TYPE_INFO[t]
		var col: int = i % COLS
		var row: int = i / COLS
		var x: float = grid_x + col * CELL_W
		var y: float = grid_y + row * CELL_H

		var icon := MapNode.new()
		icon.position = Vector2(x, y)
		icon.setup(t, null, "walkable")
		overlay.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = str(info.get("label", t))
		name_lbl.position = Vector2(x + 78, y + 4)
		name_lbl.size = Vector2(CELL_W - 96, 30)
		name_lbl.add_theme_font_size_override("font_size", 21)
		name_lbl.add_theme_color_override("font_color", Color(0.93, 0.88, 0.76))
		StoryDB.apply_serif(name_lbl)
		overlay.add_child(name_lbl)

		var note := Label.new()
		note.text = str(NOTE.get(t, ""))
		note.position = Vector2(x + 78, y + 34)
		note.size = Vector2(CELL_W - 96, 44)
		note.add_theme_font_size_override("font_size", 14)
		note.add_theme_color_override("font_color", Color(0.62, 0.58, 0.50))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		StoryDB.apply_serif(note)
		overlay.add_child(note)

	# 返回按钮（切角小面板 + 金线）
	var back := Button.new()
	back.text = "返回地图"
	back.position = Vector2(520, 612)
	back.size = Vector2(240, 46)
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override("font_size", 18)
	back.add_theme_color_override("font_color", Color(0.90, 0.76, 0.44))
	back.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.66))
	StoryDB.apply_serif(back)
	var nb := StyleBoxFlat.new()
	nb.bg_color = Color(0.05, 0.07, 0.09, 0.70)
	nb.border_color = Color(0.79, 0.66, 0.42, 0.55)
	nb.set_border_width_all(1)
	back.add_theme_stylebox_override("normal", nb)
	var hb := nb.duplicate()
	hb.bg_color = Color(0.79, 0.66, 0.42, 0.16)
	hb.border_color = Color(0.90, 0.76, 0.44, 0.95)
	back.add_theme_stylebox_override("hover", hb)
	back.add_theme_stylebox_override("pressed", hb)
	back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back.pressed.connect(overlay.queue_free)
	overlay.add_child(back)

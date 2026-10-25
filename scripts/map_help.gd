class_name MapHelp
extends RefCounted

# ============================================================
# MapHelp —— 「地图」说明弹窗：图例 + 规则
# 图标直接读 assets/art/node/*.webp
# ============================================================

const ICON_DIR := "res://assets/art/node/%s.webp"
const COLS := 2
const CELL_W := 560.0
const CELL_H := 88.0

const BY_ACT := {
	1: ["battle", "elite", "boss", "event", "shop", "rest", "contestant", "start"],
	2: ["divine", "divine_elite", "pope", "event", "shop", "rest", "remnant", "start"],
	3: ["battle", "god", "wealth", "shell", "contestant", "event", "serpent"],
}

const NOTE := {
	"battle": "普通的敌人。",
	"elite": "更强的敌人，给更好的东西。",
	"boss": "这一层的守门人。",
	"event": "说不清会发生什么。",
	"shop": "用金币换牌，或者删掉一张。",
	"rest": "恢复，或者做点别的。",
	"contestant": "和你一样在逐神的人。",
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


static func open(parent: Node) -> void:
	var overlay := Modal.open(parent, 0.94)
	Modal.title(overlay, "地图", 34, 32)

	var tip := Label.new()
	tip.text = "点击有连线相连的节点前进。走过的路会留在图上。"
	tip.position = Vector2(0, 78)
	tip.size = Vector2(1280, 28)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 17)
	tip.add_theme_color_override("font_color", Color(0.72, 0.69, 0.60))
	StoryDB.apply_serif(tip)
	overlay.add_child(tip)

	var grid_x := (1280.0 - COLS * CELL_W) / 2.0
	var grid_y := 120.0
	var order: Array = BY_ACT.get(GameState.act, BY_ACT[1])
	for i in range(order.size()):
		var t: String = order[i]
		if not MapDB.TYPE_INFO.has(t):
			continue
		var info: Dictionary = MapDB.TYPE_INFO[t]
		var col: int = i % COLS
		var row: int = i / COLS
		var x: float = grid_x + col * CELL_W
		var y: float = grid_y + row * CELL_H

		var path := ICON_DIR % t
		if ResourceLoader.exists(path):
			var icon := TextureRect.new()
			icon.texture = load(path)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.position = Vector2(x, y)
			icon.size = Vector2(64, 64)
			overlay.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = str(info.get("label", t))
		name_lbl.position = Vector2(x + 74, y + 2)
		name_lbl.size = Vector2(CELL_W - 90, 30)
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", Color(0.92, 0.87, 0.74))
		StoryDB.apply_serif(name_lbl)
		overlay.add_child(name_lbl)

		var note := Label.new()
		note.text = str(NOTE.get(t, ""))
		note.position = Vector2(x + 74, y + 30)
		note.size = Vector2(CELL_W - 90, 46)
		note.add_theme_font_size_override("font_size", 15)
		note.add_theme_color_override("font_color", Color(0.70, 0.67, 0.58))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		StoryDB.apply_serif(note)
		overlay.add_child(note)

	Modal.button(overlay, "返回", 520, 640, 240, 50, overlay.queue_free)

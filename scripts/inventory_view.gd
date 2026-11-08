extends Node

# ============================================================
# InventoryView —— 背包界面（掉落物 + 物品）
# ------------------------------------------------------------
# 和 DeckViewer 同一个套路：autoload，自己挂一个 CanvasLayer 200 的层。
# 左边掉落物、右边物品、下面详情；点左边/右边某一条会刷新详情。
#
# 按钮区会显示这一条「能做什么」：
#   掉落物：可合成清单（差什么也写出来）
#   物品： 用途说明（战斗使用 / 赠礼加好感 / 本局永久）
# ============================================================

var _layer: CanvasLayer
var _root: Control
var _detail: Label
var _detail_title: Label
var _list_boxes: Array[VBoxContainer] = []
var _head_labels: Array[Label] = []
var _scrolls: Array[ScrollContainer] = []


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 200
	add_child(_layer)


func is_open() -> bool:
	return _root != null and is_instance_valid(_root)


func close() -> void:
	if _root != null and is_instance_valid(_root):
		_root.queue_free()
	_root = null
	# 三个数组都要清：只清 _list_boxes 的话，重新 open 时
	# _head_labels[0] 还是上一轮已经被释放的 Label，写 text 会崩
	_list_boxes.clear()
	_head_labels.clear()
	_scrolls.clear()
	_detail = null
	_detail_title = null


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func open() -> void:
	# 不管当前状态，先彻底清一遍，避免拿到上一轮的失效引用
	close()

	_root = Control.new()
	_root.size = Vector2(1280, 720)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.94)
	dim.size = Vector2(1280, 720)
	_root.add_child(dim)

	var title := Label.new()
	title.text = "背 包"
	title.position = Vector2(0, 18)
	title.size = Vector2(1280, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.93, 0.87, 0.71))
	StoryDB.apply_serif(title)
	_root.add_child(title)

	# 左：掉落物　右：物品
	_build_column("掉 落 物", 70.0, 520.0, 104.0, 296.0)
	_build_column("物 品", 660.0, 520.0, 104.0, 296.0)

	# 下：详情
	var box := Panel.new()
	box.position = Vector2(70, 424)
	box.size = Vector2(1110, 210)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.11, 0.14, 0.96)
	ps.border_width_left = 1
	ps.border_width_right = 1
	ps.border_width_top = 1
	ps.border_width_bottom = 1
	ps.border_color = Color(0.55, 0.44, 0.24, 0.55)
	ps.set_corner_radius_all(4)
	box.add_theme_stylebox_override("panel", ps)
	_root.add_child(box)

	_detail_title = Label.new()
	_detail_title.position = Vector2(18, 12)
	_detail_title.size = Vector2(1074, 34)
	_detail_title.add_theme_font_size_override("font_size", 22)
	_detail_title.add_theme_color_override("font_color", Color(0.93, 0.87, 0.71))
	StoryDB.apply_serif(_detail_title)
	box.add_child(_detail_title)

	_detail = Label.new()
	_detail.position = Vector2(18, 52)
	_detail.size = Vector2(1074, 146)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 16)
	_detail.add_theme_color_override("font_color", Color(0.80, 0.76, 0.66))
	StoryDB.apply_serif(_detail)
	box.add_child(_detail)

	var close_btn := Button.new()
	close_btn.text = "关 闭"
	close_btn.position = Vector2(540, 650)
	close_btn.size = Vector2(200, 50)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(close)
	UiKit.ghost_button(close_btn, 20)
	_root.add_child(close_btn)

	_show_detail("", "")
	_refresh()


# 一列：标题 + 可滚动的条目列表
func _build_column(heading: String, x: float, w: float, y: float, h: float) -> void:
	var lab := Label.new()
	lab.text = heading
	lab.position = Vector2(x, y - 30)
	lab.size = Vector2(w, 26)
	lab.add_theme_font_size_override("font_size", 19)
	lab.add_theme_color_override("font_color", Color(0.85, 0.72, 0.45))
	StoryDB.apply_serif(lab)
	_root.add_child(lab)
	_head_labels.append(lab)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(x, y)
	scroll.size = Vector2(w, h)
	# 只做纵向滚动，横向关掉，免得列表左右晃
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_root.add_child(scroll)
	_scrolls.append(scroll)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	scroll.add_child(vb)
	_list_boxes.append(vb)


func _refresh() -> void:
	if _list_boxes.size() < 2:
		return
	var drops_box: VBoxContainer = _list_boxes[0]
	var items_box: VBoxContainer = _list_boxes[1]
	if not is_instance_valid(drops_box) or not is_instance_valid(items_box):
		return
	for c in drops_box.get_children():
		drops_box.remove_child(c)
		c.queue_free()
	for c in items_box.get_children():
		items_box.remove_child(c)
		c.queue_free()

	var drop_ids: Array = GameState.drops.keys()
	drop_ids.sort()
	if not _head_labels.is_empty() and is_instance_valid(_head_labels[0]):
		_head_labels[0].text = "掉 落 物（%d 种）%s" % [drop_ids.size(), "　▼ 可滚轮" if drop_ids.size() > 6 else ""]
	if drop_ids.is_empty():
		drops_box.add_child(_empty_label("还没有掉落物。\n打赢有掉落的敌人，或者去商店买。"))
	else:
		for id in drop_ids:
			var did := str(id)
			drops_box.add_child(_entry_button(
				"%s　×%d" % [DropDB.name_of(did), Inventory.drop_count(did)],
				func() -> void: _show_detail("drop", did)))

	var item_ids: Array = GameState.items.keys()
	item_ids.sort()
	if _head_labels.size() > 1 and is_instance_valid(_head_labels[1]):
		_head_labels[1].text = "物 品（%d 种）%s" % [item_ids.size(), "　▼ 可滚轮" if item_ids.size() > 6 else ""]
	if item_ids.is_empty():
		items_box.add_child(_empty_label("还没有物品。\n可以在休息处合成，或者去商店买。"))
	else:
		for id in item_ids:
			var iid := str(id)
			items_box.add_child(_entry_button(
				"%s　×%d" % [ItemDB.name_of(iid), Inventory.item_count(iid)],
				func() -> void: _show_detail("item", iid)))


func _empty_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(480, 60)
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.55, 0.53, 0.48))
	StoryDB.apply_serif(l)
	return l


func _entry_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(480, 46)
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 17)
	# PASS：自己收点击，同时把滚轮事件让给外面的 ScrollContainer
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.pressed.connect(cb)
	UiKit.ghost_button(b, 17)
	return b


# 详情面板：kind = "drop" / "item"，空字符串 = 提示
func _show_detail(kind: String, id: String) -> void:
	if _detail == null or not is_instance_valid(_detail):
		return
	if kind == "" or id == "":
		_detail_title.text = "选一项看详情"
		_detail.text = "左边是掉落物（合成的材料），右边是物品（能用的东西）。"
		return
	if kind == "drop":
		_detail_title.text = "%s　×%d" % [DropDB.name_of(id), Inventory.drop_count(id)]
		var lines: Array[String] = []
		lines.append(DropDB.desc_of(id))
		lines.append("")
		lines.append("来源：" + _drop_source_text(id))
		lines.append("卖价：%d 金" % DropDB.sell_price_of(id))
		var used_by := _recipes_using(id)
		if used_by.is_empty():
			lines.append("用途：暂时没有配方用到它。")
		else:
			lines.append("用途：可以合成 " + "、".join(used_by))
		_detail.text = "\n".join(lines)
		return
	# item
	_detail_title.text = "%s　×%d" % [ItemDB.name_of(id), Inventory.item_count(id)]
	var l2: Array[String] = []
	l2.append(ItemDB.desc_of(id))
	l2.append("")
	l2.append("用途：" + _item_use_text(id))
	var recipe: Dictionary = ItemDB.recipe_of(id)
	if not recipe.is_empty():
		var mats: Array[String] = []
		for mat in recipe:
			var need := int(recipe[mat])
			var have := Inventory.drop_count(str(mat))
			mats.append("%s×%d（有 %d）%s" % [
				DropDB.name_of(str(mat)), need, have, "" if have >= need else " 缺"])
		l2.append("配方：" + "、".join(mats))
	l2.append("卖价：%d 金" % int(floor(float(ItemDB.price_of(id)) / 3.0)))
	_detail.text = "\n".join(l2)


func _drop_source_text(id: String) -> String:
	var fe: Array = DropDB.info(id).get("from_enemy", [])
	if fe.is_empty():
		return "任何敌人 / 商店"
	return "击败 " + "、".join(fe)


func _recipes_using(drop_id: String) -> Array[String]:
	var out: Array[String] = []
	for item_id in ItemDB.RECIPES.keys():
		var recipe: Dictionary = ItemDB.RECIPES[item_id]
		if recipe.has(drop_id):
			out.append(ItemDB.name_of(str(item_id)))
	return out


func _item_use_text(id: String) -> String:
	var kind := ItemDB.kind_of(id)
	var mode := ItemDB.use_mode_of(id)
	if mode == "perm":
		return "拿到就永久生效（本局）"
	if kind == "battle":
		var spec: Dictionary = ItemDB.battle_spec(id)
		var parts: Array[String] = []
		if int(spec.get("damage", 0)) > 0:
			parts.append("造成 %d 伤害" % int(spec["damage"]))
		if int(spec.get("block", 0)) > 0:
			parts.append("获得 %d 格挡" % int(spec["block"]))
		if int(spec.get("heal", 0)) > 0:
			parts.append("回复 %d 生命" % int(spec["heal"]))
		var st: Dictionary = spec.get("status", {})
		if not st.is_empty():
			parts.append("给敌人挂 " + StatusSystem.text(st))
		var sst: Dictionary = spec.get("self_status", {})
		if not sst.is_empty():
			parts.append("自己获得 " + StatusSystem.text(sst))
		if parts.is_empty():
			parts.append("战斗中使用")
		var mode_txt := "一次性" if mode == "instant" else "可用 %d 次" % ItemDB.max_uses_of(id)
		return "战斗中%s：%s" % [mode_txt, "，".join(parts)]
	if kind == "hero":
		return "送给英雄，好感 +%d（%d 就能劝他退赛）" % [
			ItemDB.favor_of(id), ContestantDB.RETIRE_FAVOR]
	return "——"

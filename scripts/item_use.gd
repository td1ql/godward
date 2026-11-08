extends Node

# ============================================================
# ItemUse —— 战斗中使用物品
# ------------------------------------------------------------
# 由 battle_hud.gd 上的「物品」按钮调起。
# 物品表（ItemDB.ITEMS）为空时按钮不显示，所以这一层现在是完全静默的。
#
# 效果字段和卡牌一致，避免再学一套：
#   damage / block / heal / draw / gain_energy
#   status       挂给敌人
#   self_status  挂给自己
# ============================================================

const EnemyFx = preload("res://scripts/enemy_fx.gd")


# 把一个效果字典拍到当前战斗上
static func apply(b, spec: Dictionary) -> void:
	var dmg: int = int(spec.get("damage", 0))
	if dmg > 0:
		b.enemy.hp = max(0, b.enemy.hp - dmg)
		if b._enemy_sprite != null and is_instance_valid(b._enemy_sprite):
			EnemyFx.hit(b._enemy_sprite, dmg, dmg >= 15)
	var blk: int = int(spec.get("block", 0))
	if blk > 0:
		b.player_block += blk
	var heal: int = int(spec.get("heal", 0))
	if heal > 0:
		b.player_hp = mini(GameState.player_max_hp, b.player_hp + heal)
	var en: int = int(spec.get("gain_energy", 0))
	if en > 0:
		b.player_energy += en
	var st: Dictionary = spec.get("status", {})
	if not st.is_empty():
		StatusSystem.apply(b.enemy.status, st)
	var sst: Dictionary = spec.get("self_status", {})
	if not sst.is_empty():
		StatusSystem.apply(b.player_status, sst)
	var dr: int = int(spec.get("draw", 0))
	if dr > 0:
		b._draw_cards(dr)
	b._update_ui()


# 真正使用一件物品：扣次数、拍效果
static func use(b, item_id: String) -> bool:
	if Inventory.item_count(item_id) <= 0:
		return false
	if not ItemDB.can_use_in_battle(item_id):
		return false
	apply(b, ItemDB.battle_spec(item_id))
	Inventory.consume_use(item_id)
	Toast.show_text("用了 %s" % ItemDB.name_of(item_id))
	GameState.save_game()
	return true


# 打开选择面板（没有可用物品时返回 false，调用方可以给个提示）
static func open_picker(b) -> bool:
	var list := Inventory.battle_usable()
	if list.is_empty():
		return false
	var overlay := Modal.open(b, 0.82)
	Modal.title(overlay, "物 品", 90, 26)
	var i := 0
	for id in list:
		var item_id := str(id)
		var left := Inventory.uses_left(item_id)
		var label := "%s　（剩 %d 次）" % [ItemDB.name_of(item_id), left]
		var y := 170.0 + i * 62.0
		overlay.add_child(_item_button(b, overlay, label, item_id, y))
		i += 1
	var close := Modal.button(overlay, "不用了", 540, 170.0 + i * 62.0 + 10.0, 200, 48, func() -> void:
		overlay.queue_free())
	b._ghost_button(close, 18)
	return true


static func _item_button(b, overlay: Control, label: String, item_id: String, y: float) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.position = Vector2(390, y)
	btn.size = Vector2(500, 52)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func() -> void:
		overlay.queue_free()
		use(b, item_id)
		b._update_ui())
	b._ghost_button(btn, 18)
	return btn

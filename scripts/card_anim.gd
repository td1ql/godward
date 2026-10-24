class_name CardAnim
extends RefCounted

const DURATION := 0.36
const FADE := 0.22
const STAGGER := 0.07
const ORIGIN := Vector2(145, 646)

# 让 buttons 里最后 count 张牌从「牌堆」位置依次飞入
static func play(host: Node, buttons: Array, count: int) -> void:
	if count <= 0:
		return
	var start: int = max(0, buttons.size() - count)
	var k := 0
	for i in range(start, buttons.size()):
		var b = buttons[i]
		if b == null or not is_instance_valid(b):
			continue
		var target: Vector2 = b.position
		b.position = ORIGIN
		b.modulate.a = 0.0
		var delay := k * STAGGER
		k += 1
		var tw := host.create_tween().set_parallel(true)
		tw.tween_property(b, "position", target, DURATION).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "modulate:a", 1.0, FADE).set_delay(delay)

# 打出：飞向屏幕中央，放大，淡出
static func play_to_center(host: Node, btn: Control) -> void:
	if not _detach(host, btn):
		return
	var tx := 640.0 - btn.size.x / 2.0
	var ty := 330.0 - btn.size.y / 2.0
	var tw := host.create_tween().set_parallel(true)
	tw.tween_property(btn, "position", Vector2(tx, ty), 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.18, 1.18), 0.30)
	tw.tween_property(btn, "modulate:a", 0.0, 0.24).set_delay(0.16)
	tw.chain().tween_callback(btn.queue_free)

# 弃牌：飞向牌堆，缩小，淡出
static func discard_to(host: Node, btn: Control, target: Vector2) -> void:
	if not _detach(host, btn):
		return
	var tx := target.x - btn.size.x / 2.0
	var ty := target.y - btn.size.y / 2.0
	var tw := host.create_tween().set_parallel(true)
	tw.tween_property(btn, "position", Vector2(tx, ty), 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(btn, "scale", Vector2(0.55, 0.55), 0.26)
	tw.tween_property(btn, "modulate:a", 0.0, 0.20).set_delay(0.08)
	tw.chain().tween_callback(btn.queue_free)

static func _detach(host: Node, btn: Control) -> bool:
	if btn == null or not is_instance_valid(btn):
		return false
	var p := btn.get_parent()
	if p != null:
		p.remove_child(btn)
	host.add_child(btn)
	btn.pivot_offset = btn.size / 2.0
	btn.z_index = 60
	return true

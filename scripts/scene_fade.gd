extends CanvasLayer

## 场景切换的淡入淡出（全局 autoload，节点名 SceneFade）
## 用法：SceneFade.change_to("res://scenes/save_menu.tscn")

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 120                      # 盖在所有界面之上
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.016, 0.024, 0.031, 1.0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate = Color(1, 1, 1, 0)
	add_child(_rect)


## 淡出 → 切场景 → 淡入
func change_to(path: String) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	await tw.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame

	var tw2 := create_tween()
	tw2.tween_property(_rect, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE)
	await tw2.finished

	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


## 只淡入（新场景进入时用，可选）
func fade_in() -> void:
	_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE)

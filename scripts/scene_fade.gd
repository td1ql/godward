extends CanvasLayer

## 场景切换：水平滑动（旧的向左滑出，新的从右侧滑入）
## 用法：SceneFade.change_to("res://scenes/save_menu.tscn")
##
## 实现要点：
##   1. 切换前对当前画面做一次截图，铺在最上层当「旧场景」
##   2. 把新场景实例化后放进本层，先摆在屏幕右侧
##   3. 两条 Tween 同时跑：旧截图 x -1280 → 新场景 x 0
##   4. 动画结束后把截图删掉，把新场景从本层移到真正的场景树

const W := 1280.0
const DUR := 0.42

var _old: TextureRect
var _new_root: Node
var _busy := false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS


## 滑动切场景
func change_to(path: String) -> void:
	if _busy:
		return
	_busy = true

	# 1) 截当前画面
	var vp := get_viewport()
	var img: Image = vp.get_texture().get_image()
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_old = TextureRect.new()
	_old.texture = tex
	_old.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_old.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_old.size = Vector2(W, 720)
	_old.position = Vector2.ZERO
	_old.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_old)

	# 2) 实例化新场景，先放右侧
	var packed: PackedScene = load(path)
	if packed == null:
		_finish_immediate(path)
		return
	_new_root = packed.instantiate()
	add_child(_new_root)
	if _new_root is Node2D:
		(_new_root as Node2D).position.x = W
	elif _new_root is Control:
		(_new_root as Control).position.x = W

	# 3) 同时滑动
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_old, "position:x", -W, DUR).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if _new_root is Node2D:
		tw.tween_property(_new_root, "position:x", 0.0, DUR).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	elif _new_root is Control:
		tw.tween_property(_new_root, "position:x", 0.0, DUR).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

	# 4) 交接：把新场景挂到 current_scene 上，删掉截图
	var tree := get_tree()
	if _new_root != null and is_instance_valid(_new_root):
		remove_child(_new_root)
		tree.root.add_child(_new_root)
		tree.current_scene = _new_root
		if _new_root is Node2D:
			(_new_root as Node2D).position.x = 0
		elif _new_root is Control:
			(_new_root as Control).position.x = 0
	if _old != null and is_instance_valid(_old):
		_old.queue_free()
		_old = null
	_new_root = null
	_busy = false


## 兜底：直接切（截图失败或资源缺失时）
func _finish_immediate(path: String) -> void:
	if _old != null and is_instance_valid(_old):
		_old.queue_free()
		_old = null
	get_tree().change_scene_to_file(path)
	_busy = false


## 只做淡入（新场景首次进入时可选）
func fade_in() -> void:
	var r := ColorRect.new()
	r.color = Color(0.016, 0.024, 0.031, 1.0)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	await tw.finished
	r.queue_free()

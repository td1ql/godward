extends Node
# 战斗界面搭建（阶段 A：从 battle_demo.gd 的 _ready 拆出）
# 只负责创建 HUD 节点、挂到 battle 实例上，不处理任何回合流程。
# 约定：跨文件引用一律 preload 常量，不使用 class_name。

const ArtFrame = preload("res://scripts/art_frame.gd")
const ArkPanel = preload("res://scripts/ark_panel.gd")

const GOD_BG := {
	"奥丁": "res://assets/art/bg/bg_battle_odin.webp",
	"赫尔墨斯": "res://assets/art/bg/bg_battle_hermes.webp",
	"阿斯克勒庇俄斯": "res://assets/art/bg/bg_battle_asclepius.webp",
	"赫菲斯托斯": "res://assets/art/bg/bg_battle_hephaestus.webp",
	"耶梦加得": "res://assets/art/bg/bg_battle_3_boss.webp",
}

# b 是 battle_demo.gd 的实例（不写死类型，避免跨脚本的静态类型依赖）
static func build(b) -> void:
	_build_bg(b)
	_build_frames(b)
	_build_bars(b)
	_build_dim(b)
	_build_hand(b)
	_build_turn_button(b)
	_build_skill_button(b)
	_build_labels(b)
	_build_sprites(b)
	_build_toolbar(b)

# 这些敌人的形象直接画在战斗背景里，不再叠立绘
static func shown_in_bg(b) -> bool:
	if str(b.enemy.label_name) == "世界树":
		return true
	return GOD_BG.has(str(b.enemy.label_name))

static func _build_bg(b) -> void:
	var act_pool: Array = [1, 2, 3] if GameState.act >= 2 else [1, 2, 3, 4, 5]
	act_pool.shuffle()
	var bg_path := "res://assets/art/bg/bg_battle_%d_%d.webp" % [GameState.act, act_pool[0]]
	if str(GameState.pending_snapshot.get("kind", "")) == "tutorial":
		bg_path = "res://assets/art/bg/bg_battle_tut.webp"
	if str(GameState.pending_snapshot.get("kind", "")) == "battle":
		var pn: String = str(GameState.pending_snapshot.get("node_type", ""))
		if pn == "serpent":
			bg_path = "res://assets/art/bg/bg_battle_3_boss.webp"
		elif pn == "tree":
			bg_path = "res://assets/art/bg/bg_battle_tree.webp"
		elif pn == "god":
			bg_path = "res://assets/art/bg/bg_battle_3_boss.webp"
	# 兜底：按敌人名字认特殊背景
	var en: String = str(GameState.pending_enemy.get("name", ""))
	if GOD_BG.has(en):
		var gb: String = str(GOD_BG[en])
		if ResourceLoader.exists(gb):
			bg_path = gb
	elif en == "世界树":
		bg_path = "res://assets/art/bg/bg_battle_tree.webp"
	if not ResourceLoader.exists(bg_path):
		bg_path = "res://assets/art/bg/bg_battle_%d.webp" % randi_range(1, 5)
	if ResourceLoader.exists(bg_path):
		var bgr := TextureRect.new()
		bgr.texture = load(bg_path)
		bgr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bgr.stretch_mode = TextureRect.STRETCH_SCALE
		bgr.size = Vector2(1280, 720)
		b.add_child(bgr)
		bgr.z_index = -10
	else:
		var fb := ColorRect.new()
		fb.color = Color(0.05, 0.06, 0.09)
		fb.size = Vector2(1280, 720)
		b.add_child(fb)

static func _build_frames(b) -> void:
	# 左上/右上信息块的暗底（必须在所有标签之前加，否则会被标签或背景盖住）
	var lp := ArkPanel.new()
	lp.position = Vector2(40, 30)
	lp.size = Vector2(206, 250)
	lp.cut = 18.0
	lp.z_index = 1
	lp.alpha = 0.86
	b.add_child(lp)
	var rp := ArkPanel.new()
	b._info_strip = rp
	rp.position = Vector2(966, 86)
	rp.size = Vector2(300, 124)
	rp.cut = 14.0
	rp.z_index = 1
	rp.alpha = 0.86
	b.add_child(rp)

static func _build_bars(b) -> void:
	# 玩家格挡白条（在血条上面一层）
	b._block_bar_bg = ColorRect.new()
	b._block_bar_bg.color = Color(0.85, 0.85, 0.85, 0.16)
	b._block_bar_bg.position = Vector2(56, 140)
	b._block_bar_bg.size = Vector2(180, 5)
	b._block_bar_bg.z_index = 2
	b._block_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(b._block_bar_bg)
	b._block_bar = ColorRect.new()
	b._block_bar.color = Color(0.96, 0.96, 0.92, 0.92)
	b._block_bar.position = Vector2(56, 140)
	b._block_bar.size = Vector2(0, 5)
	b._block_bar.z_index = 2
	b._block_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(b._block_bar)

	# 敌人格挡白条
	b._eblock_bar_bg = ColorRect.new()
	b._eblock_bar_bg.color = Color(0.85, 0.85, 0.85, 0.16)
	b._eblock_bar_bg.position = Vector2(860, 140)
	b._eblock_bar_bg.size = Vector2(276, 4)
	b._eblock_bar_bg.z_index = 2
	b._eblock_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(b._eblock_bar_bg)
	b._eblock_bar = ColorRect.new()
	b._eblock_bar.color = Color(0.96, 0.96, 0.92, 0.92)
	b._eblock_bar.position = Vector2(860, 140)
	b._eblock_bar.size = Vector2(0, 5)
	b._eblock_bar.z_index = 2
	b._eblock_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(b._eblock_bar)

	# 玩家血条（放到底层，避免盖住文字）
	b._hp_bar_bg = ColorRect.new()
	b._hp_bar_bg.z_index = 2
	b._hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b._hp_bar_bg.color = Color(0.72, 0.60, 0.36, 0.18)
	b._hp_bar_bg.position = Vector2(56, 148)
	b._hp_bar_bg.size = Vector2(180, 6)
	b.add_child(b._hp_bar_bg)
	b._hp_bar = ColorRect.new()
	b._hp_bar.z_index = 2
	b._hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b._hp_bar.color = Color(0.88, 0.74, 0.42)
	b._hp_bar.position = Vector2(56, 148)
	b._hp_bar.size = Vector2(180, 6)
	b.add_child(b._hp_bar)

	# 敌人血条
	b._ehp_bar_bg = ColorRect.new()
	b._ehp_bar_bg.z_index = 2
	b._ehp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b._ehp_bar_bg.color = Color(0.72, 0.60, 0.36, 0.18)
	b._ehp_bar_bg.position = Vector2(978, 116)
	b._ehp_bar_bg.size = Vector2(276, 5)
	b.add_child(b._ehp_bar_bg)
	b._ehp_bar = ColorRect.new()
	b._ehp_bar.z_index = 2
	b._ehp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b._ehp_bar.color = Color(0.80, 0.35, 0.30)
	b._ehp_bar.position = Vector2(978, 116)
	b._ehp_bar.size = Vector2(230, 6)
	b.add_child(b._ehp_bar)

static func _build_dim(b) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.07, 0.38)
	dim.size = Vector2(1280, 720)
	b.add_child(dim)
	b.move_child(dim, 1)

static func _build_hand(b) -> void:
	b.hand_view = HandView.new()
	# 手牌永远压在敌人立绘之上
	b.hand_view.z_index = 8
	b.add_child(b.hand_view)
	b.hand_view.card_pressed.connect(b._on_card_pressed)

static func _build_turn_button(b) -> void:
	# 把结束回合按钮搬到一个高层 CanvasLayer：CanvasLayer 的层级比 z_index 更硬，
	# 不会再被任何同场景的 Control 挡住（只影响按钮，不影响其它 HUD）
	var end_turn_button: Button = b.end_turn_button
	if end_turn_button.get_parent() == b:
		b.remove_child(end_turn_button)
		var btn_layer := CanvasLayer.new()
		btn_layer.layer = 30
		b.add_child(btn_layer)
		btn_layer.add_child(end_turn_button)
		b._skill_btn_layer = btn_layer
	end_turn_button.position = Vector2(1080, 652)
	end_turn_button.size = Vector2(180, 40)
	end_turn_button.add_theme_font_size_override("font_size", 22)
	end_turn_button.add_theme_constant_override("outline_size", 2)
	end_turn_button.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	end_turn_button.pressed.connect(b._on_end_turn_pressed)
	end_turn_button.z_index = 10

static func _build_skill_button(b) -> void:
	# 职业技能按钮
	b._skill_btn = Button.new()
	b._skill_btn.visible = false   # 由 _refresh_skill_btn 决定
	b._skill_btn.z_index = 6
	b._skill_btn.position = Vector2(14, 596)
	b._skill_btn.size = Vector2(196, 46)
	b._skill_btn.focus_mode = Control.FOCUS_NONE
	b._skill_btn.add_theme_font_size_override("font_size", 15)
	b._skill_btn.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	b._skill_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.7))
	StoryDB.apply_serif(b._skill_btn)
	var sk := StyleBoxFlat.new()
	sk.bg_color = Color(0.09, 0.06, 0.02, 0.92)
	sk.border_color = Color(0.88, 0.70, 0.35, 0.90)
	sk.set_border_width_all(1)
	b._skill_btn.add_theme_stylebox_override("normal", sk)
	var skh := sk.duplicate()
	skh.bg_color = Color(0.85, 0.66, 0.30, 0.22)
	b._skill_btn.add_theme_stylebox_override("hover", skh)
	b._skill_btn.add_theme_stylebox_override("pressed", skh)
	b._skill_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b._skill_btn.pressed.connect(b._on_skill_pressed)
	b._skill_btn_layer.add_child(b._skill_btn)

static func _build_labels(b) -> void:
	# 能量：放在手牌左边
	var info_label: Label = b.info_label
	info_label.position = Vector2(22, 400)
	info_label.z_index = 5
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_label.size = Vector2(150, 46)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 26)
	info_label.add_theme_color_override("font_color", Color(0.93, 0.87, 0.71))
	info_label.add_theme_constant_override("outline_size", 2)
	info_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))

	# 牌堆计数：屏幕正下方
	b.pile_label = Label.new()
	b.pile_label.position = Vector2(0, 652)
	b.pile_label.z_index = 5
	b.pile_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.pile_label.size = Vector2(1280, 40)
	b.pile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.pile_label.add_theme_font_size_override("font_size", 20)
	b.pile_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.72))
	# 用描边假装加粗
	b.pile_label.add_theme_constant_override("outline_size", 3)
	b.pile_label.add_theme_color_override("font_outline_color", Color(0.10, 0.09, 0.08))
	StoryDB.apply_serif(b.pile_label)
	b.add_child(b.pile_label)

	b.player_label = Label.new()
	b.player_label.position = Vector2(54, 40)
	b.player_label.size = Vector2(188, 190)
	b.player_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.player_label.add_theme_font_size_override("font_size", 19)
	b.player_label.add_theme_constant_override("outline_size", 2)
	b.player_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	b.player_label.z_index = 5
	b.player_label.add_theme_constant_override("line_spacing", -6)
	b.player_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.player_label.add_theme_color_override("font_color", Color(0.93, 0.88, 0.78))
	b.add_child(b.player_label)

	var combat_label: Label = b.combat_label
	combat_label.position = Vector2(974, 90)
	combat_label.size = Vector2(286, 24)
	combat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	combat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_label.add_theme_font_size_override("font_size", 18)
	combat_label.add_theme_constant_override("outline_size", 2)
	combat_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	b._info_name = combat_label
	combat_label.z_index = 5
	combat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_label.add_theme_color_override("font_color", Color(0.93, 0.88, 0.78))

	# 血条下面的状态 / 意图
	b.player_detail_label = Label.new()
	b.player_detail_label.position = Vector2(54, 172)
	b.player_detail_label.size = Vector2(188, 70)
	b.player_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.player_detail_label.add_theme_font_size_override("font_size", 16)
	b.player_detail_label.add_theme_color_override("font_color", Color(0.82, 0.74, 0.52))
	b.player_detail_label.add_theme_constant_override("outline_size", 2)
	b.player_detail_label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.04))
	b.player_detail_label.z_index = 5
	b.player_detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StoryDB.apply_serif(b.player_detail_label)
	b.add_child(b.player_detail_label)

	b.enemy_detail_label = Label.new()
	b.enemy_detail_label.position = Vector2(974, 122)
	b.enemy_detail_label.size = Vector2(286, 20)
	b.enemy_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.enemy_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.enemy_detail_label.add_theme_font_size_override("font_size", 13)
	b.enemy_detail_label.add_theme_color_override("font_color", Color(0.85, 0.72, 0.55))
	b.enemy_detail_label.add_theme_constant_override("outline_size", 2)
	b.enemy_detail_label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.04))
	b._info_detail = b.enemy_detail_label
	b.enemy_detail_label.z_index = 5
	b.enemy_detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StoryDB.apply_serif(b.enemy_detail_label)
	b.add_child(b.enemy_detail_label)

	# 意图：单独一条，挂在信息条最上方（类型 + 数值 + 附加效果，颜色表示危险度）
	b._intent_label = Label.new()
	b._intent_label.position = Vector2(974, 88)
	b._intent_label.size = Vector2(286, 26)
	b._intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b._intent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b._intent_label.add_theme_font_size_override("font_size", 18)
	b._intent_label.add_theme_color_override("font_color", Color(0.84, 0.72, 0.50))
	b._intent_label.add_theme_constant_override("outline_size", 3)
	b._intent_label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.04))
	b._intent_label.z_index = 6
	b._intent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b._intent_label.clip_text = true
	b._intent_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	StoryDB.apply_serif(b._intent_label)
	b.add_child(b._intent_label)

	# 意图的第二行：本回合会附加什么（给你挂状态 / 自己强化 / 回血）
	b._intent_sub = Label.new()
	b._intent_sub.position = Vector2(974, 112)
	b._intent_sub.size = Vector2(286, 18)
	b._intent_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b._intent_sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b._intent_sub.add_theme_font_size_override("font_size", 13)
	b._intent_sub.add_theme_color_override("font_color", Color(0.72, 0.66, 0.54))
	b._intent_sub.add_theme_constant_override("outline_size", 2)
	b._intent_sub.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.04))
	b._intent_sub.z_index = 6
	b._intent_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b._intent_sub.clip_text = true
	b._intent_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	StoryDB.apply_serif(b._intent_sub)
	b.add_child(b._intent_sub)

	# 领域单独一条：挂在敌人脚下（不挤在头顶信息条里）
	b._domain_label = Label.new()
	b._domain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b._domain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b._domain_label.add_theme_font_size_override("font_size", 14)
	b._domain_label.add_theme_color_override("font_color", Color(0.83, 0.68, 0.42))
	b._domain_label.add_theme_constant_override("outline_size", 3)
	b._domain_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.08, 0.9))
	b._domain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b._domain_label.z_index = 5
	StoryDB.apply_serif(b._domain_label)
	b.add_child(b._domain_label)

	# 状态：显示在立绘正下方
	b.status_label = Label.new()
	b.status_label.position = Vector2(48, 250)
	b.status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.status_label.size = Vector2(200, 96)
	b.status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.status_label.add_theme_font_size_override("font_size", 17)
	b.status_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	b.status_label.add_theme_constant_override("outline_size", 2)
	b.status_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	StoryDB.apply_serif(b.status_label)
	b.add_child(b.status_label)

	b.ally_label = Label.new()
	b.ally_label.position = Vector2(14, 400)
	b.ally_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.ally_label.size = Vector2(520, 120)
	b.ally_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.ally_label.add_theme_font_size_override("font_size", 16)
	b.ally_label.add_theme_constant_override("outline_size", 2)
	b.ally_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	b.ally_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	b.add_child(b.ally_label)

static func _build_sprites(b) -> void:
	var sil: String = EnemyDB.silhouette_of(str(b.enemy.label_name))
	var boss_bg := shown_in_bg(b)
	# 新立绘：透明 PNG（自带地面阴影），底对齐同一条地面线
	var sil_path := "res://assets/art/enemy_cut/%s.png" % sil
	if not boss_bg and ResourceLoader.exists(sil_path):
		var tex: Texture2D = load(sil_path)
		var spr := TextureRect.new()
		b._enemy_sprite = spr
		spr.texture = tex
		spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# 按高度缩放（最大 420），宽度按比例
		var max_h := 360.0
		var ratio := max_h / float(tex.get_height())
		var draw_w := float(tex.get_width()) * ratio
		spr.size = Vector2(draw_w, max_h)
		spr.pivot_offset = spr.size / 2.0
		spr.z_index = 2
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spr.modulate = Color(1, 1, 1, 0.97)
		b.add_child(spr)
		# 底对齐 y=560，水平居中在 x=1150
		spr.position = Vector2(1078.0 - draw_w * 0.5, 566.0 - max_h)
		b.call_deferred("EmFx_appear")
		# 极缓慢的呼吸浮动
		var tw: Tween = b.create_tween().set_loops()
		tw.tween_property(spr, "position:y", spr.position.y - 5.0, 3.0).set_trans(Tween.TRANS_SINE)
		tw.tween_property(spr, "position:y", spr.position.y, 3.0).set_trans(Tween.TRANS_SINE)

	var voc_path := "res://assets/art/vocation/%s.webp" % GameState.vocation
	if ResourceLoader.exists(voc_path):
		var pc := TextureRect.new()
		b._player_sprite = pc
		pc.texture = load(voc_path)
		pc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pc.position = Vector2(252, 30)
		pc.size = Vector2(150, 200)
		pc.z_index = 2
		pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pc)
		var pf := ArtFrame.make(Rect2(0, 0, 150, 200), 0.55, 0.28)
		pf.corner = 16.0
		pc.add_child(pf)

static func _build_toolbar(b) -> void:
	var deck_btn := Button.new()
	deck_btn.text = StoryDB.t("battle_deck")
	deck_btn.position = Vector2(20, 652)
	deck_btn.size = Vector2(110, 40)
	deck_btn.pressed.connect(DeckViewer.toggle)
	deck_btn.add_theme_font_size_override("font_size", 20)
	deck_btn.add_theme_constant_override("outline_size", 2)
	deck_btn.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	b.add_child(deck_btn)
	var pile_btn := Button.new()
	pile_btn.text = StoryDB.t("battle_piles")
	pile_btn.position = Vector2(140, 652)
	pile_btn.size = Vector2(110, 40)
	pile_btn.pressed.connect(b._open_piles)
	pile_btn.add_theme_font_size_override("font_size", 20)
	pile_btn.add_theme_constant_override("outline_size", 2)
	pile_btn.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	b.add_child(pile_btn)

	# 物品：背包里有战斗可用的东西才显示（物品表为空时永远不出现）
	b._item_btn = Button.new()
	b._item_btn.text = "物 品"
	b._item_btn.position = Vector2(260, 652)
	b._item_btn.size = Vector2(110, 40)
	b._item_btn.pressed.connect(b._open_items)
	b._item_btn.add_theme_font_size_override("font_size", 20)
	b._item_btn.add_theme_constant_override("outline_size", 2)
	b._item_btn.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	b._item_btn.visible = false
	b.add_child(b._item_btn)
	if b.node_type != "tutorial":
		var menu_btn := Button.new()
		menu_btn.text = "≡"
		menu_btn.position = Vector2(1228, 14)
		menu_btn.size = Vector2(40, 40)
		menu_btn.add_theme_font_size_override("font_size", 26)
		menu_btn.focus_mode = Control.FOCUS_NONE
		menu_btn.tooltip_text = "菜单"
		menu_btn.pressed.connect(b._open_battle_menu)
		b.add_child(menu_btn)
		UiKit.ghost_button(menu_btn, 26)

	UiKit.ghost_button(deck_btn)
	UiKit.ghost_button(pile_btn)
	UiKit.ghost_button(b.end_turn_button, 26)


# ============================================================
# 敌人意图：类型判定 / 文本 / 颜色
# ------------------------------------------------------------
# 数据模型：敌人每回合必打，pattern 是这一回合的倍率；
# skills 里 every=N 的项在本回合触发（给玩家挂状态 = 削弱，
# 给自己挂状态 = 强化，heal = 自愈）。
# 所以「类型」= 倍率档位（重击 / 攻击 / 轻击）+ 本回合的附加效果。
# ============================================================

static func intent_info(b) -> Dictionary:
	var e = b.enemy
	var mult := 1.0
	if not e.pattern.is_empty():
		mult = float(e.pattern[e.turn_index % e.pattern.size()])
	var dmg: int = DamageCalc.compute(e.intent_damage(), e.status, b.player_status)

	var tier := "normal"
	var word := "攻击"
	if mult >= 2.0:
		tier = "heavy"
		word = "重击"
	elif mult <= 0.5:
		tier = "light"
		word = "轻击"

	var subs: Array[String] = []
	var has_buff := false
	var has_debuff := false
	var heal := 0
	# 注意：敌人回合结算是「先 turn_index += 1，再判 due_skills」
	# （battle_flow.gd:371 → :396）。玩家在回合开始时看到的意图，对应的是
	# 结算时 turn_index + 1 的状态，所以这里必须用 +1 去算，否则会差一回合。
	for s in e.skills:
		var every: int = max(1, int(s.get("every", 1)))
		if (e.turn_index + 1) % every != 0:
			continue
		var h: int = int(s.get("heal", 0))
		if h > 0:
			heal += h
			subs.append("自己回血%d" % h)
			continue
		var st: Dictionary = s.get("status", {})
		var txt: String = StatusSystem.text(st)
		if txt == "":
			continue
		if str(s.get("to", "")) == "self":
			has_buff = true
			subs.append("自己" + txt)
		else:
			has_debuff = true
			subs.append("给你" + txt)

	var hit_extra: String = StatusSystem.text(e.on_hit)
	if hit_extra != "":
		has_debuff = true
		subs.append("附带" + hit_extra)

	# 每回合自动生效的（如断头骑士每回合 +1 力量）—— 放在最前，因为它解释「数字为什么在涨」
	var turn_st: String = StatusSystem.text(e.on_turn)
	if turn_st != "":
		has_buff = true
		subs.push_front("每回合" + turn_st)

	# 最多展示 4 项，多出来的折成「等N项」，避免一行放不下
	if subs.size() > 4:
		var extra: int = subs.size() - 3
		subs = [subs[0], subs[1], subs[2], "等%d项" % extra]

	return {
		"tier": tier,
		"word": word,
		"damage": dmg,
		"subs": subs,
		"buff": has_buff,
		"debuff": has_debuff,
		"heal": heal,
	}


static func intent_text(b) -> String:
	var i: Dictionary = intent_info(b)
	return "意图　%s %d" % [str(i["word"]), int(i["damage"])]


static func intent_sub_text(b) -> String:
	var i: Dictionary = intent_info(b)
	var subs: Array = i["subs"]
	if subs.is_empty():
		return ""
	var joined := ""
	for k in range(subs.size()):
		if k > 0:
			joined += "、"
		joined += str(subs[k])
	return joined


static func intent_color(b) -> Color:
	var i: Dictionary = intent_info(b)
	# 危险度优先：数字越大越红，玩家第一眼看到的是「这回合疼不疼」
	var dmg: int = int(i["damage"])
	if dmg >= 18:
		return Color(0.95, 0.36, 0.28)
	if dmg >= 9:
		return Color(0.94, 0.60, 0.30)
	if str(i["tier"]) == "light":
		return Color(0.66, 0.63, 0.56)
	if int(i["heal"]) > 0:
		return Color(0.52, 0.80, 0.46)
	if bool(i["buff"]):
		return Color(0.90, 0.78, 0.34)
	return Color(0.84, 0.72, 0.50)

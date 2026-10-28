extends Node2D

const ArtFrame = preload("res://scripts/art_frame.gd")

const BLOCK_DAMAGE_CAP := 60

var deck := Deck.new()
var hand_view: HandView
var player_label: Label
var ally_label: Label
var pile_label: Label
var status_label: Label
var ally_fighters: Array = []
var enemy := EnemyState.new()


var player_hp := 0
var player_block := 0
var player_energy := 0
var player_status := {}

var node_type := "battle"
var game_over := false
var last_gold_gain := 0

var pending_effect := -1
var pending_need := 0
var pending_selected: Array = []
var _draw_depth := 0
var max_energy: int = RunConfig.MAX_ENERGY
var battle_uses := {}
var creed := {}
var first_attack_used := false
var first_card_used := false
var _ending_turn := false
var attacked_last_turn := false
var attacked_this_turn := false
var first_hurt_used := false
var damage_taken := 0
var bonus_energy := 0
var last_card_played := ""
var enemy_organ := ""
var _first_clear := false
var _kill_pick_pending := false
var skip_enemy := 0
var _new_cards := 0

@onready var info_label: Label = $InfoLabel
@onready var combat_label: Label = $CombatLabel
@onready var end_turn_button: Button = $EndTurnButton


const GOD_BG := {
	"奥丁": "res://assets/art/bg/bg_battle_odin.webp",
	"赫尔墨斯": "res://assets/art/bg/bg_battle_hermes.webp",
	"阿斯克勒庇俄斯": "res://assets/art/bg/bg_battle_asclepius.webp",
	"赫菲斯托斯": "res://assets/art/bg/bg_battle_hephaestus.webp",
	"耶梦加得": "res://assets/art/bg/bg_battle_3_boss.webp",
}

func _is_shown_in_bg() -> bool:
	# 这些敌人的形象直接画在战斗背景里，不再叠立绘
	if str(enemy.label_name) == "世界树":
		return true
	return GOD_BG.has(str(enemy.label_name))

func _ready() -> void:
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
		add_child(bgr)
		move_child(bgr, 0)
	else:
		var fb := ColorRect.new()
		fb.color = Color(0.05, 0.06, 0.09)
		fb.size = Vector2(1280, 720)
		add_child(fb)

	# 左上/右上信息块的暗底（必须在所有标签之前加，否则会被标签或背景盖住）
	_backing(Vector2(40, 20), Vector2(212, 330))
	_backing(Vector2(840, 20), Vector2(272, 330), true)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.07, 0.38)
	dim.size = Vector2(1280, 720)
	add_child(dim)
	move_child(dim, 1)

	var kind: String = str(GameState.pending_snapshot.get("kind", ""))
	var tutorial := kind == "tutorial"

	if tutorial:
		player_hp = 30
		max_energy = 3
		player_energy = 3
	else:
		player_hp = GameState.player_hp
		max_energy = GameState.initial_energy()
		player_energy = max_energy
		creed = TraitDB.creed_of(GameState.vocation)
		var bonus_strength: int = TraitDB.total_strength(GameState.traits)
		if bonus_strength != 0:
			player_status["力量"] = bonus_strength
	if str(creed.get("key", "")) == "keep_block":
		player_status["坚守"] = 1

	node_type = "battle"
	if GameState.pending_snapshot.has("node_type"):
		node_type = str(GameState.pending_snapshot["node_type"])
	elif tutorial:
		node_type = "tutorial"
	elif GameState.map_nodes.has(GameState.current_node_id):
		node_type = GameState.map_nodes[GameState.current_node_id]["type"]
	if kind == "pope":
		node_type = "pope"

	var enemy_data: Dictionary
	if tutorial:
		enemy_data = Tutorial.ENEMY.duplicate(true)
		Tutorial.start()
		player_status["恒光"] = 1
	elif kind == "battle" or kind == "contestant_fight" or kind == "pope":
		enemy_data = GameState.pending_snapshot["enemy"]
	elif not GameState.pending_enemy.is_empty():
		enemy_data = GameState.pending_enemy
		GameState.pending_enemy = {}
	else:
		enemy_data = EnemyDB.pick_for_node(node_type)
	enemy.setup(enemy_data)
	enemy_organ = str(enemy_data.get("organ", ""))
	
	if str(enemy.domain.get("type", "")) == "thorns_aura":
		enemy.status["荆棘"] = int(enemy.status.get("荆棘", 0)) + int(enemy.domain.get("value", 0))

	if not tutorial:
		deck.setup(GameState.deck)
	else:
		deck.setup(GameState.deck)

	hand_view = HandView.new()
	add_child(hand_view)
	hand_view.card_pressed.connect(_on_card_pressed)

	end_turn_button.position = Vector2(1080, 652)
	end_turn_button.size = Vector2(180, 40)
	end_turn_button.add_theme_font_size_override("font_size", 22)
	end_turn_button.add_theme_constant_override("outline_size", 2)
	end_turn_button.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	player_label = Label.new()
	# 能量：放在手牌左边
	info_label.position = Vector2(22, 400)
	info_label.size = Vector2(150, 46)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 26)
	info_label.add_theme_color_override("font_color", Color(0.93, 0.87, 0.71))
	info_label.add_theme_constant_override("outline_size", 2)
	info_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))

	# 牌堆计数：屏幕正下方
	pile_label = Label.new()
	pile_label.position = Vector2(0, 652)
	pile_label.size = Vector2(1280, 40)
	pile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pile_label.add_theme_font_size_override("font_size", 20)
	pile_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.72))
	# 用描边假装加粗
	pile_label.add_theme_constant_override("outline_size", 3)
	pile_label.add_theme_color_override("font_outline_color", Color(0.10, 0.09, 0.08))
	StoryDB.apply_serif(pile_label)
	add_child(pile_label)

	player_label.position = Vector2(52, 30)
	player_label.size = Vector2(196, 300)
	player_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_label.position = Vector2(852, 30)
	combat_label.size = Vector2(248, 300)
	combat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combat_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	combat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_label.add_theme_font_size_override("font_size", 19)
	combat_label.add_theme_constant_override("outline_size", 2)
	combat_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	player_label.add_theme_font_size_override("font_size", 19)
	player_label.add_theme_constant_override("outline_size", 2)
	player_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	add_child(player_label)
	var sil: String = EnemyDB.silhouette_of(str(enemy.label_name))
	var boss_bg := _is_shown_in_bg()
	var sil_path := "res://assets/art/enemy/%s.webp" % sil
	if not boss_bg and ResourceLoader.exists(sil_path):
		var spr := TextureRect.new()
		spr.texture = load(sil_path)
		spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		spr.position = Vector2(1106, 30)
		spr.size = Vector2(150, 200)
		spr.modulate = Color(1, 1, 1, 0.92)
		add_child(spr)
		var ef := ArtFrame.make(Rect2(1106, 30, 150, 200), 0.45, 0.22)
		ef.corner = 16.0
		add_child(ef)
		spr.pivot_offset = spr.size / 2.0
		var tw := create_tween().set_loops()
		tw.set_parallel(true)
		tw.tween_property(spr, "scale", Vector2(1.02, 1.02), 2.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(spr, "position:y", spr.position.y - 4.0, 2.6).set_trans(Tween.TRANS_SINE)
		tw.chain()
		tw.set_parallel(true)
		tw.tween_property(spr, "scale", Vector2(1.0, 1.0), 2.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(spr, "position:y", spr.position.y, 2.6).set_trans(Tween.TRANS_SINE)

	var voc_path := "res://assets/art/vocation/%s.webp" % GameState.vocation
	if ResourceLoader.exists(voc_path):
		var pc := TextureRect.new()
		pc.texture = load(voc_path)
		pc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pc.position = Vector2(252, 30)
		pc.size = Vector2(150, 200)
		add_child(pc)
		var pf := ArtFrame.make(Rect2(252, 30, 150, 200), 0.45, 0.22)
		pf.corner = 16.0
		add_child(pf)

	# 状态：显示在立绘正下方
	status_label = Label.new()
	status_label.position = Vector2(48, 250)
	status_label.size = Vector2(200, 96)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	status_label.add_theme_constant_override("outline_size", 2)
	status_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	StoryDB.apply_serif(status_label)
	add_child(status_label)

	ally_label = Label.new()
	ally_label.position = Vector2(14, 400)
	ally_label.size = Vector2(520, 120)
	ally_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ally_label.add_theme_font_size_override("font_size", 16)
	ally_label.add_theme_constant_override("outline_size", 2)
	ally_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	ally_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	add_child(ally_label)
	var deck_btn := Button.new()
	deck_btn.text = StoryDB.t("battle_deck")
	deck_btn.position = Vector2(20, 652)
	deck_btn.size = Vector2(110, 40)
	deck_btn.pressed.connect(DeckViewer.toggle)
	deck_btn.add_theme_font_size_override("font_size", 20)
	deck_btn.add_theme_constant_override("outline_size", 2)
	deck_btn.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	add_child(deck_btn)
	var pile_btn := Button.new()
	pile_btn.text = StoryDB.t("battle_piles")
	pile_btn.position = Vector2(140, 652)
	pile_btn.size = Vector2(110, 40)
	pile_btn.pressed.connect(_open_piles)
	pile_btn.add_theme_font_size_override("font_size", 20)
	pile_btn.add_theme_constant_override("outline_size", 2)
	pile_btn.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	add_child(pile_btn)
	if not tutorial:
		var menu_btn := Button.new()
		menu_btn.text = "≡"
		menu_btn.position = Vector2(1228, 14)
		menu_btn.size = Vector2(40, 40)
		menu_btn.add_theme_font_size_override("font_size", 26)
		menu_btn.focus_mode = Control.FOCUS_NONE
		menu_btn.tooltip_text = "菜单"
		menu_btn.pressed.connect(_open_battle_menu)
		add_child(menu_btn)
		_ghost_button(menu_btn, 26)

	_ghost_button(deck_btn)
	_ghost_button(pile_btn)
	_ghost_button(end_turn_button, 26)
	var resume: Dictionary = GameState.pending_snapshot.get("resume", {})
	if not resume.is_empty():
		_restore_battle(resume)
	elif tutorial:
		deck.draw_pile.clear()
		deck.hand.clear()
		deck.discard_pile.clear()
		for c in Tutorial.cards_for(0):
			deck.hand.append(str(c))
		_new_cards = deck.hand.size()
		_apply_turn_creed()
	else:
		var extra_draw := 0
		if str(creed.get("key", "")) == "start_draw":
			extra_draw = int(creed.get("value", 0))
		# 第 1 回合：固定 5 张（+ 敏锐/起手加成），不走 BASE_DRAW + 剩余能量
		_draw_cards(GameState.initial_hand_size() + extra_draw)
		_apply_turn_creed()
	var organ_heal := OrganDB.total("start_heal")
	if organ_heal > 0:
		player_hp = min(GameState.player_max_hp, player_hp + organ_heal)
	if node_type in ["boss", "pope", "tree", "serpent"]:
		_setup_allies()
	_render_hand()
	_update_ui()
	var boss_nodes := ["boss", "pope", "tree", "serpent", "god", "divine_elite"]
	if node_type in boss_nodes:
		AudioManager.play_bgm("boss")
	else:
		AudioManager.play_bgm("battle")
	if node_type == "serpent":
		_show_title("耶梦加得", Callable())

var _menu_popup: Control

func _ghost_button(b: Button, size_px: int = 20) -> void:
	UiKit.ghost_button(b, size_px)

func _open_battle_menu() -> void:
	_close_battle_menu()

	_menu_popup = Control.new()
	_menu_popup.size = Vector2(1280, 720)
	_menu_popup.z_index = 90
	add_child(_menu_popup)

	var dim := Button.new()
	dim.flat = true
	dim.size = Vector2(1280, 720)
	dim.focus_mode = Control.FOCUS_NONE
	dim.pressed.connect(_close_battle_menu)
	_menu_popup.add_child(dim)

	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.09, 0.12, 0.97)
	panel.position = Vector2(970, 64)
	panel.size = Vector2(290, 210)
	_menu_popup.add_child(panel)

	var resume_btn := Button.new()
	resume_btn.text = "继续战斗"
	resume_btn.position = Vector2(986, 80)
	resume_btn.size = Vector2(258, 48)
	resume_btn.focus_mode = Control.FOCUS_NONE
	resume_btn.pressed.connect(_close_battle_menu)
	_menu_popup.add_child(resume_btn)
	_ghost_button(resume_btn, 18)

	var help_btn := Button.new()
	help_btn.text = "buff效果说明"
	help_btn.position = Vector2(986, 200)
	help_btn.size = Vector2(258, 48)
	help_btn.focus_mode = Control.FOCUS_NONE
	help_btn.pressed.connect(_open_status_help)
	_menu_popup.add_child(help_btn)
	_ghost_button(help_btn, 18)

	var quit_btn := Button.new()
	quit_btn.text = "返回首页"
	quit_btn.position = Vector2(986, 140)
	quit_btn.size = Vector2(258, 48)
	quit_btn.focus_mode = Control.FOCUS_NONE
	quit_btn.pressed.connect(_back_to_menu_from_battle)
	_menu_popup.add_child(quit_btn)
	_ghost_button(quit_btn, 18)

func _close_battle_menu() -> void:
	if _menu_popup != null and is_instance_valid(_menu_popup):
		_menu_popup.queue_free()
	_menu_popup = null

func _open_status_help() -> void:
	_close_battle_menu()
	StatusHelp.open(self)

func _back_to_menu_from_battle() -> void:
	var snap: Dictionary = GameState.pending_snapshot.duplicate(true)
	if snap.is_empty():
		snap = {"kind": "battle", "enemy": {}}
	snap["resume"] = {
		"enemy_hp": enemy.hp,
		"enemy_turn": enemy.turn_index,
		"enemy_status": enemy.status.duplicate(true),
		"player_hp": player_hp,
		"player_block": player_block,
		"player_status": player_status.duplicate(true),
		"draw": deck.draw_pile.duplicate(),
		"hand": deck.hand.duplicate(),
		"discard": deck.discard_pile.duplicate(),
	}
	GameState.pending_snapshot = snap
	GameState.pending_enemy = {}
	GameState.player_hp = max(1, player_hp)
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _restore_battle(r: Dictionary) -> void:
	enemy.hp = int(r.get("enemy_hp", enemy.hp))
	enemy.turn_index = int(r.get("enemy_turn", 0))
	enemy.status = r.get("enemy_status", {})
	player_hp = int(r.get("player_hp", player_hp))
	player_block = int(r.get("player_block", 0))
	player_status = r.get("player_status", {})

	deck.draw_pile.clear()
	for c in r.get("draw", []):
		deck.draw_pile.append(str(c))
	deck.hand.clear()
	for c in r.get("hand", []):
		deck.hand.append(str(c))
		_new_cards = deck.hand.size()
	deck.discard_pile.clear()
	for c in r.get("discard", []):
		deck.discard_pile.append(str(c))

func _finish_tutorial() -> void:
	GameState.pending_snapshot = {}
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("story", "prologue_stage", 2)
	cfg.save("user://settings.cfg")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _setup_allies() -> void:
	ally_fighters.clear()
	var lines: Array[String] = []
	for id in GameState.allies:
		var c: Dictionary = ContestantDB.get_contestant(id)
		var eff: Dictionary = c.get("ally_effect", {})
		var t: String = str(eff.get("type", ""))
		var quote := str(c.get("ally_line", ""))
		var how := ""
		if t == "fighter":
			var dmg: int = int(eff.get("damage", 5))
			ally_fighters.append({"name": c["name"], "damage": dmg})
			how = "每回合 %d 伤害" % dmg
		else:
			if eff.has("cards"):
				for card in eff["cards"]:
					deck.hand.append(str(card))
				how = "开局赠「%s」" % str(eff["cards"][0])
			if eff.has("hp"):
				player_hp = min(GameState.player_max_hp, player_hp + int(eff["hp"]))
				var hp_txt := "开局 +%d HP" % int(eff["hp"])
				how = hp_txt if how == "" else how + "、" + hp_txt
		var head := "%s（%s）" % [c["name"], how] if how != "" else str(c["name"])
		lines.append(head if quote == "" else "%s\n   「%s」" % [head, quote])

	ally_label.text = "盟友\n" + "\n".join(lines)

func _open_piles() -> void:
	DeckViewer.open_piles(deck.draw_pile, deck.hand, deck.discard_pile)
func _render_hand() -> void:
	hand_view.render(deck.hand, player_energy, pending_effect, pending_selected, _new_cards)
	_new_cards = 0

# 返回本场战斗还能用几次；-1 表示不限制
func _uses_left(card: String) -> int:
	var limit: int = int(CardDB.get_card(card).get("max_uses", 0))
	if limit <= 0:
		return -1
	return max(0, limit - int(battle_uses.get(card, 0)))

func _mark_used(card: String) -> void:
	battle_uses[card] = int(battle_uses.get(card, 0)) + 1

func _draw_cards(n: int) -> void:
	AudioManager.play("draw")
	if _draw_depth >= 3:
		return
	_draw_depth += 1

	var encounters: Array[String] = []
	var extra_draw := 0
	for card in deck.draw_raw(n):
		if CardDB.kind_of(card) == "encounter":
			if _uses_left(card) == 0:
				continue
			_mark_used(card)
			_apply_card_effects(card)
			deck.discard_pile.append(card)
			encounters.append(CardDB.card_text(card).replace("\n", " "))
			Tutorial.notify("encounter_triggered")
			extra_draw += int(CardDB.get_card(card).get("draw", 0))
			if player_hp <= 0:
				_check_game_over()
				_draw_depth -= 1
				return
		else:
			deck.hand.append(card)
			_new_cards += 1

	if not encounters.is_empty():
		var msg := ""
		for e in encounters:
			if msg != "":
				msg += "  |  "
			msg += e
		Toast.show_text("遭遇牌：" + msg)

	if extra_draw > 0:
		_draw_cards(extra_draw)

	_draw_depth -= 1

func _apply_card_effects(c: String) -> void:
	var d: Dictionary = CardDB.get_card(c)
	var hits: int = d.get("hits", 1)
	var hits_key := str(d.get("hits_from_enemy_status", ""))
	if hits_key != "":
		hits = max(1, int(enemy.status.get(hits_key, 0)))
	var per_st_pre: Dictionary = d.get("damage_per_enemy_status", {})
	var has_scale: bool = int(d.get("damage_per_strength", 0)) > 0
	for key in per_st_pre:
		if int(per_st_pre[key]) != 0:
			has_scale = true
	if d["damage"] > 0 or d.get("damage_from_block", false) or has_scale:
		var base_damage: int = int(d["damage"])
		if d.get("damage_from_block", false):
			base_damage = min(player_block * int(d.get("block_damage_mult", 1)), BLOCK_DAMAGE_CAP)
		if d.get("damage_from_gold", false):
			base_damage = GameState.gold
		var per_st: Dictionary = d.get("damage_per_enemy_status", {})
		for key in per_st:
			base_damage += int(enemy.status.get(key, 0)) * int(per_st[key])
		if int(d.get("damage_per_strength", 0)) > 0:
			base_damage += int(player_status.get("力量", 0)) * int(d["damage_per_strength"])
		var ck := str(creed.get("key", ""))
		if ck == "first_attack_double" and not first_attack_used:
			base_damage *= 2
			first_attack_used = true
		elif ck == "first_attack_bonus" and not first_attack_used:
			base_damage += int(creed.get("value", 0))
			first_attack_used = true
		if ck == "no_attack_bonus" and not attacked_last_turn:
			base_damage = int(base_damage * int(creed.get("value", 150)) / 100.0)
		if ck == "low_hp_bonus" and player_hp * 100 / max(1, GameState.player_max_hp) < 30:
			base_damage = int(base_damage * int(creed.get("value", 150)) / 100.0)
		attacked_this_turn = true
		var per := DamageCalc.compute(base_damage, player_status, enemy.status)
		var leech := int(player_status.get("嗜血", 0))
		if leech > 0:
			player_hp = min(GameState.player_max_hp, player_hp + leech)
		enemy.hp = max(0, enemy.hp - per * hits)
		var clear_key := str(d.get("clear_enemy_status", ""))
		if clear_key != "":
			enemy.status.erase(clear_key)
		AudioManager.play("attack")
		if d.get("zero_block_after", false):
			player_block = 0
		elif d.get("damage_from_block", false):
			player_block = int(player_block / 2.0)
		var thorns: int = int(enemy.status.get("荆棘", 0))
		if thorns > 0:
			player_hp = max(0, player_hp - thorns)
			_on_player_hurt(true)
		if str(enemy.domain.get("type", "")) == "attack_recoil":
			player_hp = max(0, player_hp - int(enemy.domain.get("value", 0)))
			_on_player_hurt()
	var gained_block: int = int(d["block"])
	if str(enemy.domain.get("type", "")) == "half_block":
		gained_block = int(gained_block / 2.0)
	player_block += gained_block
	if d.get("poison_double", false):
		enemy.status["中毒"] = int(enemy.status.get("中毒", 0)) * 2
	if d["block"] > 0:
		Tutorial.notify("blocked")
	if d.has("status"):
		StatusSystem.apply(enemy.status, d["status"])
	if d.has("self_status"):
		StatusSystem.apply(player_status, d["self_status"])
	if d.get("skip_enemy_turn", 0) > 0:
		skip_enemy += int(d["skip_enemy_turn"])
	if d.get("next_energy", 0) != 0:
		bonus_energy += int(d["next_energy"])
	if int(d.get("heal_percent_missing", 0)) > 0:
		var missing := GameState.player_max_hp - player_hp
		var amt := int(missing * int(d["heal_percent_missing"]) / 100.0)
		if amt > 0:
			AudioManager.play("heal")
			player_hp = min(GameState.player_max_hp, player_hp + amt)
			_on_player_hurt(false)
	if d.get("heal", 0) > 0:
		if str(enemy.domain.get("type", "")) != "no_heal":
			AudioManager.play("heal")
			player_hp = min(GameState.player_max_hp, player_hp + d["heal"])
	if d.get("self_damage", 0) > 0 and not _player_immune():
		player_hp = max(0, player_hp - d["self_damage"])
		_on_player_hurt(true)
	if d.get("gain_energy", 0) > 0:
		player_energy += int(d["gain_energy"])
	if d.get("retrieve_top", false):
		if not deck.discard_pile.is_empty():
			deck.hand.append(deck.discard_pile.pop_back())

	if CardDB.kind_of(c) == "effect":
		var ek := str(creed.get("key", ""))
		if ek == "effect_damage":
			enemy.hp = max(0, enemy.hp - int(creed.get("value", 0)))
		elif ek == "effect_draw":
			_draw_cards(int(creed.get("value", 0)))

func _on_card_pressed(index: int) -> void:
	if game_over:
		return
	if pending_effect >= 0:
		_on_effect_select(index)
		return
	if index < 0 or index >= deck.hand.size():
		return
	var c: String = deck.hand[index]
	if _uses_left(c) == 0:
		Toast.show_text("「%s」本场战斗已用完" % c, 2.0)
		return
	var d: Dictionary = CardDB.get_card(c)
	var extra_cost := int(enemy.domain.get("value", 0)) if str(enemy.domain.get("type", "")) == "cost_up" else 0
	var discount := OrganDB.total("first_discount") if not first_card_used else 0
	extra_cost = max(-int(d["cost"]), extra_cost - discount)
	if player_energy < int(d["cost"]) + extra_cost:
		var req: Dictionary = d.get("min_self_status", {})
		for k in req:
			if int(player_status.get(k, 0)) < int(req[k]):
				Toast.show_text("力量不足", 1.5)
				return
		return
	if CardDB.kind_of(c) == "effect" and CardDB.consume_count(c) > 0:
		if deck.hand.size() - 1 < CardDB.consume_count(c):
			return
		pending_effect = index
		pending_need = CardDB.consume_count(c)
		pending_selected.clear()
		_render_hand()
		_update_ui()
		return
	AudioManager.play("click")
	var spent = hand_view.take_button(index)
	player_energy -= d["cost"]
	last_card_played = c
	first_card_used = true
	AudioManager.play("play")
	_apply_card_effects(c)
	Tutorial.notify("card_played")
	if CardDB.kind_of(c) == "effect":
		Tutorial.notify("effect_played")
	deck.hand.remove_at(index)
	# exhaust：本场战斗用掉就消失（不进弃牌堆）
	if not bool(d.get("exhaust", false)):
		deck.discard_pile.append(c)
	_mark_used(c)
	_check_game_over()
	_render_hand()
	CardAnim.play_to_center(self, spent)
	_update_ui()
	var draw_n: int = int(d.get("draw", 0))
	if draw_n > 0:
		_draw_cards(draw_n)
	_check_game_over()
	_render_hand()
	_update_ui()

func _on_effect_select(index: int) -> void:
	if index == pending_effect:
		pending_effect = -1
		pending_need = 0
		pending_selected.clear()
		_render_hand()
		_update_ui()
		return
	if pending_selected.has(index):
		pending_selected.erase(index)
	else:
		if pending_selected.size() >= pending_need:
			return
		pending_selected.append(index)
	if pending_selected.size() == pending_need:
		_resolve_effect()
		return
	_render_hand()
	_update_ui()

func _resolve_effect() -> void:
	var idx := pending_effect
	var c: String = deck.hand[idx]
	AudioManager.play("click")
	player_energy -= CardDB.get_card(c)["cost"]
	_apply_card_effects(c)

	var consumed: Array[String] = []
	var remove_idx: Array = [idx]
	for i in pending_selected:
		consumed.append(deck.hand[i])
		remove_idx.append(i)
	remove_idx.sort()
	remove_idx.reverse()
	var ghosts := {}
	for i in remove_idx:
		ghosts[i] = hand_view.take_button(i)
		deck.hand.remove_at(i)

	# 效果牌先进弃牌堆，消耗的牌盖在它上面
	deck.discard_pile.append(c)
	for card in consumed:
		deck.discard_pile.append(card)

	var draw_n: int = int(CardDB.get_card(c).get("draw", 0))
	if draw_n > 0:
		_draw_cards(draw_n)

	pending_effect = -1
	pending_need = 0
	pending_selected.clear()
	_check_game_over()
	_render_hand()
	CardAnim.play_to_center(self, ghosts.get(idx))
	for i in remove_idx:
		if i != idx:
			CardAnim.discard_to(self, ghosts.get(i), Vector2(140, 655))
	_update_ui()

# ===== 回合流程（分阶段）=====
func _on_end_turn_pressed() -> void:
	if _ending_turn:
		return
	Tutorial.notify("turn_ended")
	if game_over or pending_effect >= 0:
		return
	# 防连点：这一帧内不再接受结束回合
	_ending_turn = true
	if end_turn_button != null:
		end_turn_button.disabled = true
	_end_player_turn()
	if skip_enemy > 0:
		skip_enemy -= 1
		Toast.show_text("你的威严使他退却", 2.0)
		_start_new_turn()
	else:
		_resolve_enemy_turn()
	_check_game_over()
	_update_ui()
	if game_over:
		_ending_turn = false
		if end_turn_button != null:
			end_turn_button.disabled = false
		return
	_start_new_turn()
	# 下一帧才恢复（挡住同一帧内的连点）
	get_tree().create_timer(0.25).timeout.connect(func() -> void:
		_ending_turn = false
		if end_turn_button != null and not game_over:
			end_turn_button.disabled = false
	)

func _end_player_turn() -> void:
	# 回合结束：手牌全部弃掉，下回合重新抽
	for card in deck.hand:
		deck.discard_pile.append(str(card))
	deck.hand.clear()

	var pp := StatusSystem.tick_damage(player_status)
	if pp > 0:
		player_hp = max(0, player_hp - pp)
		_on_player_hurt()
	var ph := StatusSystem.tick_heal(player_status)
	if ph > 0:
		player_hp = min(GameState.player_max_hp, player_hp + ph)

func _player_immune() -> bool:
	return player_status.has("恒光")

func _on_player_hurt(now: bool = false) -> void:
	AudioManager.play("hurt")
	if str(creed.get("key", "")) != "hurt_energy":
		return
	var v := int(creed.get("value", 0))
	if now:
		player_energy += v
		_update_ui()
	else:
		bonus_energy += v

func _resolve_enemy_turn() -> void:
	var raw_dmg := DamageCalc.compute(enemy.intent_damage(), enemy.status, player_status)
	var absorbed: int = min(player_block, raw_dmg)
	player_block = max(0, player_block - absorbed)
	var dmg: int = max(0, raw_dmg - absorbed)
	_update_ui()   # 格挡变化后立刻刷新
	if dmg > 0 and int(player_status.get("护佑", 0)) > 0:
		player_status["护佑"] = int(player_status["护佑"]) - 1
		if int(player_status["护佑"]) <= 0:
			player_status.erase("护佑")
		dmg = 0
	if _player_immune():
		dmg = 0
	var hk := str(creed.get("key", ""))
	if dmg > 0 and hk == "first_hurt_half" and not first_hurt_used:
		first_hurt_used = true
		dmg = int(dmg / 2.0)
	if dmg > 0 and hk == "first_hurt_zero" and not first_hurt_used:
		first_hurt_used = true
		dmg = 0
	damage_taken += dmg
	player_hp = max(0, player_hp - dmg)
	if dmg > 0:
		var reflect := int(player_status.get("反弹", 0))
		if reflect > 0:
			enemy.hp = max(0, enemy.hp - reflect)
		var fury := int(player_status.get("狂怒", 0))
		if fury > 0:
			player_status["力量"] = int(player_status.get("力量", 0)) + fury
		Tutorial.notify("hurt")
	if not player_status.has("坚守"):
		player_block = 0
		_update_ui()   # 清空后也刷一次
	if dmg > 0:
		_on_player_hurt()
	enemy.turn_index += 1

	var ep := StatusSystem.tick_damage(enemy.status)
	if ep > 0:
		enemy.hp = max(0, enemy.hp - ep)

	# 毒性增长（挂在敌人身上）：毒伤结算之后，每 4 层额外 +1
	if enemy.status.has("毒性增长"):
		var pz := int(enemy.status.get("中毒", 0))
		if pz >= 4:
			enemy.status["中毒"] = pz + int(float(pz) / 4.0)

	var eh := StatusSystem.tick_heal(enemy.status)
	if eh > 0:
		enemy.hp = min(enemy.max_hp, enemy.hp + eh)

	StatusSystem.decay(player_status)
	StatusSystem.decay(enemy.status)

	if not enemy.on_turn.is_empty():
		StatusSystem.apply(enemy.status, enemy.on_turn)
	if not enemy.on_hit.is_empty():
		StatusSystem.apply(player_status, enemy.on_hit)

	for s in enemy.due_skills():
		if s.has("heal"):
			enemy.hp = min(enemy.max_hp, enemy.hp + int(s["heal"]))
		if s.has("status"):
			var st: Dictionary = s["status"]
			if str(s.get("to", "player")) == "self":
				StatusSystem.apply(enemy.status, st)
			else:
				StatusSystem.apply(player_status, st)
	if str(enemy.domain.get("type", "")) == "enemy_regen":
		enemy.hp = min(enemy.max_hp, enemy.hp + int(enemy.domain.get("value", 0)))

func _apply_turn_creed() -> void:
	first_attack_used = false
	first_card_used = false
	attacked_this_turn = false
	if str(creed.get("key", "")) == "turn_block":
		player_block += int(creed.get("value", 0))

func _domain_tick() -> void:
	var t := str(enemy.domain.get("type", ""))
	var v := int(enemy.domain.get("value", 0))
	match t:
		"damage_aura":
			player_hp = max(0, player_hp - v)
		"weak_aura":
			player_status["虚弱"] = int(player_status.get("虚弱", 0)) + v
		"bleed_aura":
			player_status["流血"] = int(player_status.get("流血", 0)) + v
		"block_decay":
			player_block = max(0, player_block - v)
		"poison_aura":
			player_status["中毒"] = int(player_status.get("中毒", 0)) + v

func _start_new_turn() -> void:
	_domain_tick()
	if game_over:
		return
	for f in ally_fighters:
		enemy.hp = max(0, enemy.hp - int(f["damage"]))
	if not ally_fighters.is_empty():
		AudioManager.play("hit")
	_check_game_over()
	if game_over:
		return
	if node_type == "tutorial":
		Tutorial.advance()
		for c in Tutorial.cards_for(Tutorial.turn):
			var cn := str(c)
			if CardDB.kind_of(cn) == "encounter":
				_apply_card_effects(cn)
				deck.discard_pile.append(cn)
				Toast.show_text("遭遇牌：" + CardDB.card_text(cn).replace("\n", " "))
			else:
				deck.hand.append(cn)
				_new_cards += 1
	else:
		var draw_count: int = RunConfig.BASE_DRAW + player_energy + OrganDB.total("draw") + GameState.wealth_draw
		draw_count += int(player_status.get("洞察", 0))
		draw_count = max(0, draw_count - int(player_status.get("迟钝", 0)))
		var dt := str(enemy.domain.get("type", ""))
		if dt == "draw_penalty" or dt == "less_draw":
			draw_count = max(0, draw_count - int(enemy.domain.get("value", 0)))
		if draw_count > 0:
			_draw_cards(draw_count)
	player_energy = max_energy + bonus_energy
	bonus_energy = 0
	player_energy += int(player_status.get("迅捷", 0))
	player_energy = max(0, player_energy - int(player_status.get("重力", 0)))
	if player_status.has("狂化"):
		player_status["力量"] = int(player_status.get("力量", 0)) + 2
	if str(enemy.domain.get("type", "")) == "energy_drain":
		player_energy = max(0, player_energy - int(enemy.domain.get("value", 0)))
	var guard := int(player_status.get("守护", 0))
	if guard > 0:
		player_block += guard
	_apply_turn_creed()
	var burn := int(player_status.get("炽热", 0))
	if burn > 0:
		enemy.hp = max(0, enemy.hp - burn)
	attacked_last_turn = attacked_this_turn
	_render_hand()
	_update_ui()

func _check_game_over() -> void:
	if game_over:
		return
	if enemy.hp <= 0:
		game_over = true
		AudioManager.play("victory")
		Tutorial.notify("win")
		Tutorial.stop()
		if node_type == "tutorial":
			_finish_tutorial()
			return
		var wk := str(creed.get("key", ""))
		if node_type == "elite" and int(CardDB.get_card(last_card_played).get("elite_kill_energy", 0)) > 0:
			GameState.energy_bonus += int(CardDB.get_card(last_card_played)["elite_kill_energy"])
			Toast.show_text("能量上限 +1", 2.5)
		if wk == "win_heal":
			player_hp = min(GameState.player_max_hp, player_hp + int(creed.get("value", 0)))
		elif wk == "hurt_gold":
			GameState.gold += damage_taken
		elif wk == "hurt_energy":
			pass
		if wk == "kill_pick":
			_kill_pick_pending = true
		if node_type == "god":
			var organ := str(enemy_organ)
			if organ != "":
				OrganDB.take(organ)
				Toast.show_text("你取走了它的「%s」。\n神性 +15" % organ, 3.5)
		GameState.player_hp = max(1, player_hp)
		if GameState.pending_contestant != "":
			_show_contestant_aftermath()
			return
		if node_type == "pope":
			_on_pope_defeated()
			return
		if node_type == "tree":
			_enter_act3()
			return
		if node_type == "serpent":
			_on_serpent_defeated()
			return
		last_gold_gain = NodeRuleDB.gold_of(node_type)
		GameState.gold += last_gold_gain
		if node_type == "boss":
			_after_boss()
		else:
			_show_reward()
	elif player_hp <= 0:
		game_over = true
		AudioManager.play("defeat")
		if node_type == "tutorial":
			await get_tree().create_timer(0.8).timeout
			get_tree().reload_current_scene()
			return
		await get_tree().create_timer(1.0).timeout
		_show_game_over()

func _surviving_contestants() -> Array[String]:
	var result: Array[String] = []
	for id in GameState.contestants:
		if GameState.eliminated.has(id):
			continue
		if GameState.allies.has(id):
			continue
		result.append(id)
	return result

func _after_boss() -> void:
	if not _surviving_contestants().is_empty():
		_show_cleanup_prompt()
		return
	GameState.pending_cleanup = false
	_show_church()

func _show_cleanup_prompt() -> void:
	hand_view.hide_cards()
	var n := _surviving_contestants().size()

	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.93)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)

	var title := Label.new()
	title.text = StoryDB.t("cleanup_title")
	title.position = Vector2(0, 180)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	overlay.add_child(title)

	var body := Label.new()
	body.text = StoryDB.f("cleanup_body", [n])
	body.position = Vector2(0, 290)
	body.size = Vector2(1280, 100)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	overlay.add_child(body)

	var btn := Button.new()
	btn.text = StoryDB.t("cleanup_button")
	btn.size = Vector2(240, 64)
	btn.position = Vector2(520, 440)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_begin_cleanup)
	overlay.add_child(btn)
	_ghost_button(btn, 20)

func _begin_cleanup() -> void:
	GameState.pending_cleanup = true
	GameState.save_game()
	_start_next_cleanup()

func _show_cleanup_result(text: String, summary: String) -> void:
	var overlay := Modal.open(self, 0.93)
	Modal.title(overlay, StoryDB.t("cleanup_result_title"), 150, 44)
	Modal.text(overlay, text, 260, 22, 60)
	var gain := Modal.text(overlay, summary if summary != "" else StoryDB.t("cleanup_result_empty"), 340, 20, 80)
	gain.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	var left := _surviving_contestants().size()
	var label := StoryDB.f("cleanup_continue", [left]) if left > 0 else StoryDB.t("cleanup_go")
	Modal.button(overlay, label, 500, 470, 280, 64, _start_next_cleanup)

func _start_next_cleanup() -> void:
	var targets := _surviving_contestants()
	if targets.is_empty():
		GameState.pending_cleanup = false
		GameState.save_game()
		_show_church()
		return

	var id: String = targets[0]
	var c: Dictionary = ContestantDB.get_contestant(id)
	var enemy_data := {
		"name": c["name"],
		"hp": int(c["hp"]),
		"attack": int(c["attack"]),
		"pattern": c.get("pattern", [1]),
		"on_hit": c.get("on_hit", {}),
		"domain": c.get("domain", {}),
		"skills": c.get("skills", []),
	}
	GameState.pending_enemy = enemy_data
	GameState.pending_contestant = id
	GameState.pending_snapshot = {"kind": "contestant_fight", "id": id, "enemy": enemy_data}
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# 给左上/右上的信息块加一块暗底，保证在战斗背景上看得清
func _backing(pos: Vector2, size: Vector2, align_right: bool = false) -> void:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.03, 0.05, 0.80)
	sb.border_color = Color(0.79, 0.66, 0.42, 0.50)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)

func _update_ui() -> void:
	info_label.text = "能量 %d/%d" % [player_energy, max_energy]
	pile_label.text = "抽牌堆 %d　　手牌 %d　　弃牌堆 %d　　金币 %d" % [
		deck.draw_pile.size(), deck.hand.size(), deck.discard_pile.size(), GameState.gold
	]

	var ptext := "【玩家】\nHP: %d\n格挡: %d" % [player_hp, player_block]
	var status_txt: String = StatusSystem.text(player_status)
	status_label.text = status_txt
	status_label.visible = status_txt != ""
	if pending_effect >= 0:
		ptext += "\n选择 %d 张手牌消耗（已选 %d）" % [pending_need, pending_selected.size()]
	player_label.text = ptext

	var etext := "【%s】\nHP: %d" % [enemy.label_name, enemy.hp]
	var es := StatusSystem.text(enemy.status)
	if es != "":
		etext += "\n状态: %s" % es
	var dtxt: String = EnemyDB.domain_text(enemy.domain)
	if dtxt != "":
		etext += "\n领域: %s" % dtxt
	if enemy.hp > 0 and player_hp > 0:
		var intent := "意图：攻击 %d" % DamageCalc.compute(enemy.intent_damage(), enemy.status, player_status)
		var hit_extra := StatusSystem.text(enemy.on_hit)
		if hit_extra != "":
			intent += " + %s" % hit_extra
		etext += "\n" + intent
	if enemy.hp <= 0:
		etext += "\n你赢了！"
	elif player_hp <= 0:
		etext += "\n你被打败了..."
	combat_label.text = etext
	
func _show_reward() -> void:
	hand_view.hide_cards()

	var pool: Array = RewardDB.pick_cards(node_type, NodeRuleDB.cards_of(node_type), GameState.act)
	var overlay := Modal.open(self, 0.85)
	var title_key := "reward_title" if pool.size() > 0 else "reward_title_gold"
	Modal.title(overlay, StoryDB.f(title_key, [last_gold_gain]), 110, 24)

	var n: int = pool.size()
	var spacing := 250.0
	var card_w := 200.0
	var total := (n - 1) * spacing + card_w
	var start_x := (1280.0 - total) / 2.0
	for i in range(n):
		var card_name: String = pool[i]
		var btn := CardUI.make_button(card_name, 18)
		btn.size = Vector2(card_w, 240)
		btn.position = Vector2(start_x + i * spacing, 200)
		btn.pressed.connect(_choose_reward.bind(card_name))
		overlay.add_child(btn)
	var hint := Label.new()
	hint.text = "点击一张，加入牌组"
	hint.position = Vector2(0, 458)
	hint.size = Vector2(1280, 32)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	StoryDB.apply_serif(hint)
	overlay.add_child(hint)

	var help := Modal.button(overlay, "状态说明", 40, 610, 170, 44, func() -> void: StatusHelp.open(self))
	_ghost_button(help, 18)

	if RunConfig.ALLOW_SKIP:
		var skip := Modal.button(overlay, StoryDB.t("reward_skip"), 540, 520, 200, 50, _finish_reward)
		_ghost_button(skip)

func _choose_reward(card_name: String) -> void:
	GameState.deck.append(card_name)
	_finish_reward()

func _finish_reward() -> void:
	GameState.pending_node = -1
	GameState.pending_snapshot = {}
	GameState.save_game()
	if _kill_pick_pending:
		_kill_pick_pending = false
		DeckViewer.open_choose("收殓：从牌组中复制一张", GameState.deck, _do_kill_pick)
		return
	if NodeRuleDB.discard_of(node_type):
		_offer_discard()
		return
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _do_kill_pick(index: int) -> void:
	if index >= 0 and index < GameState.deck.size():
		var c: String = GameState.deck[index]
		GameState.deck.append(c)
		GameState.save_game()
		Toast.show_text("「%s」又进了一份" % c, 2.5)
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _offer_discard() -> void:
	DeckViewer.open_choose("精英战利品：弃掉一张牌", GameState.deck, _discard_card)

func _discard_card(index: int) -> void:
	if index >= 0 and index < GameState.deck.size():
		var removed: String = GameState.deck[index]
		GameState.deck.remove_at(index)
		Toast.show_text("弃掉了「%s」" % removed, 2.5)
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _show_game_over() -> void:
	var overlay := Modal.open(self, 0.85)
	var title_key := "gameover_title"
	var body_key := "gameover_body"
	if GameState.transmigration >= 10:
		title_key = "gameover_loop_title"
		body_key = "gameover_loop_body"
	Modal.title(overlay, StoryDB.t(title_key), 240, 34)
	Modal.text(overlay, StoryDB.t(body_key), 310, 18, 50)
	Modal.button(overlay, StoryDB.t("gameover_restart"), 530, 400, 220, 60, _restart_run)

func _restart_run() -> void:
	GameState.restart_run()
	get_tree().change_scene_to_file("res://scenes/run_intro.tscn")

func _back_to_menu() -> void:
	GameState.delete_save()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _show_pope() -> void:
	hand_view.hide_cards()
	var old_trans: int = GameState.transmigration
	GameState.advance_transmigration()

	var overlay := Modal.open(self, 0.93)
	Modal.title(overlay, StoryDB.t("pope_title"), 140, 44)
	Modal.text(overlay, StoryDB.t("pope_body"), 240, 22, 100)
	var trans := Modal.text(overlay, "第 %d 次转生结束 → 第 %d 次转生开始\n职业：%s\n词条：%s" % [old_trans, GameState.transmigration, GameState.vocation, TraitDB.text_of(GameState.traits)], 360, 20, 100)
	trans.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	Modal.button(overlay, StoryDB.t("pope_button"), 530, 500, 220, 60, _transmigrate)

func _transmigrate() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _show_contestant_aftermath() -> void:
	var id: String = GameState.pending_contestant
	var c: Dictionary = ContestantDB.scaled(id)
	hand_view.hide_cards()

	var overlay := Modal.open(self, 0.92)
	Modal.title(overlay, StoryDB.f("aftermath_title", [c["name"]]), 220, 42)
	var body_text := StoryDB.t("aftermath_cleanup") if GameState.pending_cleanup else StoryDB.t("aftermath_normal")
	Modal.text(overlay, body_text, 320, 22, 60)

	if GameState.pending_cleanup:
		Modal.button(overlay, StoryDB.t("aftermath_kill"), 520, 430, 240, 60, _choose_aftermath.bind(id, true))
	else:
		Modal.button(overlay, StoryDB.t("aftermath_kill"), 390, 430, 200, 60, _choose_aftermath.bind(id, true))
		Modal.button(overlay, StoryDB.t("aftermath_spare"), 690, 430, 200, 60, _choose_aftermath.bind(id, false))

func _choose_aftermath(id: String, kill: bool) -> void:
	var c: Dictionary = ContestantDB.get_contestant(id)
	var reward: Dictionary = c["kill"] if kill else c["spare"]

	if kill:
		GameState.eliminated.append(id)
		Morality.add(-5, 10)
		if GameState.act == 3:
			GameState.divinity = clampi(GameState.divinity + 10, 0, 100)  # 第三幕杀英雄
	else:
		GameState.met_contestants.append(id)
		Morality.add(8, 0)

	var summary := Reward.apply(reward, id)

	GameState.pending_contestant = ""
	GameState.pending_snapshot = {}

	if GameState.pending_cleanup:
		GameState.save_game()
		_show_cleanup_result(str(reward.get("text", "")), summary)
		return

	GameState.pending_node = -1
	GameState.save_game()
	Toast.show_text("%s\n%s" % [str(reward.get("text", "")), summary], 3.5)
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _show_church() -> void:
	hand_view.hide_cards()
	var overlay := Modal.open(self, 0.95)
	Modal.title(overlay, StoryDB.t("church_title"), 150, 52)
	Modal.text(overlay, StoryDB.t("church_body"), 270, 24, 100)
	Modal.button(overlay, StoryDB.t("church_button"), 510, 480, 260, 64, _enter_church)

func _enter_church() -> void:
	GameState.player_hp = GameState.player_max_hp
	GameState.save_game()
	if GameState.transmigration >= 10:
		_enter_divine_realm()
		return
	_show_pope()

# 教皇死亡假结局：善恶值不够的玩家停在这里，永远见不到第三幕
# 善恶达标：教皇死后先看见那棵假树，才打它
func _show_tree_reveal() -> void:
	hand_view.hide_cards()
	var overlay := Modal.open(self, 0.97)
	var title := Modal.title(overlay, "伪·世界树", 120, 48)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	var key := "ending_body_good" if Morality.is_saint() else "ending_body_dark"
	Modal.text(overlay, StoryDB.t(key), 240, 22, 260)
	Modal.button(overlay, "抬头", 520, 560, 240, 60, func() -> void:
		overlay.queue_free()
		_start_tree_fight()
	)

func _show_fake_ending() -> void:
	hand_view.hide_cards()
	var overlay := Modal.open(self, 0.97)
	var title := Modal.title(overlay, StoryDB.t("ending_title"), 130, 52)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	Modal.text(overlay, StoryDB.t("ending_body"), 260, 24, 200)
	var stats := Modal.text(overlay, "第 %d 次转生\n剩余生命: %d / %d\n%s" % [GameState.transmigration, player_hp, GameState.player_max_hp, Morality.summary()], 460, 20, 100)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	var hint := Modal.text(overlay, "（一切似乎都结束了）", 545, 17, 30)
	hint.add_theme_color_override("font_color", Color(0.55, 0.52, 0.48))
	Modal.button(overlay, StoryDB.t("ending_button"), 520, 590, 240, 60, _end_fake_run)


func _on_pope_defeated() -> void:
	if Morality.is_saint() or Morality.is_sinner():
		Dialogue.play(self, DialogueDB.get_lines("pope_defeat"), _show_tree_reveal)
	else:
		Dialogue.play(self, DialogueDB.get_lines("pope_defeat"), _show_fake_ending)

func _show_title(text: String, next: Callable) -> void:
	var layer := ColorRect.new()
	layer.color = Color(0.02, 0.02, 0.03, 0.0)
	layer.size = Vector2(1280, 720)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)

	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(0, 300)
	lbl.size = Vector2(1280, 120)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 64)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	lbl.modulate.a = 0.0
	StoryDB.apply_serif(lbl)
	layer.add_child(lbl)

	var tw := create_tween()
	tw.tween_property(layer, "color", Color(0.02, 0.02, 0.03, 0.94), 0.5)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.9)
	tw.tween_interval(1.2)
	tw.tween_property(layer, "color", Color(0.02, 0.02, 0.03, 0.0), 0.5)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		layer.queue_free()
		if next.is_valid():
			next.call()
	)

func _start_tree_fight() -> void:
	node_type = "tree"
	enemy_organ = ""
	var data: Dictionary = EnemyDB.pick_for_node("tree", 0)
	enemy.setup(data)
	deck.hand.clear()
	deck.discard_pile.clear()
	deck.draw_pile.clear()
	for card in GameState.deck:
		deck.draw_pile.append(str(card))
	deck.draw_pile.shuffle()
	player_hp = GameState.player_max_hp
	player_block = 0
	player_status = {}
	player_energy = GameState.initial_energy()
	_start_new_turn()
	Toast.show_text("树还在。\n它没有倒。", 3.5)

func _enter_act3() -> void:
	GameState.act = 3
	GameState.allies.clear()
	# 人间不属于逐神游戏：第一幕死掉的人在这里都会再出现
	GameState.eliminated.clear()
	GameState.map_generated = false
	GameState.map_nodes = {}
	GameState.current_node_id = 0
	GameState.pending_snapshot = {}
	GameState.pending_node = -1
	GameState.pending_cleanup = false
	GameState.save_game()
	Dialogue.play(self, DialogueDB.get_lines("first_act3"), _goto_act3_map)

func _goto_act3_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")


func _on_serpent_defeated() -> void:
	GameState.divinity = clampi(GameState.divinity, 0, 100)
	_first_clear = not GameState.act3_cleared
	GameState.mark_act3_cleared()
	GameState.save_game()
	if GameState.divinity >= 71:
		Dialogue.play(self, DialogueDB.get_lines("ending_god"), _show_serpent_ending)
	elif GameState.divinity >= 31:
		Dialogue.play(self, DialogueDB.get_lines("ending_loop"), _show_serpent_ending)
	else:
		Dialogue.play(self, DialogueDB.get_lines("ending_human"), _show_serpent_ending)

func _show_serpent_ending() -> void:
	hand_view.hide_cards()
	var overlay := Modal.open(self, 0.97)
	var title := StoryDB.t("ending_god_title") if GameState.divinity >= 71 else (StoryDB.t("ending_loop_title") if GameState.divinity >= 31 else StoryDB.t("ending_human_title"))
	Modal.title(overlay, title, 150, 46)
	var stats := Modal.text(overlay, "第 %d 次转生\n剩余生命: %d / %d\n%s\n神性: %d" % [GameState.transmigration, player_hp, GameState.player_max_hp, Morality.summary(), GameState.divinity], 300, 20, 140)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))

	if _first_clear:
		var unlock := Modal.text(overlay, "★ 解锁「自由配置」：下次开局可以自选职业与流派", 452, 18, 40)
		unlock.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	Modal.button(overlay, "回到开始", 530, 520, 220, 58, _end_true_run)

func _end_true_run() -> void:
	# 真结局：通关不删档，把「已通关」写进这个存档，下次可以自由配置
	GameState.mark_act3_cleared()
	GameState.pending_snapshot = {}
	GameState.pending_node = -1
	GameState.pending_cleanup = false
	GameState.pending_contestant = ""
	GameState.act = 3
	GameState.map_generated = false
	GameState.map_nodes = {}
	GameState.current_node_id = 0
	GameState.player_hp = GameState.player_max_hp
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _end_fake_run() -> void:
	# 假结局：这一轮到此为止。存档保留（还停在打教皇之前），但什么都不解锁。
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _enter_divine_realm() -> void:
	GameState.act = 2
	GameState.allies.clear()
	GameState.map_generated = false
	GameState.map_nodes = {}
	GameState.current_node_id = 0
	GameState.pending_snapshot = {}
	GameState.pending_node = -1
	GameState.pending_cleanup = false
	GameState.save_game()
	Dialogue.play(self, DialogueDB.get_lines("first_divine"), _goto_divine_map)

func _goto_divine_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")

extends Node2D

const SkillCutIn = preload("res://scripts/skill_cutin.gd")
const EnemyFx = preload("res://scripts/enemy_fx.gd")
const BattleHud = preload("res://scripts/battle_hud.gd")
const BattleFlow = preload("res://scripts/battle_flow.gd")
const BattleVictory = preload("res://scripts/battle_victory.gd")

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
var _skill_btn: Button
var _enemy_sprite: TextureRect
var _info_strip: Control
var _info_name: Label
var _info_detail: Label
var _domain_label: Label
var _last_enemy_hp := -1
var _last_player_hp := -1
var _last_intent := 0
var _telegraphed := false
var _player_sprite: TextureRect
var player_detail_label: Label
var enemy_detail_label: Label
var _skill_used := false
var _skill_btn_layer: CanvasLayer
var _hp_bar: ColorRect
var _block_bar_bg: ColorRect
var _block_bar: ColorRect
var _eblock_bar_bg: ColorRect
var _eblock_bar: ColorRect
var _hp_bar_bg: ColorRect
var _ehp_bar: ColorRect
var _ehp_bar_bg: ColorRect
var _turn_no := 1
var _no_attack_turns := 0
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


func _ready() -> void:
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

	deck.setup(GameState.deck)

	# 界面：阶段 A 起由 battle_hud.gd 统一搭建（背景/信息条/血条/立绘/按钮）
	BattleHud.build(self)

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

# ===== 发牌 / 出牌 / 结算 / 回合推进 已迁到 battle_flow.gd（阶段 B） =====
# 这里只留同签名转发，原有调用点（信号连接、_ready）不用改。

func _uses_left(card: String) -> int:
	return BattleFlow._uses_left(self, card)

func _mark_used(card: String) -> void:
	BattleFlow._mark_used(self, card)

func _draw_cards(n: int) -> void:
	BattleFlow._draw_cards(self, n)

func _apply_card_effects(c: String) -> void:
	BattleFlow._apply_card_effects(self, c)

func _on_card_pressed(index: int) -> void:
	BattleFlow._on_card_pressed(self, index)

func _on_effect_select(index: int) -> void:
	BattleFlow._on_effect_select(self, index)

func _resolve_effect() -> void:
	BattleFlow._resolve_effect(self)

func _on_end_turn_pressed() -> void:
	BattleFlow._on_end_turn_pressed(self)

func _end_player_turn() -> void:
	BattleFlow._end_player_turn(self)

func _player_immune() -> bool:
	return BattleFlow._player_immune(self)

func _on_player_hurt(now: bool = false) -> void:
	BattleFlow._on_player_hurt(self, now)

func _resolve_enemy_turn() -> void:
	BattleFlow._resolve_enemy_turn(self)

func _apply_turn_creed() -> void:
	BattleFlow._apply_turn_creed(self)

func _domain_tick() -> void:
	BattleFlow._domain_tick(self)

func _start_new_turn() -> void:
	BattleFlow._start_new_turn(self)

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

# ===== 奖励 / 击杀复制 / 弃牌 / 清理 已迁到 battle_victory.gd（阶段 C） =====
# 同样只留同签名转发，调用点（_check_game_over、_after_boss、信号）不用改。

func _surviving_contestants() -> Array[String]:
	return BattleVictory._surviving_contestants(self)

func _show_cleanup_prompt() -> void:
	BattleVictory._show_cleanup_prompt(self)

func _begin_cleanup() -> void:
	BattleVictory._begin_cleanup(self)

func _show_cleanup_result(text: String, summary: String) -> void:
	BattleVictory._show_cleanup_result(self, text, summary)

func _start_next_cleanup() -> void:
	BattleVictory._start_next_cleanup(self)

func _show_reward() -> void:
	BattleVictory._show_reward(self)

func _choose_reward(card_name: String) -> void:
	BattleVictory._choose_reward(self, card_name)

func _finish_reward() -> void:
	BattleVictory._finish_reward(self)

func _do_kill_pick(index: int) -> void:
	BattleVictory._do_kill_pick(self, index)

func _offer_discard() -> void:
	BattleVictory._offer_discard(self)

func _discard_card(index: int) -> void:
	BattleVictory._discard_card(self, index)

func _after_boss() -> void:
	if not _surviving_contestants().is_empty():
		_show_cleanup_prompt()
		return
	GameState.pending_cleanup = false
	_show_church()

# 给左上/右上的信息块加一块暗底，保证在战斗背景上看得清
func _backing(pos: Vector2, size: Vector2, align_right: bool = false) -> void:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.03, 0.05, 0.55)
	sb.border_color = Color(0.79, 0.66, 0.42, 0.42)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)
	# 放到背景图之上、所有文字之下
	if get_child_count() > 1:
		move_child(p, 1)


# ============================================================
# 职业技能
# ============================================================
func _skill_state() -> Dictionary:
	return {
		"turn": _turn_no,
		"hp": player_hp,
		"max_hp": GameState.player_max_hp,
		"block": player_block,
		"energy": player_energy,
		"hand": deck.hand.size(),
		"damage_taken": damage_taken,
		"no_attack_turns": _no_attack_turns,
		"enemy_poison": int(enemy.status.get("中毒", 0)),
	}


func _refresh_skill_btn() -> void:
	if _skill_btn == null:
		return
	var voc := str(GameState.vocation)
	if _skill_used or not SkillDB.has(voc):
		_skill_btn.visible = false
		return
	var ok := SkillDB.ready(voc, _skill_state())
	var show := not game_over and pending_effect < 0
	_skill_btn.visible = show
	if not show:
		return
	if ok:
		_skill_btn.text = "【%s】%s" % [SkillDB.name_of(voc), SkillDB.en_of(voc)]
		_skill_btn.add_theme_color_override("font_color", Color(0.98, 0.84, 0.46))
		_skill_btn.modulate = Color(1, 1, 1, 1)
	else:
		_skill_btn.text = "◈ " + SkillDB.hint_of(voc)
		_skill_btn.add_theme_color_override("font_color", Color(0.62, 0.57, 0.47))
		_skill_btn.modulate = Color(1, 1, 1, 0.75)
	_skill_btn.disabled = not ok


func _on_skill_pressed() -> void:
	if _skill_used or _skill_btn == null:
		return
	var voc := str(GameState.vocation)
	if not SkillDB.ready(voc, _skill_state()):
		return
	_skill_used = true
	_skill_btn.visible = false
	Tutorial.notify("skill_used")
	SkillCutIn.play(self, voc, func() -> void:
		_apply_skill_effect(voc)
	)


func _apply_skill_effect(voc: String) -> void:
	var e: Dictionary = SkillDB.effect_of(voc)
	AudioManager.play("victory")

	# 格挡
	if int(e.get("block", 0)) > 0:
		player_block += int(e["block"])
	# 回复
	if int(e.get("heal", 0)) > 0:
		player_hp = min(GameState.player_max_hp, player_hp + int(e["heal"]))
	# 能量 / 抽牌
	if int(e.get("energy", 0)) > 0:
		player_energy += int(e["energy"])
	if int(e.get("draw", 0)) > 0:
		_draw_cards(int(e["draw"]))
	# 自我状态
	for k in e.get("status_self", {}):
		player_status[k] = int(player_status.get(k, 0)) + int(e["status_self"][k])
	# 敌人状态
	for k in e.get("status_all", {}):
		enemy.status[k] = int(enemy.status.get(k, 0)) + int(e["status_all"][k])
	# 全场伤害
	if int(e.get("damage_all", 0)) > 0:
		var dmg := int(e["damage_all"])
		enemy.hp = max(0, enemy.hp - dmg)
		AudioManager.play("hit")
	# 中毒倍率伤害
	if int(e.get("damage_per_poison", 0)) > 0:
		var pois := int(enemy.status.get("中毒", 0))
		var dmg2 := pois * int(e["damage_per_poison"])
		enemy.hp = max(0, enemy.hp - dmg2)
		AudioManager.play("hit")
	# 烧掉手牌，每张造成伤害
	if bool(e.get("burn_hand", false)):
		var n := deck.hand.size()
		var per := int(e.get("damage_per_card", 6))
		for cid in deck.hand.duplicate():
			deck.hand.erase(cid)
			deck.discard_pile.append(cid)
		enemy.hp = max(0, enemy.hp - n * per)
		AudioManager.play("hit")
	# 按已损失生命造成伤害
	if float(e.get("damage_self_hp_pct", 0.0)) > 0.0:
		var lost := GameState.player_max_hp - player_hp
		enemy.hp = max(0, enemy.hp - int(lost * float(e["damage_self_hp_pct"])))
		AudioManager.play("hit")
	# 下回合攻击倍率
	if float(e.get("mult_next", 1.0)) > 1.0:
		player_status["力量"] = int(player_status.get("力量", 0)) + int((float(e["mult_next"]) - 1.0) * 6.0)

	_after_skill()


func _after_skill() -> void:
	_update_ui()
	_check_game_over()
	if not game_over:
		hand_view.render(deck.hand, player_energy, pending_effect, pending_selected, _new_cards)

func EmFx_appear() -> void:
	if _enemy_sprite != null and is_instance_valid(_enemy_sprite):
		EnemyFx.appear(_enemy_sprite)


func _update_ui() -> void:
	info_label.text = "能量 %d/%d" % [player_energy, max_energy]
	pile_label.text = "抽牌堆 %d　　手牌 %d　　弃牌堆 %d　　金币 %d" % [
		deck.draw_pile.size(), deck.hand.size(), deck.discard_pile.size(), GameState.gold
	]

	# 状态里混进的「格挡 / 守护」要去掉——血条已经显示了这个信息
	var clean_status := {}
	for k in player_status:
		if str(k) != "格挡" and str(k) != "守护":
			clean_status[k] = player_status[k]
	var status_txt: String = StatusSystem.text(clean_status)
	# 血条
	if _hp_bar != null:
		var mx: int = maxi(1, GameState.player_max_hp)
		_hp_bar.size.x = 180.0 * clamp(float(player_hp) / float(mx), 0.0, 1.0)
	if _block_bar != null:
		_block_bar.size.x = 180.0 * clamp(float(player_block) / 50.0, 0.0, 1.0)
	if _eblock_bar != null:
		var eb := int(enemy.status.get("守护", 0)) + int(enemy.status.get("格挡", 0))
		_eblock_bar.size.x = 276.0 * clamp(float(eb) / 50.0, 0.0, 1.0)
	if _ehp_bar != null:
		var emx: int = maxi(1, enemy.max_hp)
		_ehp_bar.size.x = 276.0 * clamp(float(enemy.hp) / float(emx), 0.0, 1.0)

	var ptext := "【玩家】\nHP: %d\n格挡: %d" % [player_hp, player_block]
	if player_detail_label != null:
		player_detail_label.text = status_txt
	if status_label != null:
		status_label.visible = false
	if pending_effect >= 0:
		ptext += "\n选择 %d 张手牌消耗（已选 %d）" % [pending_need, pending_selected.size()]
	player_label.text = ptext
	# —— 敌人 HP 变化 → 受击 / 回血 / 死亡 ——
	if _enemy_sprite != null and is_instance_valid(_enemy_sprite):
		if _last_enemy_hp >= 0 and enemy.hp < _last_enemy_hp:
			var delta: int = _last_enemy_hp - enemy.hp
			EnemyFx.hit(_enemy_sprite, delta, delta >= 15)
		elif _last_enemy_hp >= 0 and enemy.hp > _last_enemy_hp:
			EnemyFx.heal(_enemy_sprite, enemy.hp - _last_enemy_hp)
		if enemy.hp <= 0 and _last_enemy_hp > 0:
			EnemyFx.death(_enemy_sprite)
		_last_enemy_hp = enemy.hp

	# —— 玩家 HP 变化 → 受击 ——
	if _player_sprite != null and is_instance_valid(_player_sprite):
		if _last_player_hp >= 0 and player_hp < _last_player_hp:
			EnemyFx.hit(_player_sprite, _last_player_hp - player_hp, _last_player_hp - player_hp >= 15)
		elif _last_player_hp >= 0 and player_hp > _last_player_hp:
			EnemyFx.heal(_player_sprite, player_hp - _last_player_hp)
		_last_player_hp = player_hp

	# —— 敌人意图是大招 → 预警（每回合只播一次）——
	if _enemy_sprite != null and enemy.hp > 0:
		var cur_intent: int = DamageCalc.compute(enemy.intent_damage(), enemy.status, player_status)
		if cur_intent >= maxi(10, int(float(enemy.attack_power) * 2.0)) and not _telegraphed:
			_telegraphed = true
			EnemyFx.telegraph(_enemy_sprite, 2 if cur_intent >= 15 else 1)
		elif cur_intent < maxi(10, int(float(enemy.attack_power) * 2.0)):
			_telegraphed = false
		_last_intent = cur_intent

	# —— 敌人信息条跟着立绘走（居中于敌人、贴在其头顶）——
	if _info_strip != null and _enemy_sprite != null and is_instance_valid(_enemy_sprite):
		var sw: float = _enemy_sprite.size.x
		var cx: float = _enemy_sprite.position.x + sw * 0.5
		var strip_w: float = 300.0
		_info_strip.position = Vector2(cx - strip_w * 0.5, _enemy_sprite.position.y - 62.0)
		if _info_name != null:
			_info_name.position = Vector2(cx - strip_w * 0.5 + 8.0, _enemy_sprite.position.y - 58.0)
			_info_name.size = Vector2(strip_w - 16.0, 24.0)
		if _info_detail != null:
			_info_detail.position = Vector2(cx - strip_w * 0.5 + 8.0, _enemy_sprite.position.y - 26.0)
			_info_detail.size = Vector2(strip_w - 16.0, 38.0)
			# 长文本自动缩字号（13 → 11 → 10），再长就裁掉
			var dlen: int = _info_detail.text.length()
			var fs: int = 12 if dlen <= 20 else (11 if dlen <= 34 else 10)
			_info_detail.add_theme_font_size_override("font_size", fs)
			_info_detail.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
			_info_detail.clip_text = dlen > 70
		if _ehp_bar != null:
			_ehp_bar.position = Vector2(cx - strip_w * 0.5 + 8.0, _enemy_sprite.position.y - 34.0)
			_ehp_bar.size.x = (strip_w - 16.0) * clamp(float(enemy.hp) / float(maxi(1, enemy.max_hp)), 0.0, 1.0)
		if _ehp_bar_bg != null:
			_ehp_bar_bg.position = Vector2(cx - strip_w * 0.5 + 8.0, _enemy_sprite.position.y - 34.0)
			_ehp_bar_bg.size = Vector2(strip_w - 16.0, 4)

	if _enemy_sprite != null and is_instance_valid(_enemy_sprite) and _domain_label != null:
		var dw: float = 420.0
		var dcx: float = _enemy_sprite.position.x + _enemy_sprite.size.x * 0.5
		_domain_label.position = Vector2(dcx - dw * 0.5, 588.0)
		_domain_label.size = Vector2(dw, 22.0)

	_refresh_skill_btn()

	# 上：名字 + HP（血条就在这下面）
	var etext := "【%s】  HP %d" % [enemy.label_name, enemy.hp]
	combat_label.text = etext

	# 下：状态 / 领域 / 意图（血条之下）
	var edetail := ""
	var es := StatusSystem.text(enemy.status)
	if es != "":
		edetail += "状态 %s" % es
	var dtxt: String = EnemyDB.domain_text(enemy.domain)
	if dtxt != "":
		if dtxt != "" and _domain_label != null:
			_domain_label.text = "领域 // %s" % dtxt
	if enemy.hp > 0 and player_hp > 0:
		var intent := "意图：攻击 %d" % DamageCalc.compute(enemy.intent_damage(), enemy.status, player_status)
		var hit_extra := StatusSystem.text(enemy.on_hit)
		if hit_extra != "":
			intent += " + %s" % hit_extra
		if edetail != "":
			edetail += "\n"
		edetail += intent
	if enemy.hp <= 0:
		edetail += "\n你赢了！"
	elif player_hp <= 0:
		edetail += "\n你被打败了..."
	enemy_detail_label.text = edetail
	

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

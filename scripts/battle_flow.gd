extends Node
# 战斗流程（阶段 B）：发牌 / 出牌 / 结算 / 回合推进。
# 与 battle_hud.gd 同一套路：静态函数，第一个参数 b 是 battle_demo.gd 的实例。
# 约定：跨文件引用一律 preload 常量，不使用 class_name。

const BLOCK_DAMAGE_CAP := 60

# 返回本场战斗还能用几次；-1 表示不限制
static func _uses_left(b, card: String) -> int:
	var limit: int = int(CardDB.get_card(card).get("max_uses", 0))
	if limit <= 0:
		return -1
	return max(0, limit - int(b.battle_uses.get(card, 0)))

static func _mark_used(b, card: String) -> void:
	b.battle_uses[card] = int(b.battle_uses.get(card, 0)) + 1

static func _draw_cards(b, n: int) -> void:
	AudioManager.play("draw")
	if b._draw_depth >= 3:
		return
	b._draw_depth += 1

	var encounters: Array[String] = []
	var extra_draw := 0
	for card in b.deck.draw_raw(n):
		if CardDB.kind_of(card) == "encounter":
			if b._uses_left(card) == 0:
				continue
			b._mark_used(card)
			b._apply_card_effects(card)
			b.deck.discard_pile.append(card)
			encounters.append(CardDB.card_text(card).replace("\n", " "))
			Tutorial.notify("encounter_triggered")
			extra_draw += int(CardDB.get_card(card).get("draw", 0))
			if b.player_hp <= 0:
				b._check_game_over()
				b._draw_depth -= 1
				return
		else:
			b.deck.hand.append(card)
			b._new_cards += 1

	if not encounters.is_empty():
		var msg := ""
		for e in encounters:
			if msg != "":
				msg += "  |  "
			msg += e
		Toast.show_text("遭遇牌：" + msg)

	if extra_draw > 0:
		b._draw_cards(extra_draw)

	b._draw_depth -= 1

static func _apply_card_effects(b, c: String) -> void:
	var d: Dictionary = CardDB.get_card(c)
	var hits: int = d.get("hits", 1)
	var hits_key := str(d.get("hits_from_enemy_status", ""))
	if hits_key != "":
		hits = max(1, int(b.enemy.status.get(hits_key, 0)))
	var per_st_pre: Dictionary = d.get("damage_per_enemy_status", {})
	var has_scale: bool = int(d.get("damage_per_strength", 0)) > 0
	for key in per_st_pre:
		if int(per_st_pre[key]) != 0:
			has_scale = true
	if d["damage"] > 0 or d.get("damage_from_block", false) or has_scale:
		var base_damage: int = int(d["damage"])
		if d.get("damage_from_block", false):
			base_damage = min(b.player_block * int(d.get("block_damage_mult", 1)), BLOCK_DAMAGE_CAP)
		if d.get("damage_from_gold", false):
			base_damage = GameState.gold
		var per_st: Dictionary = d.get("damage_per_enemy_status", {})
		for key in per_st:
			base_damage += int(b.enemy.status.get(key, 0)) * int(per_st[key])
		if int(d.get("damage_per_strength", 0)) > 0:
			base_damage += int(b.player_status.get("力量", 0)) * int(d["damage_per_strength"])
		var ck := str(b.creed.get("key", ""))
		if ck == "first_attack_double" and not b.first_attack_used:
			base_damage *= 2
			b.first_attack_used = true
		elif ck == "first_attack_bonus" and not b.first_attack_used:
			base_damage += int(b.creed.get("value", 0))
			b.first_attack_used = true
		if ck == "no_attack_bonus" and not b.attacked_last_turn:
			base_damage = int(base_damage * int(b.creed.get("value", 150)) / 100.0)
		if ck == "low_hp_bonus" and b.player_hp * 100 / max(1, GameState.player_max_hp) < 30:
			base_damage = int(base_damage * int(b.creed.get("value", 150)) / 100.0)
		b.attacked_this_turn = true
		var per := DamageCalc.compute(base_damage, b.player_status, b.enemy.status)
		var leech := int(b.player_status.get("嗜血", 0))
		if leech > 0:
			b.player_hp = min(GameState.player_max_hp, b.player_hp + leech)
		b.enemy.hp = max(0, b.enemy.hp - per * hits)
		var clear_key := str(d.get("clear_enemy_status", ""))
		if clear_key != "":
			b.enemy.status.erase(clear_key)
		AudioManager.play("attack")
		if d.get("zero_block_after", false):
			b.player_block = 0
		elif d.get("damage_from_block", false):
			b.player_block = int(b.player_block / 2.0)
		var thorns: int = int(b.enemy.status.get("荆棘", 0))
		if thorns > 0:
			b.player_hp = max(0, b.player_hp - thorns)
			b._on_player_hurt(true)
		if str(b.enemy.domain.get("type", "")) == "attack_recoil":
			b.player_hp = max(0, b.player_hp - int(b.enemy.domain.get("value", 0)))
			b._on_player_hurt()
	var gained_block: int = int(d["block"])
	if str(b.enemy.domain.get("type", "")) == "half_block":
		gained_block = int(gained_block / 2.0)
	b.player_block += gained_block
	if d.get("poison_double", false):
		b.enemy.status["中毒"] = int(b.enemy.status.get("中毒", 0)) * 2
	if d["block"] > 0:
		Tutorial.notify("blocked")
	if d.has("status"):
		StatusSystem.apply(b.enemy.status, d["status"])
	if d.has("self_status"):
		StatusSystem.apply(b.player_status, d["self_status"])
	if d.get("skip_enemy_turn", 0) > 0:
		b.skip_enemy += int(d["skip_enemy_turn"])
	if d.get("next_energy", 0) != 0:
		b.bonus_energy += int(d["next_energy"])
	if int(d.get("heal_percent_missing", 0)) > 0:
		var missing: int = GameState.player_max_hp - b.player_hp
		var amt := int(missing * int(d["heal_percent_missing"]) / 100.0)
		if amt > 0:
			AudioManager.play("heal")
			b.player_hp = min(GameState.player_max_hp, b.player_hp + amt)
			b._on_player_hurt(false)
	if d.get("heal", 0) > 0:
		if str(b.enemy.domain.get("type", "")) != "no_heal":
			AudioManager.play("heal")
			b.player_hp = min(GameState.player_max_hp, b.player_hp + d["heal"])
	if d.get("self_damage", 0) > 0 and not b._player_immune():
		b.player_hp = max(0, b.player_hp - d["self_damage"])
		b._on_player_hurt(true)
	if d.get("gain_energy", 0) > 0:
		b.player_energy += int(d["gain_energy"])
	if d.get("retrieve_top", false):
		if not b.deck.discard_pile.is_empty():
			b.deck.hand.append(b.deck.discard_pile.pop_back())

	if CardDB.kind_of(c) == "effect":
		var ek := str(b.creed.get("key", ""))
		if ek == "effect_damage":
			b.enemy.hp = max(0, b.enemy.hp - int(b.creed.get("value", 0)))
		elif ek == "effect_draw":
			b._draw_cards(int(b.creed.get("value", 0)))

static func _on_card_pressed(b, index: int) -> void:
	if b.game_over:
		return
	if b.pending_effect >= 0:
		b._on_effect_select(index)
		return
	if index < 0 or index >= b.deck.hand.size():
		return
	var c: String = b.deck.hand[index]
	if b._uses_left(c) == 0:
		Toast.show_text("「%s」本场战斗已用完" % c, 2.0)
		return
	var d: Dictionary = CardDB.get_card(c)
	var extra_cost := int(b.enemy.domain.get("value", 0)) if str(b.enemy.domain.get("type", "")) == "cost_up" else 0
	var discount := OrganDB.total("first_discount") if not b.first_card_used else 0
	extra_cost = max(-int(d["cost"]), extra_cost - discount)
	if b.player_energy < int(d["cost"]) + extra_cost:
		var req: Dictionary = d.get("min_self_status", {})
		for k in req:
			if int(b.player_status.get(k, 0)) < int(req[k]):
				Toast.show_text("力量不足", 1.5)
				return
		return
	if CardDB.kind_of(c) == "effect" and CardDB.consume_count(c) > 0:
		if b.deck.hand.size() - 1 < CardDB.consume_count(c):
			return
		b.pending_effect = index
		b.pending_need = CardDB.consume_count(c)
		b.pending_selected.clear()
		b._render_hand()
		b._update_ui()
		return
	AudioManager.play("click")
	var spent = b.hand_view.take_button(index)
	b.player_energy -= d["cost"]
	b.last_card_played = c
	b.first_card_used = true
	AudioManager.play("play")
	b._apply_card_effects(c)
	Tutorial.notify("card_played")
	if CardDB.kind_of(c) == "effect":
		Tutorial.notify("effect_played")
	b.deck.hand.remove_at(index)
	# exhaust：本场战斗用掉就消失（不进弃牌堆）
	if not bool(d.get("exhaust", false)):
		b.deck.discard_pile.append(c)
	b._mark_used(c)
	b._check_game_over()
	b._render_hand()
	CardAnim.play_to_center(b, spent)
	b._update_ui()
	var draw_n: int = int(d.get("draw", 0))
	if draw_n > 0:
		b._draw_cards(draw_n)
	b._check_game_over()
	b._render_hand()
	b._update_ui()

static func _on_effect_select(b, index: int) -> void:
	if index == b.pending_effect:
		b.pending_effect = -1
		b.pending_need = 0
		b.pending_selected.clear()
		b._render_hand()
		b._update_ui()
		return
	if b.pending_selected.has(index):
		b.pending_selected.erase(index)
	else:
		if b.pending_selected.size() >= b.pending_need:
			return
		b.pending_selected.append(index)
	if b.pending_selected.size() == b.pending_need:
		b._resolve_effect()
		return
	b._render_hand()
	b._update_ui()

static func _resolve_effect(b) -> void:
	var idx: int = b.pending_effect
	var c: String = b.deck.hand[idx]
	AudioManager.play("click")
	b.player_energy -= CardDB.get_card(c)["cost"]
	b._apply_card_effects(c)

	var consumed: Array[String] = []
	var remove_idx: Array = [idx]
	for i in b.pending_selected:
		consumed.append(b.deck.hand[i])
		remove_idx.append(i)
	remove_idx.sort()
	remove_idx.reverse()
	var ghosts := {}
	for i in remove_idx:
		ghosts[i] = b.hand_view.take_button(i)
		b.deck.hand.remove_at(i)

	# 效果牌先进弃牌堆，消耗的牌盖在它上面
	b.deck.discard_pile.append(c)
	for card in consumed:
		b.deck.discard_pile.append(card)

	var draw_n: int = int(CardDB.get_card(c).get("draw", 0))
	if draw_n > 0:
		b._draw_cards(draw_n)

	b.pending_effect = -1
	b.pending_need = 0
	b.pending_selected.clear()
	b._check_game_over()
	b._render_hand()
	CardAnim.play_to_center(b, ghosts.get(idx))
	for i in remove_idx:
		if i != idx:
			CardAnim.discard_to(b, ghosts.get(i), Vector2(140, 655))
	b._update_ui()

# ===== 回合流程（分阶段）=====
static func _on_end_turn_pressed(b) -> void:
	if b._ending_turn:
		return
	Tutorial.notify("turn_ended")
	if b.game_over or b.pending_effect >= 0:
		return
	# 防连点：这一帧内不再接受结束回合
	b._ending_turn = true
	if b.end_turn_button != null:
		b.end_turn_button.disabled = true
	b._end_player_turn()
	if b.skip_enemy > 0:
		b.skip_enemy -= 1
		Toast.show_text("你的威严使他退却", 2.0)
		b._start_new_turn()
	else:
		b._resolve_enemy_turn()
	b._check_game_over()
	b._update_ui()
	if b.game_over:
		b._ending_turn = false
		if b.end_turn_button != null:
			b.end_turn_button.disabled = false
		return
	b._start_new_turn()
	# 下一帧才恢复（挡住同一帧内的连点）
	b.get_tree().create_timer(0.25).timeout.connect(func() -> void:
		b._ending_turn = false
		if b.end_turn_button != null and not b.game_over:
			b.end_turn_button.disabled = false
	)

static func _end_player_turn(b) -> void:
	# 回合结束：手牌全部弃掉，下回合重新抽
	for card in b.deck.hand:
		b.deck.discard_pile.append(str(card))
	b.deck.hand.clear()

	var pp := StatusSystem.tick_damage(b.player_status)
	if pp > 0:
		b.player_hp = max(0, b.player_hp - pp)
		b._on_player_hurt()
	var ph := StatusSystem.tick_heal(b.player_status)
	if ph > 0:
		b.player_hp = min(GameState.player_max_hp, b.player_hp + ph)

static func _player_immune(b) -> bool:
	return b.player_status.has("恒光")

static func _on_player_hurt(b, now: bool = false) -> void:
	AudioManager.play("hurt")
	if str(b.creed.get("key", "")) != "hurt_energy":
		return
	var v := int(b.creed.get("value", 0))
	if now:
		b.player_energy += v
		b._update_ui()
	else:
		b.bonus_energy += v

static func _resolve_enemy_turn(b) -> void:
	# 敌人出手：先扑一下再结算伤害（不 await，动画和结算并行）
	if b.enemy.intent_damage() > 0:
		EnemyFx.attack(b._enemy_sprite)
	var raw_dmg := DamageCalc.compute(b.enemy.intent_damage(), b.enemy.status, b.player_status)
	var absorbed: int = min(b.player_block, raw_dmg)
	b.player_block = max(0, b.player_block - absorbed)
	var dmg: int = max(0, raw_dmg - absorbed)
	b._update_ui()   # 格挡变化后立刻刷新
	if dmg > 0 and int(b.player_status.get("护佑", 0)) > 0:
		b.player_status["护佑"] = int(b.player_status["护佑"]) - 1
		if int(b.player_status["护佑"]) <= 0:
			b.player_status.erase("护佑")
		dmg = 0
	if b._player_immune():
		dmg = 0
	var hk := str(b.creed.get("key", ""))
	if dmg > 0 and hk == "first_hurt_half" and not b.first_hurt_used:
		b.first_hurt_used = true
		dmg = int(dmg / 2.0)
	if dmg > 0 and hk == "first_hurt_zero" and not b.first_hurt_used:
		b.first_hurt_used = true
		dmg = 0
	b.damage_taken += dmg
	b.player_hp = max(0, b.player_hp - dmg)
	if dmg > 0:
		var reflect := int(b.player_status.get("反弹", 0))
		if reflect > 0:
			b.enemy.hp = max(0, b.enemy.hp - reflect)
		var fury := int(b.player_status.get("狂怒", 0))
		if fury > 0:
			b.player_status["力量"] = int(b.player_status.get("力量", 0)) + fury
		Tutorial.notify("hurt")
	if not b.player_status.has("坚守"):
		b.player_block = 0
		b._update_ui()   # 清空后也刷一次
	if dmg > 0:
		b._on_player_hurt()
	b.enemy.turn_index += 1

	var ep := StatusSystem.tick_damage(b.enemy.status)
	if ep > 0:
		b.enemy.hp = max(0, b.enemy.hp - ep)

	# 毒性增长（挂在敌人身上）：毒伤结算之后，每 4 层额外 +1
	if b.enemy.status.has("毒性增长"):
		var pz := int(b.enemy.status.get("中毒", 0))
		if pz >= 4:
			b.enemy.status["中毒"] = pz + int(float(pz) / 4.0)

	var eh := StatusSystem.tick_heal(b.enemy.status)
	if eh > 0:
		b.enemy.hp = min(b.enemy.max_hp, b.enemy.hp + eh)

	StatusSystem.decay(b.player_status)
	StatusSystem.decay(b.enemy.status)

	if not b.enemy.on_turn.is_empty():
		EnemyFx.buff(b._enemy_sprite)
		StatusSystem.apply(b.enemy.status, b.enemy.on_turn)
	if not b.enemy.on_hit.is_empty():
		StatusSystem.apply(b.player_status, b.enemy.on_hit)

	for s in b.enemy.due_skills():
		if s.has("heal"):
			b.enemy.hp = min(b.enemy.max_hp, b.enemy.hp + int(s["heal"]))
		if s.has("status"):
			var st: Dictionary = s["status"]
			if str(s.get("to", "player")) == "self":
				EnemyFx.buff(b._enemy_sprite)
				StatusSystem.apply(b.enemy.status, st)
			else:
				StatusSystem.apply(b.player_status, st)
	if str(b.enemy.domain.get("type", "")) == "enemy_regen":
		b.enemy.hp = min(b.enemy.max_hp, b.enemy.hp + int(b.enemy.domain.get("value", 0)))

static func _apply_turn_creed(b) -> void:
	b.first_attack_used = false
	b.first_card_used = false
	b.attacked_this_turn = false
	if str(b.creed.get("key", "")) == "turn_block":
		b.player_block += int(b.creed.get("value", 0))

static func _domain_tick(b) -> void:
	var t := str(b.enemy.domain.get("type", ""))
	var v := int(b.enemy.domain.get("value", 0))
	match t:
		"damage_aura":
			b.player_hp = max(0, b.player_hp - v)
		"weak_aura":
			b.player_status["虚弱"] = int(b.player_status.get("虚弱", 0)) + v
		"bleed_aura":
			b.player_status["流血"] = int(b.player_status.get("流血", 0)) + v
		"block_decay":
			b.player_block = max(0, b.player_block - v)
		"poison_aura":
			b.player_status["中毒"] = int(b.player_status.get("中毒", 0)) + v

static func _start_new_turn(b) -> void:
	b._turn_no += 1
	if not b.attacked_this_turn:
		b._no_attack_turns += 1
	else:
		b._no_attack_turns = 0
	b.attacked_this_turn = false
	b._domain_tick()
	if b.game_over:
		return
	for f in b.ally_fighters:
		b.enemy.hp = max(0, b.enemy.hp - int(f["damage"]))
	if not b.ally_fighters.is_empty():
		AudioManager.play("hit")
	b._check_game_over()
	if b.game_over:
		return
	if b.node_type == "tutorial":
		Tutorial.advance()
		for c in Tutorial.cards_for(Tutorial.turn):
			var cn := str(c)
			if CardDB.kind_of(cn) == "encounter":
				b._apply_card_effects(cn)
				b.deck.discard_pile.append(cn)
				Toast.show_text("遭遇牌：" + CardDB.card_text(cn).replace("\n", " "))
			else:
				b.deck.hand.append(cn)
				b._new_cards += 1
	else:
		var draw_count: int = RunConfig.BASE_DRAW + b.player_energy + OrganDB.total("draw") + GameState.wealth_draw
		draw_count += int(b.player_status.get("洞察", 0))
		draw_count = max(0, draw_count - int(b.player_status.get("迟钝", 0)))
		var dt := str(b.enemy.domain.get("type", ""))
		if dt == "draw_penalty" or dt == "less_draw":
			draw_count = max(0, draw_count - int(b.enemy.domain.get("value", 0)))
		if draw_count > 0:
			b._draw_cards(draw_count)
	b.player_energy = b.max_energy + b.bonus_energy
	b.bonus_energy = 0
	b.player_energy += int(b.player_status.get("迅捷", 0))
	b.player_energy = max(0, b.player_energy - int(b.player_status.get("重力", 0)))
	if b.player_status.has("狂化"):
		b.player_status["力量"] = int(b.player_status.get("力量", 0)) + 2
	if str(b.enemy.domain.get("type", "")) == "energy_drain":
		b.player_energy = max(0, b.player_energy - int(b.enemy.domain.get("value", 0)))
	var guard := int(b.player_status.get("守护", 0))
	if guard > 0:
		b.player_block += guard
	b._apply_turn_creed()
	var burn := int(b.player_status.get("炽热", 0))
	if burn > 0:
		b.enemy.hp = max(0, b.enemy.hp - burn)
	b.attacked_last_turn = b.attacked_this_turn
	b._render_hand()
	b._update_ui()

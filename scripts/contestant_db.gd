extends Node

const IMPRESSION_SCALE := 4

const CONTESTANTS := ContestantData.CONTESTANTS

const MEET_LINES := ContestantData.MEET_LINES

# 好感 ≥ 70：可以结盟、可以收礼
const BOND_CHOICES := ContestantData.BOND_CHOICES

# 好感 30~69：可以做交易
const FRIEND_CHOICES := ContestantData.FRIEND_CHOICES

# 好感 -29~29：互相试探
const NEUTRAL_CHOICES := ContestantData.NEUTRAL_CHOICES

# 好感 -69~-30：敌意，但还能退
const HOSTILE_CHOICES := ContestantData.HOSTILE_CHOICES

func get_contestant(id: String) -> Dictionary:
	return CONTESTANTS[id]

func name_of(id: String) -> String:
	return CONTESTANTS[id]["name"]

func resolve_cards(reward: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if reward.has("cards"):
		for c in reward["cards"]:
			result.append(str(c))
	if reward.has("random_cards"):
		var count: int = int(reward["random_cards"])
		var pool: Array = CardDB.reward_pool()
		for i in range(count):
			result.append(str(pool[randi() % pool.size()]))
	return result

func pick_roster(count: int) -> Array[String]:
	var pool: Array = []
	for id in CONTESTANTS.keys():
		# 已经死掉 / 已经自愿退赛的人不会再出现在这一局里
		if GameState.eliminated.has(str(id)):
			continue
		if GameState.retired.has(str(id)):
			continue
		pool.append(id)
	pool.shuffle()
	var result: Array[String] = []
	for i in range(min(count, pool.size())):
		result.append(pool[i])
	return result
func scaled(id: String) -> Dictionary:
	var c: Dictionary = CONTESTANTS[id].duplicate()
	var mult: float = 1.0 + 0.08 * float(GameState.transmigration - 1)
	var result := c.duplicate()
	result["hp"] = int(float(c["hp"]) * mult)
	result["attack"] = int(float(c["attack"]) * mult)
	return result
# 立场：evil / good / neutral（也可以在某位参赛者里写 "tendency" 覆盖）
func tendency_of(id: String) -> String:
	var c: Dictionary = CONTESTANTS.get(id, {})
	if c.has("tendency"):
		return str(c["tendency"])
	var t := str(c.get("trait", ""))
	if t in ["好战", "狡诈", "贪婪", "疯狂"]:
		return "evil"
	if t in ["虔诚", "虚弱"]:
		return "good"
	return "neutral"

# 本次选择对印象的影响
func impression_delta(id: String, choice: Dictionary) -> int:
	var f: int = int(choice.get("favor", 0))
	if str(choice.get("result", "talk")) == "talk":
		f = max(f, 9)
	var d: int = f * IMPRESSION_SCALE
	if str(choice.get("result", "talk")) == "fight":
		d -= 20 * IMPRESSION_SCALE
	if choice.get("ally", false):
		d += 20 * IMPRESSION_SCALE
	var tendency := tendency_of(id)
	var moral_part: int = int((GameState.morality - 50) / 10.0) * IMPRESSION_SCALE
	var sin_part: int = int(GameState.sin / 10.0) * IMPRESSION_SCALE
	if tendency == "good":
		d += moral_part - sin_part
	elif tendency == "evil":
		d += sin_part - moral_part
	return d

# 第 meet 次遇见的场景（0 = 初次）
func scene_for(id: String, meet: int) -> Dictionary:
	var c: Dictionary = CONTESTANTS[id]
	if meet <= 0:
		return {"text": str(c["desc"]), "choices": c["choices"]}

	var imp: int = int(GameState.impressions.get(id, 0))
	var lines: Dictionary = MEET_LINES.get(id, {})

	if imp >= 70:
		var bond_choices: Array = BOND_CHOICES
		if c.has("bond"):
			bond_choices = [c["bond"]]
		return {"text": _meet_line(lines, "good", c), "choices": bond_choices}
	if imp >= 30:
		return {"text": _meet_line(lines, "good", c), "choices": FRIEND_CHOICES}
	if imp <= -70:
		return {"text": _meet_line(lines, "bad", c), "choices": HOSTILE_CHOICES, "auto_fight": true}
	if imp <= -30:
		return {"text": _meet_line(lines, "bad", c), "choices": HOSTILE_CHOICES}
	return {"text": _meet_line(lines, "neutral", c), "choices": NEUTRAL_CHOICES}

var _last_meet := {}

# ============================================================
# 物品 ↔ 英雄（物品系统的交互入口）
# ------------------------------------------------------------
# 好感存在 GameState.impressions[id]，和现有的遇见系统共用同一个数值。
# ============================================================

# 能劝退的好感门槛
const RETIRE_FAVOR := 60


func favor_of(id: String) -> int:
	return int(GameState.impressions.get(id, 0))


# 送一件物品：加好感，返回要给玩家看的话
func give_item(id: String, item_id: String) -> Dictionary:
	if not ItemDB.can_give_to_hero(item_id):
		return {"ok": false, "text": "他没接。"}
	if Inventory.item_count(item_id) <= 0:
		return {"ok": false, "text": "你没有这件东西。"}
	Inventory.take_item(item_id, 1)
	var add: int = ItemDB.favor_of(item_id)
	var before := favor_of(id)
	GameState.impressions[id] = before + add
	GameState.save_game()
	var text := "他收下了%s。" % ItemDB.name_of(item_id)
	if add != 0:
		text += "（好感 %+d）" % add
	if before < RETIRE_FAVOR and before + add >= RETIRE_FAVOR:
		text += "\n「……你还有事要我帮忙吗。」"
	return {"ok": true, "favor": add, "text": text}


func can_retire(id: String) -> bool:
	return favor_of(id) >= RETIRE_FAVOR and not GameState.retired.has(id)


# 让英雄自愿退出比赛：不再参与守门人之后的清算，本局之后也不再出现在事件里
func retire(id: String) -> bool:
	if not can_retire(id):
		return false
	if not GameState.retired.has(id):
		GameState.retired.append(id)
	# 结盟中的也一起撤掉，避免清算时重复
	GameState.allies.erase(id)
	GameState.save_game()
	return true


func _meet_line(lines: Dictionary, tier: String, c: Dictionary) -> String:
	var v = lines.get(tier, "")
	if v is Array:
		var arr: Array = v
		if arr.is_empty():
			return "「%s」看了你一眼。" % str(c["name"])
		var key := str(c["name"]) + "_" + tier
		var idx: int = randi() % arr.size()
		if arr.size() > 1 and int(_last_meet.get(key, -1)) == idx:
			idx = (idx + 1) % arr.size()
		_last_meet[key] = idx
		return str(arr[idx])
	var t := str(v)
	if t == "":
		return "「%s」看了你一眼。" % str(c["name"])
	return t

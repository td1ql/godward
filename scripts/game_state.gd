extends Node

const SAVE_VERSION := 2

const SLOT_COUNT := 3

var player_hp: int = 50
var player_max_hp: int = 50
var gold: int = 100
var current_node_id: int = 0
var map_nodes: Dictionary = {}
var map_generated: bool = false
var deck: Array[String] = []
var current_slot := 0
var pending_node: int = -1
var pending_snapshot: Dictionary = {}
var transmigration := 1
var traits: Array[String] = []
var vocation := ""
var vocation_history: Array[String] = []
var contestants: Array[String] = []
var met_contestants: Array[String] = []
var eliminated: Array[String] = []
var allies: Array[String] = []
var pending_enemy: Dictionary = {}
var pending_contestant: String = ""
var pending_cleanup := false
var act := 1
var streams: Array[String] = []
var prologue_seen := false
var milestone_card := false
var milestone_discard := false
var morality := 50
var sin := 0
var impressions := {}
var meet_count := {}
var energy_bonus := 0

func _ready() -> void:
	reset_deck()

func reset_deck() -> void:
	deck.clear()
	for i in range(4):
		deck.append("打击")
	for i in range(4):
		deck.append("防御")
	for c in TraitDB.deck_of(vocation):
		deck.append(str(c))

func _roll_streams() -> Array[String]:
	var result: Array[String] = []
	for c in TraitDB.deck_of(vocation):
		for s in CardDB.streams_of(c):
			if not result.has(s):
				result.append(s)
	result.shuffle()
	while result.size() > 2:
		result.pop_back()

	var all: Array = CardDB.STREAMS.duplicate()
	all.shuffle()
	for s in all:
		if not result.has(str(s)):
			result.append(str(s))
			break
	return result

func reset_run() -> void:
	Morality.reset()
	prologue_seen = false
	transmigration = 1
	energy_bonus = 0
	vocation_history.clear()
	impressions.clear()
	meet_count.clear()
	_roll_vocation()

func advance_transmigration() -> void:
	transmigration += 1
	if vocation != "":
		vocation_history.append(vocation)
	_roll_vocation()

func _roll_vocation() -> void:
	var pool: Array = TraitDB.VOCATIONS.keys()
	var fresh: Array = []
	for v in pool:
		if not vocation_history.has(str(v)):
			fresh.append(v)
	if fresh.is_empty():
		fresh = pool
	vocation = str(fresh[randi() % fresh.size()])
	traits = TraitDB.traits_of(vocation)
	_apply_traits()

func restart_run() -> void:
	_apply_traits()

func _apply_traits() -> void:
	player_max_hp = recompute_max_hp()
	player_hp = player_max_hp
	gold = max(0, RunConfig.START_GOLD + TraitDB.total_gold(traits) + (transmigration - 1) * RunConfig.META_GOLD_PER_RUN)
	if transmigration >= 9:
		gold += 50
	current_node_id = 0
	map_generated = false
	map_nodes.clear()
	reset_deck()
	streams = _roll_streams()
	for c in TraitDB.bonus_cards(traits):
		deck.append(c)
	contestants = ContestantDB.pick_roster(5)
	met_contestants.clear()
	eliminated.clear()
	act = 1
	pending_cleanup = false
	pending_node = -1
	pending_snapshot = {}
	pending_contestant = ""
	pending_enemy = {}
	milestone_card = false
	milestone_discard = false
	allies.clear()

func initial_hand_size() -> int:
	return max(1, RunConfig.HAND_SIZE + TraitDB.total_hand(traits))

func initial_energy() -> int:
	return max(1, RunConfig.MAX_ENERGY + TraitDB.total_energy(traits) + energy_bonus)

func recompute_max_hp() -> int:
	var hp: int = max(10, RunConfig.START_HP + TraitDB.total_hp(traits) + (transmigration - 1) * RunConfig.META_HP_PER_RUN)
	if transmigration >= 10:
		hp += 20
	return hp

func _slot_path(slot: int) -> String:
	return "user://save_%d.txt" % slot

func save_game() -> void:
	var data := {
		"energy_bonus": energy_bonus,
		"streams": streams,
		"save_version": SAVE_VERSION,
		"impressions": impressions,
		"meet_count": meet_count,
		"morality": morality,
		"sin": sin,
		"prologue_seen": prologue_seen,
		"player_max_hp": player_max_hp,
		"vocation_history": vocation_history,
		"milestone_card": milestone_card,
		"milestone_discard": milestone_discard,
		"pending_cleanup": pending_cleanup,
		"vocation": vocation,
		"pending_snapshot": pending_snapshot,
		"pending_contestant": pending_contestant,
		"pending_node": pending_node,
		"player_hp": player_hp,
		"gold": gold,
		"current_node_id": current_node_id,
		"map_generated": map_generated,
		"map_nodes": map_nodes,
		"deck": deck,
		"transmigration": transmigration,
		"traits": traits,
		"contestants": contestants,
		"met_contestants": met_contestants,
		"eliminated": eliminated,
		"allies": allies,
	}
	var f := FileAccess.open(_slot_path(current_slot), FileAccess.WRITE)
	if f:
		f.store_string(var_to_str(data))
		f.close()

func has_save(slot: int = -1) -> bool:
	var s: int = slot if slot >= 0 else current_slot
	return FileAccess.file_exists(_slot_path(s))

func load_game(slot: int = -1) -> bool:
	var s: int = slot if slot >= 0 else current_slot
	if not FileAccess.file_exists(_slot_path(s)):
		return false
	var f := FileAccess.open(_slot_path(s), FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var data = str_to_var(text)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	vocation_history.clear()
	for v in data.get("vocation_history", []):
		vocation_history.append(str(v))
	player_hp = int(data.get("player_hp", player_max_hp))
	gold = int(data.get("gold", 100))
	current_node_id = int(data.get("current_node_id", 0))
	map_generated = bool(data.get("map_generated", false))
	map_nodes = data.get("map_nodes", {})
	deck.clear()
	for c in data.get("deck", []):
		deck.append(str(c))
	transmigration = int(data.get("transmigration", 1))
	traits.clear()
	for t in data.get("traits", []):
		traits.append(str(t))
	contestants.clear()
	for c in data.get("contestants", []):
		contestants.append(str(c))
	met_contestants.clear()
	for c in data.get("met_contestants", []):
		met_contestants.append(str(c))
	eliminated.clear()
	for c in data.get("eliminated", []):
		eliminated.append(str(c))
	allies.clear()
	for c in data.get("allies", []):
		allies.append(str(c))
	morality = int(data.get("morality", Morality.START_MORAL))
	sin = int(data.get("sin", Morality.START_SIN))
	energy_bonus = int(data.get("energy_bonus", 0))
	impressions = data.get("impressions", {})
	meet_count = data.get("meet_count", {})
	prologue_seen = bool(data.get("prologue_seen", false))
	act = int(data.get("act", 1))
	milestone_card = bool(data.get("milestone_card", false))
	milestone_discard = bool(data.get("milestone_discard", false))
	pending_node = int(data.get("pending_node", -1))
	pending_snapshot = data.get("pending_snapshot", {})
	pending_contestant = str(data.get("pending_contestant", ""))
	pending_cleanup = bool(data.get("pending_cleanup", false))
	vocation = str(data.get("vocation", ""))
	if vocation == "":
		vocation = TraitDB.roll_vocation()
		traits = TraitDB.traits_of(vocation)
	if data.has("player_max_hp"):
		player_max_hp = int(data["player_max_hp"])
	else:
		player_max_hp = recompute_max_hp()
	var ver: int = int(data.get("save_version", 1))
	if ver < SAVE_VERSION:
		_migrate_v1(data)
	current_slot = s
	streams.clear()
	for st in data.get("streams", []):
		streams.append(str(st))
	if streams.is_empty():
		streams = _roll_streams()
	return true

# 把 v1 存档升级到 v2
func _migrate_v1(data: Dictionary) -> void:
	# v1 没有职业和词条 → 补一个
	if vocation == "":
		vocation = TraitDB.roll_vocation()
		traits = TraitDB.traits_of(vocation)

	# v1 没有最大生命字段 → 按当前职业重算
	if not data.has("player_max_hp"):
		player_max_hp = recompute_max_hp()

	# 夹一下当前血量，防止超过上限
	player_hp = clamp(player_hp, 1, player_max_hp)

	# v1 没有道德/罪恶 → 用默认值
	if not data.has("morality"):
		morality = 50
	if not data.has("sin"):
		sin = 0

func delete_save(slot: int = -1) -> void:
	var s: int = slot if slot >= 0 else current_slot
	if FileAccess.file_exists(_slot_path(s)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_slot_path(s)))

func slot_summary(slot: int) -> String:
	if not FileAccess.file_exists(_slot_path(slot)):
		return "空"
	var f := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if f == null:
		return "空"
	var text := f.get_as_text()
	f.close()
	var data = str_to_var(text)
	if typeof(data) != TYPE_DICTIONARY:
		return "空"
	return "第 %d 次转生 · HP %d · 金币 %d" % [
		int(data.get("transmigration", 1)),
		int(data.get("player_hp", 0)),
		int(data.get("gold", 0)),
	]

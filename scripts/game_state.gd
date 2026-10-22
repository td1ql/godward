extends Node

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
var milestone_card := false
var milestone_discard := false

func _ready() -> void:
	reset_deck()

func reset_deck() -> void:
	deck = CardDB.starter_deck(RunConfig.DECK_SIZE)

func reset_run() -> void:
	transmigration = 1
	vocation_history.clear()
	_roll_vocation()

func advance_transmigration() -> void:
	transmigration += 1
	if vocation != "":
		vocation_history.append(vocation)
	_roll_vocation()

func _roll_vocation() -> void:
	vocation = TraitDB.roll_vocation()
	traits = TraitDB.traits_of(vocation)
	_apply_traits()

func restart_run() -> void:
	_apply_traits()

func _apply_traits() -> void:
	player_max_hp = max(10, RunConfig.START_HP + TraitDB.total_hp(traits))
	if transmigration >= 10:
		player_max_hp += 20
	player_hp = player_max_hp
	gold = max(0, RunConfig.START_GOLD + TraitDB.total_gold(traits))
	if transmigration >= 9:
		gold += 50
	current_node_id = 0
	map_generated = false
	map_nodes.clear()
	reset_deck()
	for c in TraitDB.bonus_cards(traits):
		deck.append(c)
	contestants = ContestantDB.pick_roster(5)
	met_contestants.clear()
	eliminated.clear()
	act = 1
	pending_cleanup = false
	pending_node = -1
	pending_snapshot = {}
	milestone_card = false
	milestone_discard = false
	allies.clear()

func initial_hand_size() -> int:
	return max(1, RunConfig.HAND_SIZE + TraitDB.total_hand(traits))

func initial_energy() -> int:
	return max(1, RunConfig.MAX_ENERGY + TraitDB.total_energy(traits))

func _slot_path(slot: int) -> String:
	return "user://save_%d.txt" % slot

func save_game() -> void:
	var data := {
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
	act = int(data.get("act", 1))
	milestone_card = bool(data.get("milestone_card", false))
	milestone_discard = bool(data.get("milestone_discard", false))
	pending_node = int(data.get("pending_node", -1))
	pending_snapshot = data.get("pending_snapshot", {})
	pending_contestant = str(data.get("pending_contestant", ""))
	pending_cleanup = bool(data.get("pending_cleanup", false))
	vocation = str(data.get("vocation", ""))
	current_slot = s
	return true

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

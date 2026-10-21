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

func _ready() -> void:
	reset_deck()

func reset_deck() -> void:
	deck = CardDB.starter_deck(RunConfig.DECK_SIZE)

func reset_run() -> void:
	player_max_hp = RunConfig.START_HP
	player_hp = player_max_hp
	gold = RunConfig.START_GOLD
	current_node_id = 0
	map_generated = false
	map_nodes.clear()
	reset_deck()

func _slot_path(slot: int) -> String:
	return "user://save_%d.txt" % slot

func save_game() -> void:
	var data := {
		"player_hp": player_hp,
		"gold": gold,
		"current_node_id": current_node_id,
		"map_generated": map_generated,
		"map_nodes": map_nodes,
		"deck": deck,
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
	player_hp = int(data.get("player_hp", player_max_hp))
	gold = int(data.get("gold", 100))
	current_node_id = int(data.get("current_node_id", 0))
	map_generated = bool(data.get("map_generated", false))
	map_nodes = data.get("map_nodes", {})
	deck.clear()
	for c in data.get("deck", []):
		deck.append(str(c))
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
	return "HP %d · 金币 %d" % [int(data.get("player_hp", 0)), int(data.get("gold", 0))]

extends Node

const SAVE_PATH := "user://save.txt"

var player_hp: int = 50
var player_max_hp: int = 50
var gold: int = 100
var current_node_id: int = 0
var map_nodes: Dictionary = {}
var map_generated: bool = false
var deck: Array[String] = []

func _ready() -> void:
	reset_deck()

func reset_deck() -> void:
	deck = CardDB.starter_deck()

func reset_run() -> void:
	player_hp = player_max_hp
	gold = 100
	current_node_id = 0
	map_generated = false
	map_nodes.clear()
	reset_deck()

func save_game() -> void:
	var data := {
		"player_hp": player_hp,
		"gold": gold,
		"current_node_id": current_node_id,
		"map_generated": map_generated,
		"map_nodes": map_nodes,
		"deck": deck,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(var_to_str(data))
		f.close()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
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
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

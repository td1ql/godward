extends Node

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
	deck.clear()
	var card_ids := ["打击", "防御", "重击", "铁壁", "疾风斩"]
	for i in range(20):
		deck.append(card_ids[i % card_ids.size()])

func reset_run() -> void:
	player_hp = player_max_hp
	gold = 100
	current_node_id = 0
	map_generated = false
	map_nodes.clear()
	reset_deck()

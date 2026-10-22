class_name EnemyState
extends RefCounted

var hp := 0
var max_hp := 0
var attack_power := 0
var status := {}
var on_hit := {}
var on_turn := {}
var pattern: Array = [1]
var label_name := "敌人"
var turn_index := 0

func setup(data: Dictionary) -> void:
	hp = int(data["hp"])
	max_hp = hp
	attack_power = int(data["attack"])
	label_name = str(data["name"])
	pattern = data.get("pattern", [1])
	on_hit = data.get("on_hit", {})
	on_turn = data.get("on_turn", {})
	status = {}
	turn_index = 0

func intent_damage() -> int:
	if pattern.is_empty():
		return attack_power
	return attack_power * int(pattern[turn_index % pattern.size()])

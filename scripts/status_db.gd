extends Node

const STATUS := {
	"中毒": {"name": "中毒", "tick_damage": true, "decay": 1},
	"流血": {"name": "流血", "tick_damage": true, "decay": 1},
	"虚弱": {"name": "虚弱", "tick_damage": false, "decay": 1},
	"易伤": {"name": "易伤", "tick_damage": false, "decay": 1},
	"力量": {"name": "力量", "tick_damage": false, "decay": 1},
	"再生": {"name": "再生", "tick_damage": false, "tick_heal": true, "decay": 1},
	"荆棘": {"name": "荆棘", "tick_damage": false, "decay": 1},
}

func name_of(id: String) -> String:
	return STATUS[id]["name"]

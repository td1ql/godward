extends Node

# tick_damage: 回合结束是否按层数造成伤害
# decay      : 每回合衰减层数（0 = 不衰减）
const STATUS := {
	"中毒": {"name": "中毒", "tick_damage": true, "decay": 1},
	"虚弱": {"name": "虚弱", "tick_damage": false, "decay": 1},
	"易伤": {"name": "易伤", "tick_damage": false, "decay": 1},
	"力量": {"name": "力量", "tick_damage": false, "decay": 0},
}

func name_of(id: String) -> String:
	return STATUS[id]["name"]

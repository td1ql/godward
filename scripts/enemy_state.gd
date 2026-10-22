class_name EnemyState
extends RefCounted
#"skills": [
#	{"every": 2, "to": "player", "status": {"中毒": 2}, "name": "毒牙"},
#	{"every": 3, "to": "self",   "status": {"力量": 2}, "name": "狂暴"},
#	{"every": 4, "to": "self",   "heal": 10,           "name": "再生"},
#     ]
# every	每 N 回合触发一次（1 = 每回合）
# to	"player" 给玩家挂状态 / "self" 给自己挂
# status	要挂的状态字典
# heal	回复自己多少血
# name	技能名（显示用）

var hp := 0
var max_hp := 0
var attack_power := 0
var status := {}
var on_hit := {}
var on_turn := {}
var skills: Array = []
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
	skills = data.get("skills", [])
	status = {}
	turn_index = 0

func intent_damage() -> int:
	if pattern.is_empty():
		return attack_power
	return attack_power * int(pattern[turn_index % pattern.size()])

# 计算本回合该触发的技能（every = 冷却回合数）
func due_skills() -> Array:
	var result := []
	for s in skills:
		var every: int = max(1, int(s.get("every", 1)))
		if turn_index % every == 0:
			result.append(s)
	return result

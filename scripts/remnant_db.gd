extends Node

const REMNANTS := [
	{"name": "第 2 次转生的你", "text": "她背对着你，还在等一个不会回来的人。", "cards": ["急救"], "hp": 10},
	{"name": "第 3 次转生的你", "text": "他握着断掉的剑，眼睛却还亮着。", "cards": ["火球"]},
	{"name": "第 5 次转生的你", "text": "她把自己的护符塞进你手里，什么也没说。", "cards": ["铁壁"], "hp": 8},
	{"name": "第 7 次转生的你", "text": "他笑了笑：「这次别死在门口。」", "gold": 60},
	{"name": "第 8 次转生的你", "text": "她靠坐在墙边，像睡着了一样。", "cards": ["重击"], "gold": 20},
	{"name": "第 9 次转生的你", "text": "他只剩一只手，却还攥着牌。", "cards": ["快速思考"], "hp": 12},
]

func pick() -> Dictionary:
	return REMNANTS[randi() % REMNANTS.size()]

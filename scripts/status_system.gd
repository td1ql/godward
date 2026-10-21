class_name StatusSystem
extends RefCounted

static func apply(target: Dictionary, st: Dictionary) -> void:
	for key in st:
		target[key] = int(target.get(key, 0)) + int(st[key])

static func tick_damage(st: Dictionary) -> int:
	var total := 0
	for key in st.keys():
		var rule: Dictionary = StatusDB.STATUS.get(key, {})
		if rule.get("tick_damage", false):
			total += int(st[key])
	return total

static func decay(st: Dictionary) -> void:
	var to_erase: Array = []
	for key in st.keys():
		var rule: Dictionary = StatusDB.STATUS.get(key, {})
		var d: int = int(rule.get("decay", 0))
		if d <= 0:
			continue
		st[key] = int(st[key]) - d
		if st[key] <= 0:
			to_erase.append(key)
	for key in to_erase:
		st.erase(key)

static func text(st: Dictionary) -> String:
	var s := ""
	for key in st:
		if s != "":
			s += " "
		s += "%s%d" % [key, st[key]]
	return s

class_name DamageCalc

static func compute(base: int, attacker: Dictionary, target: Dictionary) -> int:
	var dmg := float(base) + float(attacker.get("力量", 0))
	if attacker.get("虚弱", 0) > 0:
		dmg *= 0.75
	if target.get("易伤", 0) > 0:
		dmg *= 1.5
	return max(0, int(floor(dmg)))

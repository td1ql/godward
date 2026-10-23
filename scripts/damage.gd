class_name DamageCalc

static func compute(base: int, attacker: Dictionary, target: Dictionary) -> int:
	var dmg := float(base) + float(attacker.get("力量", 0))
	if attacker.get("虚弱", 0) > 0:
		dmg *= 0.75
	if target.get("易伤", 0) > 0:
		dmg *= 1.5
	# 流血：易伤结算之后，额外加上目标身上的流血层数
	dmg += float(target.get("流血", 0))
	return max(0, int(floor(dmg)))

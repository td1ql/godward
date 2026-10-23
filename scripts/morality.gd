# ============================================================
# Morality —— 道德 / 罪恶
# ------------------------------------------------------------
# 取值范围 0~100：
#   道德：行善、饶恕、给予
#   罪恶：杀戮、掠夺、欺骗
#
# 独立模块：所有加减、判定、文案都集中在这里。
# ============================================================

class_name Morality

const START_MORAL := 50
const START_SIN := 0
const MAX_VALUE := 100

static func reset() -> void:
	GameState.morality = START_MORAL
	GameState.sin = START_SIN

static func add(moral_delta: int, sin_delta: int) -> String:
	GameState.morality = clamp(GameState.morality + moral_delta, 0, MAX_VALUE)
	GameState.sin = clamp(GameState.sin + sin_delta, 0, MAX_VALUE)
	var parts: Array[String] = []
	if moral_delta != 0:
		parts.append("道德 %s%d" % ["+" if moral_delta >= 0 else "", moral_delta])
	if sin_delta != 0:
		parts.append("罪恶 %s%d" % ["+" if sin_delta >= 0 else "", sin_delta])
	return "　".join(parts)

static func summary() -> String:
	return "道德 %d　罪恶 %d" % [GameState.morality, GameState.sin]

# 净倾向：正数偏善，负数偏恶
static func balance() -> int:
	return GameState.morality - GameState.sin

static func title() -> String:
	if GameState.sin >= 70:
		return "罪人"
	if is_saint():
		return "有德者"
	var b := balance()
	if b >= 20:
		return "向善"
	if b <= -20:
		return "堕落"
	return "凡人"

static func is_saint() -> bool:
	return GameState.morality >= 70 and GameState.sin <= 20

static func is_sinner() -> bool:
	return GameState.sin >= 70

static func meets(data: Dictionary) -> bool:
	if data.has("min_moral") and GameState.morality < int(data["min_moral"]):
		return false
	if data.has("max_moral") and GameState.morality > int(data["max_moral"]):
		return false
	if data.has("min_sin") and GameState.sin < int(data["min_sin"]):
		return false
	if data.has("max_sin") and GameState.sin > int(data["max_sin"]):
		return false
	return true

static func req_text(data: Dictionary) -> String:
	var parts: Array[String] = []
	if data.has("min_moral"):
		parts.append("道德≥%d" % int(data["min_moral"]))
	if data.has("max_moral"):
		parts.append("道德≤%d" % int(data["max_moral"]))
	if data.has("min_sin"):
		parts.append("罪恶≥%d" % int(data["min_sin"]))
	if data.has("max_sin"):
		parts.append("罪恶≤%d" % int(data["max_sin"]))
	return "、".join(parts)

# NPC 对玩家的态度（一句话）
static func attitude() -> String:
	if is_saint():
		return "他看你的眼神很轻，像是看见了光。"
	if is_sinner():
		return "他往后退了半步，手按在刀上。"
	var b := balance()
	if b >= 20:
		return "他朝你点了点头。"
	if b <= -20:
		return "他不太敢看你。"
	return "他打量着你，像在估量。"

extends RefCounted

# ============================================================
# dump_cards.gd —— 把全部卡牌按流派导出成一份 Markdown 文档
# 用法：
#   godot --headless --path . -s tools/dump_cards.gd
# 输出：
#   docs/CARDS_BY_STREAM.md
# ============================================================

const OUT_PATH := "res://docs/CARDS_BY_STREAM.md"
const STREAM_ORDER := ["毒", "力", "守", "抽", "斩", "血", "技", "愈"]
const STREAM_DESC := {
	"毒": "施加中毒、流血，或按敌方状态层数造成伤害。越拖越强。",
	"力": "堆叠力量，让每一次攻击都更重。",
	"守": "格挡与减伤，把伤害挡在生命之外。",
	"抽": "抽牌与能量，把手牌变成资源。",
	"斩": "单次高伤害的直接攻击。",
	"血": "用生命换取收益，自伤换爆发。",
	"技": "控制与削弱：虚弱、易伤、加费。",
	"愈": "回复生命，把损失补回来。",
}

const KIND_LABEL := {
	"action": "行动",
	"effect": "效果",
	"encounter": "遭遇",
}


static func write() -> void:
	var lines: PackedStringArray = []

	var total: int = CardDB.CARDS.size()
	lines.append("# 卡牌总表（按流派）")
	lines.append("")
	lines.append("共 **%d** 张。每张卡只出现在一个流派下（取它的主流派）。" % total)
	lines.append("")
	lines.append("| 流派 | 张数 | 说明 |")
	lines.append("|------|------|------|")

	# 先按主流派分组
	var groups := {}
	for st in STREAM_ORDER:
		groups[st] = []
	var other: Array = []
	for id in CardDB.CARDS.keys():
		var ss: Array = CardDB.streams_of(id)
		var main := str(ss[0]) if not ss.is_empty() else ""
		if groups.has(main):
			groups[main].append(id)
		else:
			other.append(id)

	for st in STREAM_ORDER:
		lines.append("| **%s** | %d | %s |" % [st, groups[st].size(), str(STREAM_DESC.get(st, ""))])
	if not other.is_empty():
		lines.append("| 其他 | %d | 无主流派 |" % other.size())
	lines.append("")

	# 逐流派输出
	for st in STREAM_ORDER:
		var ids: Array = groups[st]
		if ids.is_empty():
			continue
		lines.append("")
		lines.append("## %s（%d 张）" % [st, ids.size()])
		lines.append("")
		lines.append("> %s" % str(STREAM_DESC.get(st, "")))
		lines.append("")
		lines.append("| 卡名 | 类型 | 费 | 效果 | 获得方式 |")
		lines.append("|------|------|----|------|----------|")

		ids.sort_custom(func(a, b): return _cost_of(a) < _cost_of(b) or (_cost_of(a) == _cost_of(b) and str(a) < str(b)))
		for id in ids:
			var d: Dictionary = CardDB.CARDS[id]
			var parts: PackedStringArray = CardDB.card_text(id).split("\n")
			var body := str(parts[2]) if parts.size() > 2 else ""
			var kind := str(KIND_LABEL.get(CardDB.kind_of(id), CardDB.kind_of(id)))
			lines.append("| %s | %s | %d | %s | %s |" % [
				str(id), kind, _cost_of(id), body.replace("\n", " "), _source_of(id)
			])

	if not other.is_empty():
		lines.append("")
		lines.append("## 其他（%d 张）" % other.size())
		lines.append("")
		lines.append("| 卡名 | 类型 | 费 | 效果 |")
		lines.append("|------|------|----|------|")
		for id in other:
			var d2: Dictionary = CardDB.CARDS[id]
			var p2: PackedStringArray = CardDB.card_text(id).split("\n")
			var b2 := str(p2[2]) if p2.size() > 2 else ""
			lines.append("| %s | %s | %d | %s |" % [
				str(id), str(KIND_LABEL.get(CardDB.kind_of(id), CardDB.kind_of(id))),
				_cost_of(id), b2.replace("\n", " ")
			])

	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if f == null:
		push_error("写不了 %s" % OUT_PATH)
		return
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("已写出 %s（%d 张卡）" % [OUT_PATH, total])


static func _cost_of(id: String) -> int:
	return int(CardDB.CARDS[id].get("cost", 0))


# 获得方式：一句话说明这张卡从哪来
static func _source_of(id: String) -> String:
	var d: Dictionary = CardDB.CARDS[id]
	if bool(d.get("tutorial", false)):
		return "教学"
	if bool(d.get("exclusive", false)):
		return "职业专属"
	if bool(d.get("remnant", false)):
		return "残余节点"
	if bool(d.get("event", false)):
		return "事件 / 英雄"
	if bool(d.get("divine", false)):
		return "神国奖励"
	if bool(d.get("common", false)):
		return "通用（任意流派）"
	return "战斗奖励 / 商店"

extends Node

# ===== 状态定义：加新状态只需在这里加一行 =====
const STATUS := {
	"中毒": {"name": "中毒", "kind": "debuff", "desc": "回合结束受到层数点伤害，然后层数 -1"},
	"虚弱": {"name": "虚弱", "kind": "debuff", "desc": "造成的伤害 -25%，每回合 -1"},
	"易伤": {"name": "易伤", "kind": "debuff", "desc": "受到的伤害 +50%，每回合 -1"},
	"力量": {"name": "力量", "kind": "buff", "desc": "每段攻击 +层数 伤害，不衰减"},
}

func name_of(id: String) -> String:
	return STATUS[id]["name"]

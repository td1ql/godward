# ============================================================
# NodeRuleDB —— 节点奖励规则表
# ------------------------------------------------------------
# 每种地图节点对应一条规则：
#   "gold"    : 通关掉落金币
#   "cards"   : 奖励卡可选数量
#   "discard" : 是否在奖励后追加"弃一张牌"
#
# 想调平衡：只改下面这张表，不用动战斗代码。
# ============================================================

extends Node

const RULES := {
	"battle":       {"gold": 15,  "cards": 3, "discard": false},
	"elite":        {"gold": 40,  "cards": 3, "discard": true},
	"boss":         {"gold": 100, "cards": 3, "discard": false},
	"divine":       {"gold": 25,  "cards": 3, "discard": false},
	"divine_elite": {"gold": 60,  "cards": 3, "discard": true},
	"pope":         {"gold": 0,   "cards": 0, "discard": false},
	"contestant":   {"gold": 0,   "cards": 3, "discard": false},
}

func gold_of(node_type: String) -> int:
	return int(RULES.get(node_type, {}).get("gold", 0))

func cards_of(node_type: String) -> int:
	return int(RULES.get(node_type, {}).get("cards", 3))

func discard_of(node_type: String) -> bool:
	return bool(RULES.get(node_type, {}).get("discard", false))

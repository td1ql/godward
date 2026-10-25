extends Node

const STATUS := {
	"中毒": {"name": "中毒", "desc": "回合结束失去等同层数的生命", "good": false, "tick_damage": true, "decay": 1},
	"流血": {"name": "流血", "desc": "被攻击时额外受到等同层数的伤害", "good": false, "tick_damage": false, "decay": 1},
	"虚弱": {"name": "虚弱", "desc": "造成的伤害降低 25%", "good": false, "tick_damage": false, "decay": 1},
	"易伤": {"name": "易伤", "desc": "受到的伤害提高 50%", "good": false, "tick_damage": false, "decay": 1},
	"力量": {"name": "力量", "desc": "攻击伤害 + 层数", "good": true, "tick_damage": false, "decay": 1},
	"再生": {"name": "再生", "desc": "回合结束回复等同层数的生命", "good": true, "tick_damage": false, "tick_heal": true, "decay": 1},
	"荆棘": {"name": "荆棘", "desc": "攻击它的人受到等同层数的伤害", "good": true, "tick_damage": false, "decay": 1},
	"恒光": {"name": "恒光", "desc": "不会受到任何伤害", "good": true, "tick_damage": false, "decay": 0},
	"迅捷": {"name": "迅捷", "desc": "每回合开始能量 + 层数", "good": true, "tick_damage": false, "decay": 1},
	"洞察": {"name": "洞察", "desc": "每回合多抽等同层数的牌", "good": true, "tick_damage": false, "decay": 1},
	"嗜血": {"name": "嗜血", "desc": "每打出一张伤害牌回复等同层数的生命", "good": true, "tick_damage": false, "decay": 1},
	"炽热": {"name": "炽热", "desc": "每回合开始对敌人造成等同层数的伤害", "good": true, "tick_damage": false, "decay": 1},
	"反弹": {"name": "反弹", "desc": "每次受伤对敌人造成等同层数的伤害", "good": true, "tick_damage": false, "decay": 1},
	"狂怒": {"name": "狂怒", "desc": "每次受伤获得等同层数的力量", "good": true, "tick_damage": false, "decay": 1},
	"坚守": {"name": "坚守", "desc": "格挡不会在回合结束时清空", "good": true, "tick_damage": false, "decay": 0},
	"重力": {"name": "重力", "desc": "每回合开始能量 -1", "good": false, "tick_damage": false, "decay": 1},
	"迟钝": {"name": "迟钝", "desc": "每回合少抽 1 张", "good": false, "tick_damage": false, "decay": 1},
	"护佑": {"name": "护佑", "desc": "抵挡接下来的 1 次伤害", "good": true, "tick_damage": false, "decay": 0},
	"守护": {"name": "守护", "desc": "每回合开始获得等同层数的格挡", "good": true, "tick_damage": false, "decay": 1},
	"锋锐": {"name": "锋锐", "desc": "攻击伤害 ×1.25", "good": true, "tick_damage": false, "decay": 1},
	"毒性增长": {"name": "毒性增长", "desc": "敌人每有 3 层中毒，回合结束额外 +1 层", "good": true, "tick_damage": false, "decay": 0},
	"狂化": {"name": "狂化", "desc": "每回合开始 +2 力量", "good": true, "tick_damage": false, "decay": 0},


}

func name_of(id: String) -> String:
	return STATUS[id]["name"]

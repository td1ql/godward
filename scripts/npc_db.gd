# ============================================================
# NpcDB —— 英雄 NPC 的话题数据
# ------------------------------------------------------------
# 每个英雄是一棵「话题树」：
#   topics : 可反复点的话题。requires 满足才会出现。
#   bond   : 结盟话题，需要好感度达到 bond_favor 才会出现。
#   fight  : 拔刀话题，一直都有。
#
# 字段说明：
#   id       话题唯一 id（存档里记「聊过哪些」）
#   label    按钮上显示的文字
#   text     点开之后说的话（支持 \n）
#   favor    +好感度
#   requires 出现条件：{"favor": 25} / {"topics": ["t1","t2"]}
#   once     只能聊一次（默认 true）
#
# 好感度存在 GameState.impressions[英雄名]，0~100。
# ============================================================

extends Node

# ===== 样板英雄：阿喀琉斯 =====
const NPCS := {
	"阿喀琉斯": {
		"title": "等一个人的人",
		"portrait": "res://assets/art/enemy/warden.webp",
		"bond_favor": 45,
		"topics": [
			{
				"id": "t1",
				"label": "「你为什么一个人站在这里？」",
				"text": "他看了你很久。\n「等人。」",
				"favor": 5,
			},
			{
				"id": "t2",
				"label": "「等谁？」",
				"text": "「一个朋友。」\n「他答应过我，会走在我前面。」\n他说这句话的时候没有笑。",
				"favor": 6,
				"requires": {"topics": ["t1"]},
			},
			{
				"id": "t3",
				"label": "「这条路没有回头。」",
				"text": "「我知道。」\n「所以我站在这里。」\n「站在这里，就等于替他回头了。」",
				"favor": 6,
				"requires": {"topics": ["t2"]},
			},
			{
				"id": "t4",
				"label": "「他是不是不会来了？」",
				"text": "他没有立刻回答。\n「……他答应过我。」\n「答应过的事，就该算数。」",
				"favor": 8,
				"requires": {"favor": 18},
			},
			{
				"id": "t5",
				"label": "「你叫什么？」",
				"text": "「阿喀琉斯。」\n「你呢？」\n你说了自己的名字。他点了点头，像是记住了。",
				"favor": 8,
				"requires": {"favor": 26},
			},
			{
				"id": "t6",
				"label": "「（告诉他：那个人不会来了）」",
				"text": "他听完，很慢地眨了眨眼。\n「我知道。」\n「我早就知道了。」\n「我只是不想走。」",
				"favor": 12,
				"requires": {"favor": 34},
			},
		],
	},
}

# 通用的「拔刀」话题
const FIGHT_LABEL := "「（拔刀）」"

# 通用的「离开」按钮
const LEAVE_LABEL := "「（不说了，走吧）」"


func has(npc_id: String) -> bool:
	return NPCS.has(npc_id)


func info_of(npc_id: String) -> Dictionary:
	return NPCS.get(npc_id, {})


func title_of(npc_id: String) -> String:
	return str(info_of(npc_id).get("title", ""))


func portrait_of(npc_id: String) -> String:
	return str(info_of(npc_id).get("portrait", "res://assets/art/enemy/soldier.webp"))


func bond_favor_of(npc_id: String) -> int:
	return int(info_of(npc_id).get("bond_favor", 45))


# 某个话题现在能不能出现
func unlocked(npc_id: String, tp: Dictionary, favor: int, seen: Array) -> bool:
	var req: Dictionary = tp.get("requires", {})
	if req.has("favor") and favor < int(req["favor"]):
		return false
	if req.has("topics"):
		for need in req["topics"]:
			if not seen.has(str(need)):
				return false
	return true


# 当前可聊的话题（排除已聊过的 once 话题）
func available_topics(npc_id: String, favor: int, seen: Array) -> Array:
	var out: Array = []
	for tp in info_of(npc_id).get("topics", []):
		var id := str(tp.get("id", ""))
		if bool(tp.get("once", true)) and seen.has(id):
			continue
		if unlocked(npc_id, tp, favor, seen):
			out.append(tp)
	return out


# 结盟话题是否已解锁
func can_bond(npc_id: String, favor: int) -> bool:
	return favor >= bond_favor_of(npc_id)

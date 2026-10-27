# ============================================================
# NpcDB —— 英雄 NPC 的话题数据
# ------------------------------------------------------------
# 结构：
#   topics[]        话题。点开后 NPC 说 text，然后弹出 responses。
#   responses[]     玩家可以怎么回。每条有自己的 text（NPC 的回应）和好感变化。
#   vocation_lines  按玩家职业替换 NPC 的开场白（不写就用默认 text）。
#   bond_favor      好感度到多少才能结盟。
#
# 好感度存 GameState.impressions[英雄名]，0~100。
# ============================================================

extends Node

const NPCS := {
	"阿喀琉斯": {
		"title": "等一个人的人",
		"portrait": "res://assets/art/enemy/warden.webp",
		"bond_favor": 45,
		"greeting": "他背对着你站在那里。\n风从你们中间过去，他没有回头。",
		"topics": [
			{
				"id": "t1",
				"label": "「你为什么一个人站在这里？」",
				"text": "他看了你很久。\n「等人。」",
				"vocation_lines": {
					"等待丈夫的新娘": "他看了你很久。\n「你也在等。」\n「那我们是一样的。」",
					"失明的守钟人": "他看了你很久。\n「你手里那口钟，」他说，「还在响吗。」",
					"饥饿的朝圣者": "他看了你很久。\n「你跪着过来的。」\n「我不劝人站起来。」",
					"沉默的执剑人": "他看了你很久。\n「你的剑没出过鞘。」\n「我的也是。」",
					"疯癫的先知": "他看了你很久。\n「你看见的东西，」他说，「是不是也没人信。」",
					"褴褛的记账人": "他看了你很久。\n「你记的那些债，」他说，「早烂了。」\n「你还记着。」",
					"断臂的旗手": "他看了你很久。\n「旗子倒了。」\n「你还举着。」",
					"无名的旅人": "他看了你很久。\n「我记不住你的脸。」\n「你也不在乎。」",
					"溺水的小公主": "他看了你很久。\n「你身上是湿的。」\n「从这里走上来，很冷吧。」",
					"焚书的疯子": "他看了你很久。\n「你身上有烟味。」\n「烧过东西的人，不劝人走。」",
					"守夜的哨兵": "他看了你很久。\n「换班的人呢。」\n「……我懂了。」",
					"数星星的瞎子": "他看了你很久。\n「今天晚上有几颗。」\n「你看不见。」\n「那你看的是什么。」",
					"磨刀的哑巴": "他看了你很久。\n「你的刀很亮。」\n「磨了很久吧。」",
					"收尸的妇人": "他看了你很久。\n「你替很多人合过眼睛。」\n「别替我合。我还没闭。」",
					"执棋未落的妙手": "他看了你很久。\n「这一手你已经想很久了。」\n「落子吧。」",
					"等死的病人": "他看了你很久。\n「你也在等一个不会来的人。」\n「那我们一起等。」",
				},
				"responses": [
					{"label": "「等谁？」", "text": "「一个朋友。」\n「他答应过我，会走在我前面。」", "favor": 5},
					{"label": "（不说话，在他旁边站着）", "text": "他侧过头看了你一眼。\n没有赶你走。", "favor": 8},
					{"label": "「这条路一直往前，没什么好等的。」", "text": "「你走你的。」\n「我等他。」", "favor": -2},
				],
			},
			{
				"id": "t2",
				"label": "「那个人是什么样的人？」",
				"text": "「他走路的时候，会先迈右脚。」\n「很奇怪吧。」\n「我记得这个。」",
				"requires": {"topics": ["t1"]},
				"responses": [
					{"label": "「你记得很清楚。」", "text": "「我记性不好。」\n「就是这件事一直没忘。」", "favor": 6},
					{"label": "「（试着记下这个细节）」", "text": "「你不用记。」\n「以后要是见到他，你会认得。」", "favor": 8},
					{"label": "「一个小动作而已。」", "text": "他没说话。\n把右手在身后握了一下。", "favor": -3},
				],
			},
			{
				"id": "t3",
				"label": "「前面的路我看过了，没有别人。」",
				"text": "「我知道。」\n「我往前走过。」\n「走了一段就回来了。」",
				"requires": {"topics": ["t2"]},
				"responses": [
					{"label": "「为什么回来？」", "text": "「怕他来了看不见我。」\n他说完自己笑了一下。", "favor": 8},
					{"label": "「那你也可以一直站在这里。」", "text": "「嗯。」\n这是他第一次应得这么快。", "favor": 10},
					{"label": "「他不会来了。」", "text": "他转过头，第一次正眼看你。\n「你也不知道。」", "favor": -5},
				],
			},
			{
				"id": "t4",
				"label": "「你叫什么？」",
				"text": "「阿喀琉斯。」\n「你呢？」\n你说完，他点了点头，像在把名字放进什么地方。",
				"requires": {"favor": 20},
				"responses": [
					{"label": "「你会记得我的名字吗？」", "text": "「会。」\n「我记性不好，但会。」", "favor": 8},
					{"label": "「（问他记不记得自己是谁）」", "text": "「记得。」\n「记得太久了，所以不敢走。」", "favor": 9},
					{"label": "「名字不重要。」", "text": "「重要。」\n「不然你走了，我连等谁都不知道。」", "favor": 4},
				],
			},
			{
				"id": "t5",
				"label": "「（告诉他：那个人已经死了）」",
				"text": "他站着没动。\n很久之后才开口。\n「你怎么知道。」",
				"requires": {"favor": 32},
				"responses": [
					{"label": "「我就是知道。」", "text": "「……嗯。」\n「我知道很久了。」\n「我只是不想走。」", "favor": 10},
					{"label": "「抱歉。」", "text": "「不用道歉。」\n「你是第一个肯跟我说的。」", "favor": 12},
					{"label": "「（什么也没说，把手放在他肩上）」", "text": "他没有躲。\n肩膀在抖。\n很轻，像风。", "favor": 14},
				],
			},
		],
	},
}

const FIGHT_LABEL := "「（拔刀）」"
const LEAVE_LABEL := "「（不说了，走吧）」"


func has(npc_id: String) -> bool:
	return NPCS.has(npc_id)


func info_of(npc_id: String) -> Dictionary:
	return NPCS.get(npc_id, {})


func title_of(npc_id: String) -> String:
	return str(info_of(npc_id).get("title", ""))


func greeting_of(npc_id: String) -> String:
	return str(info_of(npc_id).get("greeting", "他在那里。"))


func portrait_of(npc_id: String) -> String:
	return str(info_of(npc_id).get("portrait", "res://assets/art/enemy/soldier.webp"))


func bond_favor_of(npc_id: String) -> int:
	return int(info_of(npc_id).get("bond_favor", 45))


func topic_of(npc_id: String, topic_id: String) -> Dictionary:
	for tp in info_of(npc_id).get("topics", []):
		if str(tp.get("id", "")) == topic_id:
			return tp
	return {}


# 这个话题现在能不能出现
func unlocked(tp: Dictionary, favor: int, seen: Array) -> bool:
	var req: Dictionary = tp.get("requires", {})
	if req.has("favor") and favor < int(req["favor"]):
		return false
	if req.has("topics"):
		for need in req["topics"]:
			if not seen.has(str(need)):
				return false
	return true


func available_topics(npc_id: String, favor: int, seen: Array) -> Array:
	var out: Array = []
	for tp in info_of(npc_id).get("topics", []):
		if not unlocked(tp, favor, seen):
			continue
		out.append(tp)
	return out


# NPC 的开场白：优先用职业专属版本
func line_of(npc_id: String, tp: Dictionary) -> String:
	var vl: Dictionary = tp.get("vocation_lines", {})
	var voc := str(GameState.vocation)
	if vl.has(voc):
		return str(vl[voc])
	return str(tp.get("text", ""))


# 已聊过的话题打勾提示用
func is_seen(seen: Array, topic_id: String) -> bool:
	return seen.has(topic_id)


func can_bond(npc_id: String, favor: int) -> bool:
	return favor >= bond_favor_of(npc_id)

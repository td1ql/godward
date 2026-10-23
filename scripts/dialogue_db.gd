# ============================================================
# DialogueDB —— 对话脚本数据
# ------------------------------------------------------------
# 每条对话是一个数组，元素可以是：
#   {"speaker": "教皇", "text": "「又来了一个。」"}
#   或直接写字符串（当作旁白）
#
# 播放：
#   Dialogue.play(self, DialogueDB.get_lines("prologue"), _on_done)
# ============================================================

extends Node

const LINES := {
	"prologue": [
		{"speaker": "旁白", "text": "你在神域的边缘醒来，身上没有一处不疼。"},
		{"speaker": "旁白", "text": "远处有一座教堂，尖顶刺进灰白色的天。"},
		{"speaker": "教皇", "text": "「又来了一个。」"},
		{"speaker": "你", "text": "「……这是哪里？」"},
		{"speaker": "教皇", "text": "「逐神的游戏。赢的人，可以登临神堂。」"},
		{"speaker": "你", "text": "「如果我输了呢？」"},
		{"speaker": "教皇", "text": "「你会再来一次。」"},
	],
	"first_divine": [
		{"speaker": "旁白", "text": "教堂的门在你身后合上。"},
		{"speaker": "旁白", "text": "里面不是神堂，是一片没有尽头的白。"},
		{"speaker": "教皇", "text": "「欢迎来到我的神国。」"},
	],
	"pope_defeat": [
		{"speaker": "教皇", "text": "「你……不可能……」"},
		{"speaker": "你", "text": "「你骗了所有人。」"},
		{"speaker": "教皇", "text": "「不。是你自己愿意相信的。」"},
	],
}

func get_lines(id: String) -> Array:
	return LINES.get(id, [])

extends Node

const TEXTS := {
	# 清算
	"cleanup_title": "教堂的大门紧闭",
	"cleanup_body": "还有 %d 名参赛者活着。\n觐见神的资格只属于胜者",
	"cleanup_button": "开始清算",
	"cleanup_result_title": "清 算",
	"cleanup_result_empty": "什么也没留下。",
	"cleanup_continue": "继续清算（剩 %d 人）",
	"cleanup_go": "前往神堂",
	"gameover_loop_title": "教皇还在等你",
	"gameover_loop_body": "你在神国里倒下。\n教皇没有看你。\n——第 10 次转生，重新开始。",

	# 战斗奖励
	"reward_title": "战斗胜利！金币 +%d　选择一张卡",
	"reward_pick": "点击选择",
	"reward_skip": "跳过奖励",

	# 失败
	"gameover_title": "你被打倒了……",
	"gameover_body": "这次冒险到此为止。",
	"gameover_restart": "重新开始一局",
	"gameover_menu": "返回主菜单",

	# 教皇
	"pope_title": "教 皇",
	"pope_body": "你走进教堂。教皇甚至没有抬头。\n一只手落在你的额头上——\n然后，一切暗了下去。",
	"pope_button": "转生",

	# 教堂
	"church_title": "教 堂",
	"church_body": "清算结束了。\n教堂的门，为你打开了。",
	"church_button": "进入教堂",

	# 真结局
	"ending_title": "神 堂",
	"ending_body": "教皇倒下时，穹顶裂开了。\n里面没有神，只有一片安静的白。\n\n你终于想起自己是谁。",
	"ending_body_good": "教皇倒下时，穹顶裂开了。\n里面没有神，只有一片安静的白。\n\n你想起自己这一路没有杀过不该杀的人。\n白里有一点光，像是回应了你。",
	"ending_body_dark": "教皇倒下时，穹顶裂开了。\n里面没有神，只有一片安静的白。\n\n你踩过太多人的手。\n那些手都还留在下面。\n你听见它们在叫你。",
	"ending_button": "回到主菜单",

	# 参赛者结算
	"aftermath_title": "%s 倒下了",
	"aftermath_cleanup": "觐见神明的门只为胜利者打开。\n他必须留在这里。",
	"aftermath_normal": "他还有呼吸。于是你可以践行自己的道德了。",
	"aftermath_kill": "杀死他",
	"aftermath_spare": "饶恕他",

	# 战斗界面
	"battle_menu": "菜单",
	"battle_deck": "牌库",
	"battle_piles": "牌堆",
}

func t(key: String) -> String:
	return str(TEXTS.get(key, key))

func f(key: String, args: Array) -> String:
	return str(TEXTS.get(key, key)) % args

const SERIF_PATH := "res://assets/fonts/NotoSerifCJKsc-Regular.otf"

func font() -> Font:
	if not ResourceLoader.exists(SERIF_PATH):
		return null
	return load(SERIF_PATH) as Font

func apply_serif(ctrl: Control) -> void:
	var f := font()
	if f != null:
		ctrl.add_theme_font_override("font", f)

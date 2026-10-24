# ============================================================
# DialogueDB —— 对话脚本数据
# ------------------------------------------------------------
# 说话人固定用：
#   "无上神音"  旁白/世界之声
#   "上帝"      陨落前的上帝
#   "教皇"      第二幕的真身
#   "影子"      教堂里的幻象
#   "你"        玩家
#
# 铁律：不出现「卡牌 / 牌组 / 抽牌 / 费用 / 能量」等游戏术语。
# ============================================================

extends Node

const LINES := {
	"prologue": [
		{"speaker": "无上神音", "text": "起初，光从众神的衣袍上落下。","bg": "res://assets/art/story/p1_eden.webp"},
		{"speaker": "无上神音", "text": "万物饱足而不朽。\n那时没有生死，也没有昼夜。"},
		{"speaker": "无上神音", "text": "直到贪婪将一切吞没。\n众神们纷纷陷入疯狂", "bg": "res://assets/art/story/p2_tree.webp"},
		{"speaker": "无上神音", "text": "撑起世界的巨木枯萎了\n天国中的生灵们全部坠入那无尽深渊"},
		{"speaker": "无上神音", "text": "在上帝将要沉睡的刹那。\n他飘起了些许的思绪。", "bg": "res://assets/art/story/p3_abyss.webp"},
		{"speaker": "无上神音", "text": "「……那是什么」"},
		{"speaker": "无上神音", "text": "「一团微亮的星火」", "bg": "res://assets/art/story/p4_spark.webp"},
		{"speaker": "无上神音", "text": "「一颗种子」"},
		{"speaker": "无上神音", "text": "「希望的信念在蔓延」"},
		{"speaker": "无上神音", "text": "「离开这里」"},
		{"speaker": "无上神音", "text": "「到人@！#」"},
		{"speaker": "无上神音", "text": "黑暗在侵蚀祂的神志\n贪婪与罪恶遮蔽了光芒"},
		{"speaker": "无上神音", "text": "「但是神明说」"},
		{"speaker": "无上神音", "text": "「要有光」", "bg": "res://assets/art/story/p4_light.webp"},
		{"speaker": "无上神音", "text": "「驱散它们」"},
	],
	"prologue_after": [
		{"speaker": "无上神音", "text": "「于是星火也足以燎尽荒原」", "bg": "res://assets/art/story/p5_burn.webp"},
		{"speaker": "无上神音", "text": "「众神在疯狂与痛苦中挣扎」"},
		{"speaker": "火在燃烧", "text": "「.」"},
		{"speaker": "火在燃烧", "text": "「..」"},
		{"speaker": "火在燃烧", "text": "「...」"},
		{"speaker": "于是星火发问", "text": "「我是谁」", "bg": "res://assets/art/story/p6_flame.webp"},
		{"speaker": "于是星火发问", "text": "「我从哪来」"},
		{"speaker": "于是星火发问", "text": "「我改去往何处」"},
		{"speaker": "无上神音", "text": "「到人间去」"},
		{"speaker": "无上神音", "text": "「...去发光...」"},
		{"speaker": "无上神音", "text": "「...去成为太阳」\n「...众生..明天！@##@！」"},
		{"speaker": "沉沦神音", "text": "「！@###￥%……##￥」"},
	],
	"first_divine": [
		{"speaker": "无上神音", "text": "门开了"},
		{"speaker": "无上神音", "text": "入目是一片惨烈的苍白 \n接着是无尽的空旷"},
		{"speaker": "无上神音", "text": "你听见了呼吸声\n从四面八方传来"},
		{"speaker": "无上神音", "text": "是谁在呼吸\n好似是世界在起伏"},
	],
	"pope_before": [
		{"speaker": "无上神音", "text": "教皇垂坐在长椅之上"},
		{"speaker": "教皇", "text": "我的主啊，你竟被困于这人间"},
		{"speaker": "无上神音", "text": "他的眼中流下泪水，传来微微的啜泣"},
		{"speaker": "教皇", "text": "已经太晚了，我的罪孽无以悔过"},
		{"speaker": "教皇", "text": "我从没有错"},
	],
	"pope_defeat": [
		{"speaker": "教皇", "text": "「我的主」"},
		{"speaker": "教皇", "text": "「如果你一直都在」"},
		{"speaker": "教皇", "text": "「又为何要漠视这众生」"},
		{"speaker": "教皇", "text": "「  ...  」"},
		{"speaker": "无上神音", "text": "他闭上了眼睛。"},
	],
	"world_tree": [
		{"speaker": "无上神音", "text": "你抬头看向天空"},
		{"speaker": "无上神音", "text": "那里有着树叶的纹理\n像是世界的伤疤，狰狞可怖"},
		{"speaker": "无上神音", "text": "赤红的火光从天空的缝隙溢出\n你却只感到无比的温暖"},
	],
}

func get_lines(id: String) -> Array:
	return LINES.get(id, [])

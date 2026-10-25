extends Node

const IMPRESSION_SCALE := 3

const CONTESTANTS := {
	"阿喀琉斯": {
		"name": "阿喀琉斯",
		"trait": "好战",
		"desc": "他是这局里最强的一个。\n他把自己的口粮全分了出去。\n他说他不需要。",
		"hostile": true,
		"hp": 52, "attack": 7, "pattern": [1, 1, 2],
		"choices": [
			{"label": "问他为什么来", "result": "talk", "text": "「别人推我来的。」\n「我懒得拒绝。」", "gold": 25},
			{"label": "和他动手", "result": "fight"},
			{"label": "走开", "result": "leave", "text": "他把最后一点口粮分给了下一个路过的人。"},
		],
		"kill": {"text": "他倒下时，先看的是自己的左脚。", "gold": 60},
		"spare": {"text": "「你走前头。」\n「我懒得看路。」", "ally": true},
		"ally_effect": {"type": "fighter", "damage": 6},
	},
	"赫克托耳": {
		"name": "赫克托耳",
		"trait": "冷静",
		"desc": "他不肯离开路口。\n路口后面是水。\n他说总得有人站在这里。",
		"hostile": false,
		"hp": 52, "attack": 8, "pattern": [1, 2],
		"choices": [
			{"label": "替他站一会儿", "result": "talk", "text": "他坐下，没有睡。\n「水是干净的。」他说。\n「别让人往里面放东西。」", "hp": -5, "moral": 8, "cards": ["铁壁"]},
			{"label": "问他守到什么时候", "result": "talk", "text": "「守到没人来。」", "moral": 3},
			{"label": "走开", "result": "leave", "text": "他朝你点头，像在送人出门。"},
		],
		"kill": {"text": "路口空了。\n水还在那里。", "gold": 45},
		"spare": {"text": "「换你站。」他说。\n你站了半刻，他就回来了。", "ally": true},
		"ally_effect": {"type": "fighter", "damage": 4},
	},
	"奥德修斯": {
		"name": "奥德修斯",
		"trait": "狡诈",
		"desc": "他什么都换。\n换东西，换消息，换别人欠他的。\n他不换自己的。",
		"hostile": true,
		"hp": 46, "attack": 7, "pattern": [2, 1],
		"choices": [
			{"label": "用钱换一条消息（-20 金币）", "result": "talk", "text": "他收了钱，凑近。\n「往东走，别走桥。」\n他没说为什么。", "gold": -20, "cards": ["快速思考"]},
			{"label": "问他欠谁的", "result": "fight"},
			{"label": "走开", "result": "leave", "text": "他重新摆好他的东西。\n摆得比刚才整齐。"},
		],
		"kill": {"text": "他身上的东西比谁都多。\n没有一样是他自己的。", "gold": 55},
		"spare": {"text": "「你什么都不问，」他说。\n「这很好。」", "random_cards": 1},
		"ally_effect": {"type": "buff", "cards": ["快速思考"]},
	},
	"赫拉克勒斯": {
		"name": "赫拉克勒斯",
		"trait": "好战",
		"desc": "营地里的活都是他干的。\n他搬得动别人搬不动的东西。\n他从不问报酬。",
		"hostile": true,
		"hp": 54, "attack": 9, "pattern": [1, 1, 1],
 		"domain": {"type": "enemy_regen", "value": 4},
		"choices": [
			{"label": "请他搬开塌方", "result": "talk", "text": "他搬开了。\n「以后还有这种事，叫我。」", "gold": 20, "moral": 3},
			{"label": "问他图什么", "result": "talk", "text": "「不图什么。」\n「闲着也是闲着。」", "cards": ["重击"]},
			{"label": "走开", "result": "leave", "text": "他已经在搬下一堆了。"},
		],
		"kill": {"text": "他倒下的地方，塌方又合上了。", "gold": 70},
		"spare": {"text": "「有事叫我。」\n他说完就去搬东西了。", "ally": true},
		"ally_effect": {"type": "fighter", "damage": 7},
	},
	"珀尔修斯": {
		"name": "珀尔修斯",
		"trait": "敏锐",
		"desc": "他有一面铜盾，磨得很亮。\n他不看前面，只看身后。\n他说前面的东西不用看。",
		"hostile": false,
		"hp": 45, "attack": 8, "pattern": [1, 2, 1],
		"choices": [
			{"label": "借盾照身后", "result": "talk", "text": "你在盾里看见身后那条路。\n路上没有脚印。\n你刚才走过的。", "cards": ["圣光"], "hp": -4},
			{"label": "问他后面有什么", "result": "talk", "text": "「有人。」\n「一直有。」", "gold": 20},
			{"label": "走开", "result": "leave", "text": "他把盾转了个方向，让你照不到。"},
		],
		"kill": {"text": "铜盾掉在地上。\n里面还是你的脸。", "gold": 50},
		"spare": {"text": "他把盾留给了你。\n「别看自己。」", "cards": ["神谕"]},
		"ally_effect": {"type": "buff", "cards": ["神谕"]},
	},
	"忒修斯": {
		"name": "忒修斯",
		"trait": "冷静",
		"desc": "他走到哪都在墙上刻一道。\n刻得很深。\n他说怕回不去。",
		"hostile": false,
		"hp": 50, "attack": 8, "pattern": [1, 1, 2],
		"choices": [
			{"label": "跟着记号走", "result": "talk", "text": "记号一直通到出口。\n他在出口等你。\n「你比我慢。」", "hp": 15},
			{"label": "问他从哪来", "result": "talk", "text": "「一个有很多墙的地方。」", "cards": ["快速思考"]},
			{"label": "走开", "result": "leave", "text": "身后又响起了刻墙的声音。"},
		],
		"kill": {"text": "最后一刀没有刻完。", "gold": 40},
		"spare": {"text": "「跟着记号走，」他说。\n「别走丢。」", "cards": ["快速思考"]},
		"ally_effect": {"type": "buff", "cards": ["快速思考"]},
	},
	"伊阿宋": {
		"name": "伊阿宋",
		"trait": "狡诈",
		"desc": "他总在说以后。\n以后要去哪，以后要做什么。\n没人问他现在。",
		"hostile": true,
		"hp": 38, "attack": 8, "pattern": [1.5, 2],
		"choices": [
			{"label": "听他讲以后", "result": "talk", "text": "他讲了很久。\n「到时候我带你一起走。」\n他已经对很多人说过这句话。", "gold": -20},
			{"label": "问他现在有什么", "result": "fight"},
			{"label": "走开", "result": "leave", "text": "「你会回来的。」他在你身后说。"},
		],
		"kill": {"text": "他临死前还在说以后。", "gold": 55},
		"spare": {"text": "「那就一起走。」", "ally": true},
		"ally_effect": {"type": "buff", "cards": ["誓约"]},
	},
	"俄耳甫斯": {
		"name": "俄耳甫斯",
		"trait": "神秘",
		"desc": "他唱歌的时候，没人说话。\n他停下的时候，也没人说话。\n他一天只唱一次。",
		"hostile": false,
		"hp": 40, "attack": 7, "pattern": [1, 1],
		"choices": [
			{"label": "等他唱", "result": "talk", "text": "他唱了一个音。\n很长的一个音。\n你的伤口合上了。", "hp": 15},
			{"label": "问他一天为什么只唱一次", "result": "talk", "text": "「唱多了，就不准了。」", "moral": 5},
			{"label": "走开", "result": "leave", "text": "琴声跟着你，直到听不见。"},
		],
		"kill": {"text": "弦断了。\n世界安静得可怕。", "gold": 35},
		"spare": {"text": "他为你多唱了一个音。", "hp": 10, "gold": 10},
		"ally_effect": {"type": "buff", "hp": 10},
	},
	"卡珊德拉": {
		"name": "卡珊德拉",
		"trait": "疯狂",
		"desc": "她跟每一个人说同一个名字。\n那个名字不在这局里。\n她说了很多天。",
		"hostile": false,
		"hp": 42, "attack": 7, "pattern": [1, 2],
		"choices": [
			{"label": "问她那个名字是谁", "result": "talk", "text": "她愣住了。\n「你不认识他？」\n「他就在你身后。」", "random": [
				{"text": "你回头。什么也没有。", "moral": 3},
				{"text": "你回头。地上的影子多了一个。", "cards": ["审判"]},
			]},
			{"label": "让她闭嘴", "result": "fight"},
			{"label": "走开", "result": "leave", "text": "她在你身后，继续跟下一个人说。"},
		],
		"kill": {"text": "她死前还在说那个名字。", "gold": 45},
		"spare": {"text": "「谢谢你听我说完。」\n这是她第一次被听完。", "cards": ["妄念"]},
		"ally_effect": {"type": "buff", "cards": ["妄念"]},
	},
	"美狄亚": {
		"name": "美狄亚",
		"trait": "疯狂",
		"desc": "她给营地的人治病，不收钱。\n只收一句话：用完之后回来告诉她好不好。\n回来的人很少。",
		"hostile": true,
		"hp": 34, "attack": 9, "pattern": [2, 1],
		 "domain": {"type": "no_heal"},
		"choices": [
			{"label": "让她治", "result": "talk", "text": "她的手很稳。\n「好了。」\n「记得回来。」", "random": [
				{"text": "伤口合上了。", "hp": 15},
				{"text": "伤口合上了，但你觉得冷。", "hp": -8},
			]},
			{"label": "问她那些没回来的人", "result": "talk", "text": "「他们没回来。」\n「说明不好。」", "moral": 3},
			{"label": "走开", "result": "leave", "text": "她在你身后收拾药瓶。\n瓶口都没有塞子。"},
		],
		"kill": {"text": "药瓶碎了。\n味道是甜的。", "gold": 60},
		"spare": {"text": "她挑了一瓶，塞上塞子。\n「这瓶是好的。」", "cards": ["急救"]},
		"ally_effect": {"type": "buff", "hp": 12},
	},
	"阿塔兰忒": {
		"name": "阿塔兰忒",
		"trait": "敏锐",
		"desc": "探路的人是她。\n她回来得比别人快。\n回来的时候不说话。",
		"hostile": false,
		"hp": 46, "attack": 8, "pattern": [1, 1, 2],
		"choices": [
			{"label": "问她看见了什么", "result": "talk", "text": "「前面有三条路。」\n「两条走不通。」\n「哪两条，我不说。」", "cards": ["疾风斩"]},
			{"label": "跟她一起探路", "result": "talk", "text": "你跟不上。\n她回来找了你两次。", "hp": -6, "cards": ["疾风斩"]},
			{"label": "走开", "result": "leave", "text": "一阵风。她已经不在了。"},
		],
		"kill": {"text": "她倒下时，还是向前倒的。", "gold": 50},
		"spare": {"text": "「追得上我，就一起走。」", "cards": ["疾风斩"]},
		"ally_effect": {"type": "fighter", "damage": 5},
	},
	"普罗米修斯": {
		"name": "普罗米修斯",
		"trait": "虔诚",
		"desc": "他有一小堆火。\n谁冷都可以来烤。\n他不让人碰火种。",
		"hostile": false,
		"hp": 55, "attack": 6, "pattern": [1, 1],
		"choices": [
			{"label": "烤火（-5 生命）", "result": "talk", "text": "火是暖的。\n他一直看着火种。\n他没有看你。", "hp": -5, "cards": ["火球"]},
			{"label": "问火种从哪来", "result": "talk", "text": "「从上面来的。」\n「拿的时候有点疼。」", "moral": 5, "hp": 5},
			{"label": "走开", "result": "leave", "text": "他没有挽留。他一直在看火。"},
		],
		"kill": {"text": "火没有灭。\n它落在地上，烧了很久。", "gold": 40},
		"spare": {"text": "「拿去，」他说，「别说是我给的。」", "cards": ["火球"], "moral": 5},
		"ally_effect": {"type": "buff", "cards": ["火球"]},
	},
	"西西弗斯": {
		"name": "西西弗斯",
		"trait": "冷静",
		"desc": "他在填一个塌方。\n填了三天。\n他说填完就走。",
		"hostile": false,
		"hp": 60, "attack": 5, "pattern": [1, 1, 1],
		"domain": {"type": "energy_drain", "value": 1},
		"choices": [
			{"label": "帮他填", "result": "talk", "text": "石头又塌了。\n「谢谢。」他说。\n「明天还得填。」", "moral": 10, "hp": -4},
			{"label": "问他填完去哪", "result": "talk", "text": "「没想过。」\n「填完再说。」", "cards": ["冥想"]},
			{"label": "走开", "result": "leave", "text": "石头滚落的声音跟了你很远。"},
		],
		"kill": {"text": "石头停住了。\n停在半路。", "gold": 45},
		"spare": {"text": "他把石头的位置指给你看。", "cards": ["冥想"]},
		"ally_effect": {"type": "buff", "cards": ["冥想"]},
	},
	"齐格弗里德": {
		"name": "齐格弗里德",
		"trait": "好战",
		"desc": "他一个人走。\n他走过的地方，草是枯的。\n他说这不是他做的。",
		"hostile": true,
		"hp": 28, "attack": 12, "pattern": [2, 2, 2],
		"choices": [
			{"label": "跟着他走", "result": "talk", "text": "他走得很稳。\n你踩过的草没有枯。\n只有他踩过的枯了。", "hp": -5, "gold": 25},
			{"label": "问他要不要一起走", "result": "fight"},
			{"label": "走开", "result": "leave", "text": "他把剑擦干净，收了起来。"},
		],
		"kill": {"text": "他的血滴在地上。\n草全枯了。", "gold": 65},
		"spare": {"text": "「别碰我的血。」\n「走我后面。」", "ally": true},
		"ally_effect": {"type": "fighter", "damage": 6},
	},
	"布伦希尔德": {
		"name": "布伦希尔德",
		"trait": "沉默",
		"desc": "她把死者的名字记在一张长纸条上。\n纸条已经很长了。\n她不记活人的。",
		"hostile": false,
		"hp": 22, "attack": 10, "pattern": [1, 3],
		"choices": [
			{"label": "问她记这些做什么", "result": "talk", "text": "「总得有人记。」\n「不然他们就不算来过。」", "moral": 8, "cards": ["回望"]},
			{"label": "让她把你也记上", "result": "talk", "text": "她抬头看了你一眼。\n「你还活着。」\n她没有写。", "moral": 3},
			{"label": "走开", "result": "leave", "text": "她低下头，继续写。"},
		],
		"kill": {"text": "纸条掉了。\n最后一行是空的。", "gold": 50},
		"spare": {"text": "她把纸条撕了一半给你。\n「别弄丢。」", "ally": true},
		"ally_effect": {"type": "fighter", "damage": 5},
	},
	"洛基": {
		"name": "洛基",
		"trait": "狡诈",
		"desc": "他不干活，只在各处坐着。\n他坐过的地方，第二天就有人吵架。\n他说他只是听。",
		"hostile": true,
		"hp": 40, "attack": 7, "pattern": [1, 2, 4],
		"domain": {"type": "draw_penalty", "value": 1},
		"choices": [
			{"label": "在他旁边坐一会", "result": "talk", "text": "他跟你说了三件事。\n两件是真的。\n你分不出是哪两件。", "random": [
				{"text": "你后来赚了一笔。", "gold": 20},
				{"text": "你后来和人吵了一架。", "cards": ["陷阱"]},
			]},
			{"label": "让他离营地远点", "result": "fight"},
			{"label": "走开", "result": "leave", "text": "他在你身后笑。\n影子先笑了。"},
		],
		"kill": {"text": "他倒下时还在笑。\n营地安静了两天。", "gold": 70},
		"spare": {"text": "「你比我还有趣。」\n他说完就去找别人了。", "random_cards": 1},
		"ally_effect": {"type": "buff", "cards": ["陷阱"]},
	},
	"海姆达尔": {
		"name": "海姆达尔",
		"trait": "沉默",
		"desc": "他守夜，从不睡。\n守夜的人要交班，他不交。\n他说他睡不着。",
		"hostile": false,
		"hp": 65, "attack": 4, "pattern": [1, 1, 2],
		"domain": {"type": "thorns_aura", "value": 3},
		"choices": [
			{"label": "陪他守一夜", "result": "talk", "text": "他一整夜没有说话。\n天快亮时，他指了指东边。\n「那边有人。」", "hp": -6, "moral": 5, "cards": ["回望"]},
			{"label": "强行换班", "result": "fight"},
			{"label": "走开", "result": "leave", "text": "他还在原地。\n他从来不坐。"},
		],
		"kill": {"text": "他倒下的方向，还是东边。", "gold": 55},
		"spare": {"text": "「替我看着东边。」\n他说完就睡着了。", "ally": true},
		"ally_effect": {"type": "fighter", "damage": 4},
	},
	"提尔": {
		"name": "提尔",
		"trait": "虔诚",
		"desc": "他答应过的事，都做到。\n他断了的那只手，是替别人答应的。\n他不说替谁。",
		"hostile": false,
		"hp": 58, "attack": 9, "pattern": [0.5, 1, 1.5, 2],
		"choices": [
			{"label": "让他答应一件事", "result": "talk", "text": "「说吧。」\n你说完，他点头。\n「我记住了。」", "moral": 8, "cards": ["誓约"]},
			{"label": "问他替谁", "result": "talk", "text": "他想了很久。\n「一个已经不用我答应的人。」", "moral": 5, "gold": 20},
			{"label": "走开", "result": "leave", "text": "他用左手朝你行了个礼。"},
		],
		"kill": {"text": "他的左手还握着刀。", "gold": 50},
		"spare": {"text": "「替我拿着它。」\n「别弄丢。」", "cards": ["圣约"]},
		"ally_effect": {"type": "buff", "cards": ["圣约"]},
	},
}

const MEET_LINES := {
	"阿喀琉斯": {
		"good": "「你来了。」\n他把口粮推过来一半。",
		"neutral": "他看了你一眼。\n然后又看回自己的刀。",
		"bad": "「上次是你。」\n他站起来了。",
	},
	"赫克托耳": {
		"good": "「水还干净。」他说。",
		"neutral": "他朝你点头。\n没有让开。",
		"bad": "「你过了这条线。」",
	},
	"奥德修斯": {
		"good": "「有消息。」他招手。",
		"neutral": "他把布往自己那边收了收。",
		"bad": "「你欠我的。」",
	},
	"赫拉克勒斯": {
		"good": "「有事叫我。」",
		"neutral": "他在搬东西。\n没停。",
		"bad": "他放下手里的东西。",
	},
	"珀尔修斯": {
		"good": "他把盾转过来，让你照身后。",
		"neutral": "他举起盾。\n又放下了。",
		"bad": "「别站在我后面。」",
	},
	"忒修斯": {
		"good": "「记号还在。」他说。",
		"neutral": "他刻了一道新的。",
		"bad": "他把记号刮掉了。",
	},
	"伊阿宋": {
		"good": "「以后我带你走。」",
		"neutral": "他又在讲以后。",
		"bad": "「这次我不说了。」",
	},
	"俄耳甫斯": {
		"good": "他为你多唱了一个音。",
		"neutral": "他哼了半句。\n停了。",
		"bad": "他背过身去。",
	},
	"卡珊德拉": {
		"good": "她只对你一个人说那个名字。",
		"neutral": "她又开始说那个名字。",
		"bad": "她指着你，说不出话。",
	},
	"美狄亚": {
		"good": "「你回来了。」她说。",
		"neutral": "她在收拾药瓶。",
		"bad": "她手里的瓶子是满的。",
	},
	"阿塔兰忒": {
		"good": "她朝你抬了抬下巴。",
		"neutral": "她刚探完路回来。\n没有说话。",
		"bad": "她挡在路口。",
	},
	"普罗米修斯": {
		"good": "火还在。\n他往旁边让了让。",
		"neutral": "他守着火。",
		"bad": "他把火种收了起来。",
	},
	"西西弗斯": {
		"good": "「来帮我。」",
		"neutral": "石头又滚下来了。",
		"bad": "他放下石头，看着你。",
	},
	"齐格弗里德": {
		"good": "「走我后面。」",
		"neutral": "他一个人走。",
		"bad": "「别碰我的血。」",
	},
	"布伦希尔德": {
		"good": "她把纸条翻到新的一页。",
		"neutral": "她在写。\n没有抬头。",
		"bad": "她把纸条收起来了。",
	},
	"洛基": {
		"good": "「坐。」他拍了拍旁边的位置。",
		"neutral": "他在笑。\n影子慢半步。",
		"bad": "「我等你很久了。」",
	},
	"海姆达尔": {
		"good": "他朝东边指了指，又指了指你。",
		"neutral": "他还在守夜。",
		"bad": "他挡在路中间。",
	},
	"提尔": {
		"good": "「说吧。」他伸出左手。",
		"neutral": "他用左手朝你行了礼。",
		"bad": "「这次我不能答应。」",
	},
}

# 好感 ≥ 70：可以结盟、可以收礼
const BOND_CHOICES := [
	{"label": "「一起走到最后。」", "result": "talk", "ally": true, "favor": 15, "text": "他没说话，站到了你身后。"},
	{"label": "收下他给的东西", "result": "talk", "favor": 5, "random_cards": 1, "text": "他把东西塞进你手里。"},
	{"label": "「路上小心。」", "result": "leave", "favor": 3, "text": "他点了点头。"},
]

# 好感 30~69：可以做交易
const FRIEND_CHOICES := [
	{"label": "和他换点东西（-15 金币）", "result": "talk", "gold": -15, "favor": 8, "random_cards": 1, "text": "「用得上。」他说。"},
	{"label": "坐下来聊一会", "result": "talk", "favor": 5, "hp": 5, "text": "你们聊了一阵。\n他没问你要去哪。"},
	{"label": "道别", "result": "leave", "favor": 0, "text": "他目送你走远。"},
]

# 好感 -29~29：互相试探
const NEUTRAL_CHOICES := [
	{"label": "点个头", "result": "talk", "favor": 5, "text": "他也点了点头。"},
	{"label": "绕开", "result": "leave", "favor": 0, "text": "你们擦肩而过。"},
	{"label": "先下手", "result": "fight", "favor": -20},
]

# 好感 -69~-30：敌意，但还能退
const HOSTILE_CHOICES := [
	{"label": "退开一步", "result": "leave", "favor": 4, "text": "他盯着你。\n没有追。"},
	{"label": "把东西放在地上（-10 金币）", "result": "talk", "gold": -10, "favor": 8, "text": "他看了一眼。\n没捡。"},
	{"label": "先动手", "result": "fight", "favor": -10},
]

func get_contestant(id: String) -> Dictionary:
	return CONTESTANTS[id]

func name_of(id: String) -> String:
	return CONTESTANTS[id]["name"]

func resolve_cards(reward: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if reward.has("cards"):
		for c in reward["cards"]:
			result.append(str(c))
	if reward.has("random_cards"):
		var count: int = int(reward["random_cards"])
		var pool: Array = CardDB.reward_pool()
		for i in range(count):
			result.append(str(pool[randi() % pool.size()]))
	return result

func pick_roster(count: int) -> Array[String]:
	var pool: Array = CONTESTANTS.keys()
	pool.shuffle()
	var result: Array[String] = []
	for i in range(min(count, pool.size())):
		result.append(pool[i])
	return result
func scaled(id: String) -> Dictionary:
	var c: Dictionary = CONTESTANTS[id].duplicate()
	var mult: float = 1.0 + 0.08 * float(GameState.transmigration - 1)
	var result := c.duplicate()
	result["hp"] = int(float(c["hp"]) * mult)
	result["attack"] = int(float(c["attack"]) * mult)
	return result
# 立场：evil / good / neutral（也可以在某位参赛者里写 "tendency" 覆盖）
func tendency_of(id: String) -> String:
	var c: Dictionary = CONTESTANTS.get(id, {})
	if c.has("tendency"):
		return str(c["tendency"])
	var t := str(c.get("trait", ""))
	if t in ["好战", "狡诈", "贪婪", "疯狂"]:
		return "evil"
	if t in ["虔诚", "虚弱"]:
		return "good"
	return "neutral"

# 本次选择对印象的影响
func impression_delta(id: String, choice: Dictionary) -> int:
	var d: int = int(choice.get("favor", 0)) * IMPRESSION_SCALE
	if str(choice.get("result", "talk")) == "fight":
		d -= 20 * IMPRESSION_SCALE
	if choice.get("ally", false):
		d += 20 * IMPRESSION_SCALE
	var tendency := tendency_of(id)
	var moral_part: int = int((GameState.morality - 50) / 10.0) * IMPRESSION_SCALE
	var sin_part: int = int(GameState.sin / 10.0) * IMPRESSION_SCALE
	if tendency == "good":
		d += moral_part - sin_part
	elif tendency == "evil":
		d += sin_part - moral_part
	return d

# 第 meet 次遇见的场景（0 = 初次）
func scene_for(id: String, meet: int) -> Dictionary:
	var c: Dictionary = CONTESTANTS[id]
	if meet <= 0:
		return {"text": str(c["desc"]), "choices": c["choices"]}

	var imp: int = int(GameState.impressions.get(id, 0))
	var lines: Dictionary = MEET_LINES.get(id, {})

	if imp >= 70:
		return {"text": _meet_line(lines, "good", c), "choices": BOND_CHOICES}
	if imp >= 30:
		return {"text": _meet_line(lines, "good", c), "choices": FRIEND_CHOICES}
	if imp <= -70:
		return {"text": _meet_line(lines, "bad", c), "choices": HOSTILE_CHOICES, "auto_fight": true}
	if imp <= -30:
		return {"text": _meet_line(lines, "bad", c), "choices": HOSTILE_CHOICES}
	return {"text": _meet_line(lines, "neutral", c), "choices": NEUTRAL_CHOICES}

func _meet_line(lines: Dictionary, tier: String, c: Dictionary) -> String:
	var t := str(lines.get(tier, ""))
	if t == "":
		return "「%s」看了你一眼。" % str(c["name"])
	return t

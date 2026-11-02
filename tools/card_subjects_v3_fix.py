# -*- coding: utf-8 -*-
"""卡面 v3b 自查发现的问题卡 → 改写后的描述（下一轮重出用）

规律：
  · corpse / dead / bone / skull → 被画成骷髅脸 ⇒ 换成「闭着眼的人」「躺着的人」
  · staring at / facing / looking at → 被画成物件 ⇒ 换成明确的身体动作
  · walking away / turning back → 只有背影 ⇒ 加 face visible / 改侧面
  · distant / far away → 脸太小 ⇒ 改半身特写
"""

FIXES = {
    # 被画成物件
    "遗忘": "an old man running his fingers over a worn stone tablet, face visible, eyes sad",
    "久候": "an old woman sitting on the edge of a chair, face toward the viewer, hands on her knees",
    "擎旗": "a standard-bearer gripping a torn banner pole with both hands, face raised",
    "落子": "a young man pressing a black stone onto a wooden board, face down in thought",
    "记债": "a moneylender carving a tally stick, face close to the viewer",
    # 只有背影 / 脸太小
    "守夜": "a watchman raising a lantern beside his face, eyes tired, stone wall behind",
    "剑息": "a duelist holding a thin blade up to his own face, breath fogging the steel",
    "余温": "a woman cupping a warm teacup close to her face, eyes closed, steam rising",
    "浮木": "a drowning sailor clutching driftwood, face above the water, mouth open",
    "呛水": "a man coughing water out, wet hair over his face, water up to his chest",
    # 被画成骷髅
    "入殓": "a mourner gently closing a coffin lid, face lowered, candle on the side",
    "啃食": "a starving man biting into a strip of dried meat, face gaunt but human",
    # 其它
    # 第 3 批发现
    "星位": "a young astronomer pointing up at the sky, face turned up and visible, star chart in hand",
    "翻页": "a scholar turning a page of an old book, face close to the pages, candlelit",
    "将军": "a commander tipping a crowned chess piece over, face visible, board in front",
    "旗不倒": "a wounded soldier holding a torn banner upright, face lit by firelight",
    "送行": "a mourner setting a bowl of wine down, face visible, head raised",
    "传说": "an old storyteller looking up from an illustrated book, face visible, listeners unseen",
    "余火": "a survivor warming his hands over a dying fire, face lit orange, looking up",
    # 第 4-5 批发现（物件当主语 / 背影 导致人消失）
    "忏悔": "a sinner kneeling inside a confessional, face lit through the lattice",
    "血约": "a warlord slicing his own finger over a scroll, face grim, blood on the page",
    "神谕": "a prophet holding a scroll up to the light, face lit by one glowing line",
    "苦修": "a monk with a knotted scourge over his shoulder, face turned up in pain",
    "毒牙": "a painted shaman holding a curved fang to the light, face visible",
    "誓约": "two knights clasping hands over an iron ring, both faces in profile",
    "圣光弹": "a cleric hurling a sphere of light forward, arm extended, face visible",
    "突刺": "a spearman lunging forward, spike leading, face visible",
    "毒潮": "a cultist pouring green liquid onto the floor, face visible, sleeves soaked",
    "铁骨": "a bare-knuckled brawler flexing his forearm, face visible, teeth bared",
    "坚壁": "a mason laying a stone into a wall, face visible, dust on his hands",
    "拒马": "a sapper driving an iron caltrop into the road, face visible",
    "防御": "a knight raising a round shield, eyes looking over the rim",
    "盾墙": "two soldiers shoulder to shoulder behind raised shields, faces toward the viewer",
    # 第 6 轮：仍不合格的 6 张
    "记债": "a moneylender writing in a ledger under a lamp, face visible, stack of tally sticks beside him",
    "将军": "an old commander standing over a chessboard, one hand pushing a piece over, face visible",
    "翻页": "a girl reading a heavy book on her lap, one hand turning the page, face visible",
    "余火": "a survivor sitting by a dying fire, face lit orange, looking forward",
    "拒马": "a soldier bending to set an iron spiked barricade across a road, face visible",
    "毒潮": "a hooded poisoner tipping a jar, green liquid spilling, face in profile",
    # 用户反馈「意义不明」的 4 张
    "打击": "a young swordsman mid-swing with both hands on the hilt, face toward the viewer, cloak flying",
    "毒潮": "a woman tipping a jar of green liquid onto the floor, face visible in profile, sleeves stained",
    "防御": "a young soldier holding a round shield up in front of his chest, eyes looking over the rim",
    "铁骨": "a bare-chested strongman flexing both arms, face visible, old scars across his chest",
}

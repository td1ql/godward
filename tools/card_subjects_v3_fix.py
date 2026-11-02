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
}

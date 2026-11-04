# -*- coding: utf-8 -*-
"""卡面 v8 描述修正表

v7 最大的失分点是「描述里写了道具，模型没画出来」；v8 改用「双手压/握/抵住 X」句式。
这里按卡覆盖描述，命名与 CardDB 一致，生成脚本会自动叠加在 v4 描述表之上。
"""

FIXES_V8 = {
    # 用户要求：左手持剑，脸朝镜头、不要崩
    "打击": (
        "a young swordsman swinging a longsword downward with his left hand, right hand empty and open, "
        "body in three-quarter view, face turned toward the viewer, clean symmetrical face, clear sharp eyes, "
        "calm focused expression, short pale hair"
    ),
    # 用户指定：不穿上衣、露胸、胸口有旧疤（旧伤）
    "旧伤": (
        "a man with his robe open, bare chest, a long pale old scar across his chest and ribs, "
        "no bandages, modest, face turned to the viewer, clean face with no marks, short pale hair"
    ),
    # 用户指定：V1 动作——抬手告别（送行）
    "送行": (
        "a young man standing and raising one hand in farewell, the other hand at his side, "
        "face turned to the viewer, clean face with no marks, short pale hair"
    ),
    # 用户指定：启程（抽卡）
    "启程": (
        "a traveler walking away from a small house at dawn, pack on his back, "
        "face turned back to the viewer, clean face with no marks, short pale hair"
    ),
    # 用户指定：换一张脸（少年），跪坐整理物资（行囊）
    "行囊": (
        "a young man with a refined delicate face and short pale hair, kneeling beside a spread cloth "
        "with travel supplies laid out, sorting them with both hands, face turned toward the viewer, "
        "clean face with no marks"
    ),
    # 用户指定：V3 构图——大月亮下走夜路
    "夜路": (
        "a young traveler walking toward the viewer on a night road under a huge pale moon, "
        "a long robe and a cape blown by the wind, face turned to the viewer, "
        "clean face with no marks, short pale hair"
    ),
    # 用户指定：大远景 + 飘荡的披风（远路）
    "远路": (
        "wide shot, a lone traveler walking a long road, a long tattered cloak billowing in the wind, "
        "seen from behind, staff in one hand"
    ),
    # 用户指定：X5 构图——长刃斜横过胸前、脸正对镜头
    "开刃": (
        "close view of a long sword blade held diagonally across his chest, the whole blade visible from hilt to tip, "
        "face turned to the viewer, clean face with no marks, short pale hair"
    ),
    # 用户指定：保留这个女孩的形象，手握药瓶向外泼洒 + 光点/迷雾
    "催化": (
        "a young woman with hair in two buns and a dark robe, gripping a small glass bottle in one hand "
        "and flinging it outward, dark liquid splashing out in an arc, "
        "tiny bright light specks floating in the air, drifting mist around the splash, "
        "face turned to the viewer, clean face with no marks"
    ),
    # 用户指定：W3 的姿势——横剑在身前；年龄大、剑更长、手别变形（单手，减少手部出错）
    "试刀": (
        "a middle-aged swordsman in his forties with a weathered mature face and light stubble, "
        "holding a long sword horizontally in one hand, the long blade crossing in front of him, "
        "the other hand empty at his side, the gripping hand clearly visible with five fingers, "
        "face turned to the viewer, clean face with no marks, short pale hair"
    ),
    # 用户指定：手提着一个小毒药瓶 + 人物天真无邪
    "剧毒": (
        "an innocent young woman with a soft round face, large clear eyes, gentle naive smile, "
        "holding a small glass bottle of dark poison up in one hand, the bottle clearly visible with dark liquid inside, "
        "face turned to the viewer, clean face with no marks, short pale hair"
    ),
    # 用户指定：横举一把短剑于胸前，剑上滴着毒液
    "毒刃": (
        "holding a short sword level across his chest with one hand, the whole blade visible, "
        "dark venom dripping from the blade edge, drops falling from the steel, "
        "face turned to the viewer, clean face with no marks, short pale hair"
    ),
    # 用户要求：脸不要崩、抬头；蹲着低头看碗会让脸全低下去，改成把碗端到胸口
    "淬毒": (
        "kneeling and holding a shallow stone bowl of dark liquid up at chest height with one hand, "
        "a dagger held above the bowl in the other hand, looking at the viewer, clean symmetrical face, "
        "calm cold expression, short pale hair"
    ),
}

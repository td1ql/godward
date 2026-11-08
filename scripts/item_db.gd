extends Node

# ============================================================
# ItemDB —— 物品表
# ------------------------------------------------------------
# 「物品」= 由掉落物合成、或在商店买的东西。三种用途：
#
#   ① 战斗中使用（kind = "battle"）
#        use = "instant"  一次性，用完就没了
#        use = "multi"    能用 max_uses 次，用完才消失
#        use = "perm"     本局永久生效，拿到就自动挂上，不需要"使用"
#
#   ② 与英雄交互（kind = "hero"）
#        送出去 → 提升好感 / 拿到信物 / 让对方自愿退出比赛
#
#   ③ 纯被动（kind = "passive"）
#        拿到就一直生效（往 GameState.item_perms 里加）
#
# 现在表是空的 —— 框架先搭好，内容后面再填。
# ============================================================
#
# 每一条的写法：
#
#   "安神香": {
#       "name": "安神香",
#       "desc": "闻起来像雨后的石头。",
#       "kind": "hero",                       # battle / hero / passive
#       "use": "instant",                     # instant / multi / perm
#       "max_uses": 1,                        # 只有 multi 用
#       "favor": 12,                          # 送给英雄加多少好感
#       "gift_tag": "香",                     # 英雄认不认这类礼物（留给内容阶段用）
#       "battle": {                           # kind = battle 时的效果，字段与卡牌一致
#           "damage": 0, "block": 10, "heal": 0,
#           "status": {}, "self_status": {},  # status 挂给敌人 / self_status 挂给自己
#           "draw": 0, "gain_energy": 0,
#       },
#       "perm": {"draw": 1},                  # kind = passive 时往 item_perms 里加的东西
#       "price": 120,
#   },
#
# 合成配方写在下面的 RECIPES：物品 id → { 掉落物 id: 需要几个 }
# ============================================================

const ITEMS := {
	"晴天项链": {
		"name": "晴天项链",
		"desc": "象征着恒久晴天的项链，被当作礼物赠与他人时代表着最真挚的祝福。",
		"kind": "hero",
		"use": "instant",
		"favor": 20,
		"price": 200,
	},
}

const RECIPES := {
	"晴天项链": {"粗蜘蛛线": 1, "火焰精华": 1},
}


# ---------- 查询 ----------

func has(id: String) -> bool:
	return ITEMS.has(id)


func info(id: String) -> Dictionary:
	return ITEMS.get(id, {})


func name_of(id: String) -> String:
	return str(ITEMS.get(id, {}).get("name", id))


func desc_of(id: String) -> String:
	return str(ITEMS.get(id, {}).get("desc", ""))


func kind_of(id: String) -> String:
	return str(ITEMS.get(id, {}).get("kind", "battle"))


func use_mode_of(id: String) -> String:
	return str(ITEMS.get(id, {}).get("use", "instant"))


func max_uses_of(id: String) -> int:
	return maxi(1, int(ITEMS.get(id, {}).get("max_uses", 1)))


func price_of(id: String) -> int:
	return int(ITEMS.get(id, {}).get("price", 0))


func battle_spec(id: String) -> Dictionary:
	return ITEMS.get(id, {}).get("battle", {})


func favor_of(id: String) -> int:
	return int(ITEMS.get(id, {}).get("favor", 0))


func perm_of(id: String) -> Dictionary:
	return ITEMS.get(id, {}).get("perm", {})


func recipe_of(id: String) -> Dictionary:
	return RECIPES.get(id, {})


func can_use_in_battle(id: String) -> bool:
	return kind_of(id) == "battle" and use_mode_of(id) != "perm"


func can_give_to_hero(id: String) -> bool:
	return kind_of(id) == "hero" or favor_of(id) > 0


# 所有「本局永久生效」的物品 id
func all_perm_items() -> Array:
	var out: Array = []
	for id in ITEMS.keys():
		if use_mode_of(id) == "perm":
			out.append(id)
	return out


# 商店里卖的物品（表空就空）
func shop_pool(act: int = 1) -> Array:
	var out: Array = []
	for id in ITEMS.keys():
		if int(ITEMS[id].get("min_act", 1)) <= act:
			out.append(id)
	return out

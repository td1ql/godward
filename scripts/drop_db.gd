extends Node

# ============================================================
# DropDB —— 掉落物表（打败敌人后掉的东西）
# ------------------------------------------------------------
# 「掉落物」= 材料。自己不能直接用，用来：
#   ① 在休息处合成物品（见 ItemDB.RECIPES）
#   ② 在商店卖出 / 买进
#   ③ 当作礼物送给英雄（见 ContestantDB.give_gift）
#
# 现在表是空的 —— 框架先搭好，内容后面再填。
# ============================================================
#
# 每一条的写法：
#
#   "骨屑": {
#       "name": "骨屑",              # 显示名（和 key 一致就行）
#       "desc": "从某处刮下来的。",   # 背包里显示的一行说明
#       "tier": 1,                   # 1 = 普通怪掉 / 2 = 精英 / 3 = Boss
#       "from": ["battle", "elite"], # 哪些节点会掉（"battle"/"elite"/"boss"/"god"/"divine"...）
#       "weight": 10,                # 同 tier 里的抽取权重，越大越常见
#       "price": 20,                 # 商店买入价（卖出默认是 1/3）
#   },
#
# 注意：tier 只影响「从哪掉」，不影响能不能合成。
# ============================================================

const DROPS := {
	"粗蜘蛛线": {
		"name": "粗蜘蛛线",
		"desc": "毒蜘蛛吐出来的丝，比头发还韧。",
		"tier": 1,
		"from_enemy": ["毒蜘蛛"],
		"weight": 10,
		"price": 8,
	},
	"火焰精华": {
		"name": "火焰精华",
		"desc": "火元素体内凝下来的一点热，装在小瓶里还烫手。",
		"tier": 1,
		"from_enemy": ["火元素"],
		"weight": 10,
		"price": 12,
	},
}


# ---------- 查询 ----------

func has(id: String) -> bool:
	return DROPS.has(id)


func info(id: String) -> Dictionary:
	return DROPS.get(id, {})


func name_of(id: String) -> String:
	return str(DROPS.get(id, {}).get("name", id))


func desc_of(id: String) -> String:
	return str(DROPS.get(id, {}).get("desc", ""))


func price_of(id: String) -> int:
	return int(DROPS.get(id, {}).get("price", 0))


func sell_price_of(id: String) -> int:
	return int(floor(float(price_of(id)) / 3.0))


func tier_of(id: String) -> int:
	return int(DROPS.get(id, {}).get("tier", 1))


# 某类节点能掉的全部掉落物 id
func pool_for_node(node_type: String) -> Array:
	var out: Array = []
	for id in DROPS.keys():
		var from: Array = DROPS[id].get("from", [])
		if from.is_empty() or from.has(node_type):
			out.append(id)
	return out


# 某个敌人体内能掉的全部掉落物 id（按敌人名字匹配，这是主要的取法）
# 没写 from_enemy 的条目视为「任何敌人都可能掉」
func pool_for_enemy(enemy_name: String) -> Array:
	var out: Array = []
	for id in DROPS.keys():
		var fe: Array = DROPS[id].get("from_enemy", [])
		var fn: Array = DROPS[id].get("from", [])
		if fe.is_empty() and fn.is_empty():
			out.append(id)
		elif fe.has(enemy_name):
			out.append(id)
	return out


# ---------- 抽取 ----------
# count 个掉落物（按 weight 加权，不放回）
# 表为空时返回空数组 —— 调用方不用特判
func roll(node_type: String, count: int = 1) -> Array:
	var out: Array = []
	var pool := pool_for_node(node_type)
	if pool.is_empty():
		return out
	var left := pool.duplicate()
	for _i in range(count):
		if left.is_empty():
			break
		var total := 0
		for id in left:
			total += maxi(1, int(DROPS[id].get("weight", 1)))
		if total <= 0:
			break
		var pick := randi() % total
		var chosen := str(left[left.size() - 1])
		for id in left:
			pick -= maxi(1, int(DROPS[id].get("weight", 1)))
			if pick < 0:
				chosen = str(id)
				break
		out.append(chosen)
		left.erase(chosen)
	return out


# 商店进什么货：按 tier 过滤后的列表（空表安全）
func shop_pool(max_tier: int = 3) -> Array:
	var out: Array = []
	for id in DROPS.keys():
		if tier_of(id) <= max_tier:
			out.append(id)
	return out

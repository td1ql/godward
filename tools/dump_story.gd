extends RefCounted

# ============================================================
# dump_story.gd —— 把游戏里所有剧情文本抽成一份 Markdown
# 用法：
#   godot --headless --path . --quit-after 200 -- --dump-story
# 输出：
#   docs/STORY.md
#
# 每段都带 key（例如 [prologue/2]），改完把文档发回来即可按 key 反写。
# ============================================================

const OUT_PATH := "res://docs/STORY.md"


static func write() -> void:
	var L: PackedStringArray = []
	L.append("# 剧情文本总表")
	L.append("")
	L.append("游戏里**所有**对白 / 旁白 / 事件 / 英雄台词。每段前面带 `key`，改完按 key 能直接对回代码。")
	L.append("")
	L.append("`\\n` 是换行，`「」` 和 `（）` 按原文保留。")
	L.append("")

	_dump_dialogue(L)
	_dump_story(L)
	_dump_events(L)
	_dump_contestants(L)
	_dump_remnants(L)
	_dump_vocations(L)
	_dump_misc(L)

	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if f == null:
		push_error("写不了 %s" % OUT_PATH)
		return
	f.store_string("\n".join(L) + "\n")
	f.close()
	print("已写出 %s（%d 行）" % [OUT_PATH, L.size()])


static func _q(s: String) -> String:
	# 保留原文，只把过长的一行折开
	return s


# ---------- 1. 对白（序章 / 神国 / 第三幕 / 结局 / 教皇） ----------
static func _dump_dialogue(L: PackedStringArray) -> void:
	L.append("---")
	L.append("")
	L.append("## 一、主线对白（dialogue_db.gd · LINES）")
	L.append("")
	for key in DialogueDB.LINES:
		L.append("### %s" % str(key))
		L.append("")
		var arr: Array = DialogueDB.LINES[key]
		for i in range(arr.size()):
			var it: Dictionary = arr[i]
			var sp := str(it.get("speaker", ""))
			var tx := str(it.get("text", "")).replace("\n", " ⏎ ")
			var bg := str(it.get("bg", ""))
			var tail := "" if bg == "" else "　`[换背景]`"
			L.append("- **[%s/%d] %s**：%s" % [str(key), i, sp, tx + tail])
		L.append("")


# ---------- 2. Short StoryDB 文案 ----------
static func _dump_story(L: PackedStringArray) -> void:
	L.append("---")
	L.append("")
	L.append("## 二、界面文案（story_db.gd · TEXTS）")
	L.append("")
	L.append("| key | 文本 |")
	L.append("|-----|------|")
	for key in StoryDB.TEXTS:
		var v := str(StoryDB.TEXTS[key]).replace("\n", " ⏎ ")
		L.append("| `%s` | %s |" % [str(key), v])
	L.append("")


# ---------- 3. 事件 ----------
static func _dump_events(L: PackedStringArray) -> void:
	var pools := [
		["第一幕事件（EVENTS）", EventDB.EVENTS],
		["第二幕事件（DIVINE_EVENTS）", EventDB.DIVINE_EVENTS],
		["第三幕事件（ACT3_EVENTS）", EventDB.ACT3_EVENTS],
	]
	L.append("---")
	L.append("")
	L.append("## 三、事件（event_db.gd）")
	L.append("")
	for p in pools:
		L.append("### %s" % str(p[0]))
		L.append("")
		var arr: Array = p[1]
		for i in range(arr.size()):
			var ev: Dictionary = arr[i]
			L.append("#### [%d] 正文" % i)
			L.append("")
			L.append("```")
			L.append(str(ev.get("text", "")))
			L.append("```")
			L.append("")
			for c in ev.get("choices", []):
				var lbl := str(c.get("label", ""))
				var txt := str(c.get("text", "")).replace("\n", " ⏎ ")
				L.append("- **选项**：%s" % lbl)
				if txt != "":
					L.append("  - 结果：%s" % txt)
			L.append("")


# ---------- 4. 英雄 ----------
static func _dump_contestants(L: PackedStringArray) -> void:
	L.append("---")
	L.append("")
	L.append("## 四、十八位英雄（contestant_data.gd）")
	L.append("")
	for id in ContestantData.CONTESTANTS:
		var c: Dictionary = ContestantData.CONTESTANTS[id]
		L.append("### %s" % str(id))
		L.append("")
		L.append("- **称号**：%s" % str(c.get("trait", "")))
		L.append("- **第一幕三行**：")
		L.append("  ```")
		for ln in str(c.get("desc", "")).split("\n"):
			L.append("  " + ln)
		L.append("  ```")
		if c.has("desc3"):
			L.append("- **第三幕三行**：")
			L.append("  ```")
			for ln2 in str(c.get("desc3", "")).split("\n"):
				L.append("  " + ln2)
			L.append("  ```")
		if c.has("ally_line"):
			L.append("- **决战时盟友台词**：「%s」" % str(c.get("ally_line", "")))
		if c.has("choices"):
			L.append("- **第一幕选项**：")
			for ch in c["choices"]:
				var t := str(ch.get("text", "")).replace("\n", " ⏎ ")
				L.append("  - `%s` → %s" % [str(ch.get("label", "")), t])
		for key in ["kill", "spare"]:
			if c.has(key):
				var r: Dictionary = c[key]
				var t2 := str(r.get("text", "")).replace("\n", " ⏎ ")
				var label := "杀死他" if key == "kill" else "放过他"
				L.append("- **%s**：%s" % [label, t2])
		L.append("")

	L.append("### 遇见时的台词（MEET_LINES）")
	L.append("")
	for id in ContestantData.MEET_LINES:
		L.append("- **%s**" % str(id))
		var tiers: Dictionary = ContestantData.MEET_LINES[id]
		for tier in tiers:
			var lines: Array = tiers[tier]
			for ln in lines:
				L.append("  - `%s` %s" % [str(tier), str(ln)])
	L.append("")


# ---------- 5. 残余 ----------
static func _dump_remnants(L: PackedStringArray) -> void:
	L.append("---")
	L.append("")
	L.append("## 五、残余节点（remnant_db.gd）")
	L.append("")
	L.append("### 开场白（OPENINGS）")
	L.append("")
	for i in range(RemnantDB.OPENINGS.size()):
		L.append("- **[%d]** %s" % [i, str(RemnantDB.OPENINGS[i]).replace("\n", " ⏎ ")])
	L.append("")
	L.append("### 每位英雄的遗言（REMNANTS）")
	L.append("")
	for r in RemnantDB.REMNANTS:
		if r is Dictionary:
			var who := str(r.get("name", r.get("id", "?")))
			var say := str(r.get("line", r.get("text", "")))
			L.append("- **%s**：%s" % [who, say.replace("\n", " ⏎ ")])
	L.append("")


# ---------- 6. 职业 ----------
static func _dump_vocations(L: PackedStringArray) -> void:
	L.append("---")
	L.append("")
	L.append("## 六、十六个职业（trait_db.gd · VOCATIONS）")
	L.append("")
	for id in TraitDB.VOCATIONS:
		var v: Dictionary = TraitDB.VOCATIONS[id]
		L.append("### %s" % str(id))
		L.append("")
		L.append("- **描述**：%s" % str(v.get("desc", "")))
		if v.has("remnant"):
			L.append("- **残余文本**：%s" % str(v.get("remnant", "")))
		var cr: Dictionary = v.get("creed", {})
		if not cr.is_empty():
			L.append("- **守则【%s】**：%s" % [str(cr.get("name", "")), str(cr.get("desc", ""))])
		L.append("")


# ---------- 7. 其他 ----------
static func _dump_misc(L: PackedStringArray) -> void:
	L.append("---")
	L.append("")
	L.append("## 七、其他")
	L.append("")
	L.append("### 器官（organ_db.gd）")
	L.append("")
	for k in OrganDB.ORGANS:
		L.append("- **%s**：%s" % [str(k), str(OrganDB.ORGANS[k].get("desc", ""))])
	L.append("")
	L.append("### 空壳（map.gd · SHELLS）")
	L.append("")
	var shells: Array = preload("res://scripts/map.gd").SHELLS
	for i in range(shells.size()):
		var sh: Dictionary = shells[i]
		L.append("#### [%d]" % i)
		L.append("```")
		for ln in str(sh.get("text", "")).split("\n"):
			L.append(ln)
		L.append("```")
		for c in sh.get("choices", []):
			L.append("- **选项**：%s" % str(c.get("label", "")))
			if c.has("text"):
				L.append("  - 结果：%s" % str(c["text"]).replace("\n", " ⏎ "))
		L.append("")

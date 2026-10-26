「逐神 / Godward」

> **测试版 1.0** ✅ 三幕流程可完整游玩，数值仍在调整。

一款 **Roguelike 卡牌构筑** 游戏，使用 **Godot 4.7** 开发。灵感来自《杀戮尖塔》，核心玩法围绕「手牌经济」展开。

## 世界观

上古众神的黄金时代之后，灭世之蛇耶梦加得咬断了世界树的根脉。
众神被污染、上帝陷入疯狂。你是一点「来自世界之外的灵光」——
也是上帝最后的一点思绪。

老教皇借神明之口办了一场「逐神」的游戏：
胜者可以觐见神明。教堂里什么都没有。
胜者被改造成虚假的世界树，撑起虚假之神国。

三幕：**人间** → **虚假的神国** → **昔日的神明之土**

## 核心机制

- **径向地图**：玩家始终在屏幕中心，可去的节点向外辐射，选择路径推进。
- **三种卡牌**
  - **行动牌**：只消耗能量。
  - **效果牌**：消耗能量 + 消耗若干张其他手牌。
  - **遭遇牌**：抽到立即生效，不进入手牌（可设每场次数）。
- **起手 5 张 / 之后每回合**：基础 4 张 + 上回合剩余能量。
- **回合结束弃掉手牌**：不会跨回合累积。
- **22 种状态**：中毒 / 流血 / 力量 / 虚弱 / 易伤 / 再生 / 毒性增长 / 重力 …
- **敌人领域**：每场战斗的敌人可能有特殊规则（加费 / 吸能量 / 荆棘 / 禁疗 …）。
- **敌人意图**：战斗界面可预判敌人下回合的行动。

## 玩法

| 节点 | 作用 |
|------|------|
| 战斗 | 普通敌人，胜利获得金币并可三选一加牌 |
| 精英 | 更强的敌人，金币更多，可获效果牌 |
| 商店 | 用金币买牌（单卡独立定价） |
| 休息 | 回复生命 |
| 事件 | 随机剧情，多选项（会给牌的选项会标出卡牌效果） |
| 参赛者 | 五位英雄之一，可交谈 / 杀死 / 结盟 |
| 残余 | 过去某一世的自己，给专属强力牌 |
| 首领 | 六位教父守门人之一 |

### 三幕差异

| 幕 | 内容 |
|----|------|
| 第一幕 | 人间。5 位参赛英雄，逐神游戏 |
| 第二幕 | 虚假神国。没有英雄——只有玩家能进教堂。神国守卫 / 教皇 |
| 第三幕 | 昔日的神明之土。**18 位英雄全部登场**，可杀死或结盟；财富之神（用金币买属性）；没有商店和精英；最终 BOSS 耶梦加得 |

### 三个结局（由神性决定）

| 神性 | 结局 |
|------|------|
| 71+ | 神座 · 上帝复苏 |
| 31~70 | 薪火 · 前路未卜 |
| 0~30 | 沉沦 · 人间沉沦 |

## 运行

1. 下载 [Godot 4.7](https://godotengine.org/download)（Standard 版即可）
2. 用 Godot 导入本目录的 `project.godot`
3. 按 `F5` 运行

## 构建与发布

见 [docs/BUILD.md](docs/BUILD.md)。

推 tag 会自动构建 Windows + Android 并发布到 Releases：

```bash
git tag -a v2.0.0 -m "v2.0.0"
git push origin v2.0.0
```

## 项目结构

```
scripts/
  # 数据层
  card_db.gd  enemy_db.gd  status_db.gd  map_db.gd  node_rule_db.gd
  event_db.gd  shop_db.gd  reward_db.gd  run_config.gd
  contestant_data.gd  contestant_db.gd  organ_db.gd
  remnant_db.gd  trait_db.gd  story_db.gd  dialogue_db.gd
  # 运行时
  game_state.gd          # 全局状态 + 多存档
  # 战斗模块
  deck.gd  damage.gd  status_system.gd  enemy_state.gd
  card_ui.gd  hand_view.gd  toast.gd  deck_viewer.gd
  # 场景
  main_menu.gd  save_menu.gd  run_intro.gd  map.gd  battle_demo.gd
  # UI 组件
  ui_kit.gd  modal.gd  dialogue.gd  nav_menu.gd  map_help.gd  status_help.gd
  # 系统
  audio_manager.gd  tutorial.gd  morality.gd  meta_pick.gd
scenes/
  main_menu.tscn  save_menu.tscn  run_intro.tscn  map.tscn  main.tscn
assets/
  art/    背景 / 卡面流派图 / 节点图标 / 剧情插图（全部 WebP）
  audio/  7 首 BGM + 9 个音效
  fonts/  子集化的 Noto CJK（31.4 MB → 1.19 MB）
tools/
  subset_fonts.py        # 改了文案要重跑，否则新字会显示成方块
```

## 数据驱动

扩充内容基本只需改对应的 DB 文件：

| 想加什么 | 改哪里 |
|----------|--------|
| 卡牌 | `card_db.gd` 的 `CARDS` |
| 敌人 | `enemy_db.gd` 的 `NORMAL / ELITE / BOSS / DIVINE / DIVINE_ELITE / GODS / POPE / TREE / SERPENT` |
| 状态 | `status_db.gd` 的 `STATUS`（新增记得在 `battle_demo.gd` 里实现） |
| 地图层数/节点 | `map_db.gd` |
| 事件 | `event_db.gd` |
| 节点奖励 | `node_rule_db.gd` 的 `RULES` |
| 英雄 | `contestant_data.gd`（纯数据）/ `contestant_db.gd`（逻辑） |
| 器官 | `organ_db.gd` 的 `ORGANS` |
| 平衡数值 | `run_config.gd` |

## 更新日志

- **v1.0.0 测试版**：三幕完整版。第三幕（18 英雄 / 财富之神 / 耶梦加得）、三个结局、6 位教父守门人、8 个流派卡面图、7 首 BGM + 9 音效、通关解锁自由配置、字体子集化
- **v1.4.0**：第二幕（虚假神国）、教皇、器官系统
- **v1.3.0**：第三幕地图骨架、神性系统
- **v1.2.0**：18 位英雄、结盟系统
- **v1.1.0**：效果牌、遭遇牌、状态系统
- **v1.0.0**：首个可玩版本（径向地图、手牌经济、战斗、商店/事件/休息、多存档、通关结算）

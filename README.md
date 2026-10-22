「逐神 / Godward」

一款 **Roguelike 卡牌构筑** 游戏，使用 **Godot 4.7** 开发。灵感来自《杀戮尖塔》，核心玩法围绕「手牌经济」展开。

## 核心机制

- **径向地图**：玩家始终在屏幕中心，可去的节点向外辐射，选择路径推进。
- **三种卡牌**
  - **行动牌**：只消耗能量。
  - **效果牌**：消耗能量 + 消耗若干张其他手牌。
  - **遭遇牌**：抽到立即生效，不进入手牌。
- **手牌不弃**：回合结束时，剩余手牌保留。
- **能量换抽牌**：回合结束时，剩余能量转化为等量抽牌（另有默认抽牌）。
- **状态系统**：中毒 / 虚弱 / 易伤 / 力量。
- **敌人意图**：战斗界面可预判敌人下回合的行动。

## 玩法

| 节点 | 作用 |
|------|------|
| 战斗 | 普通敌人，胜利获得金币并可三选一加牌 |
| 精英 | 更强的敌人，金币更多，可获效果牌 |
| 商店 | 用金币买牌（单卡独立定价） |
| 休息 | 回复 30% 生命 |
| 事件 | 随机剧情，多选项（金币不足的选项不可选） |
| 首领 | 最终战，击败后进入通关结算 |

> 构建、发版、常见报错见 [docs/BUILD.md](docs/BUILD.md)

## 运行

1. 下载 [Godot 4.7](https://godotengine.org/download)（Standard 版即可）
2. 用 Godot 导入本目录的 `project.godot`
3. 按 `F5` 运行

## 项目结构

```
scripts/
  # 数据层
  card_db.gd  enemy_db.gd  status_db.gd  map_db.gd
  event_db.gd  shop_db.gd  reward_db.gd  run_config.gd
  # 运行时
  game_state.gd          # 全局状态 + 多存档
  # 战斗模块
  deck.gd  damage.gd  status_system.gd  enemy_state.gd
  card_ui.gd  hand_view.gd  toast.gd  deck_viewer.gd
  # 场景
  main_menu.gd  map.gd  battle_demo.gd
scenes/
  main_menu.tscn  map.tscn  main.tscn
assets/audio/
```

## 数据驱动

扩充内容基本只需改对应的 DB 文件：

| 想加什么 | 改哪里 |
|----------|--------|
| 卡牌 | `card_db.gd` 的 `CARDS` |
| 敌人 | `enemy_db.gd` 的 `NORMAL / ELITE / BOSS` |
| 状态 | `status_db.gd` 的 `STATUS` |
| 地图层数/节点 | `map_db.gd` |
| 事件 | `event_db.gd` |
| 平衡数值 | `run_config.gd` |

## 更新日志

- **v1.0.0**：首个可玩版本（径向地图、手牌经济、战斗、商店/事件/休息、多存档、通关结算）

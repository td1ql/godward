extends Node

# ===== 一局起始 =====
const START_HP := 100
const START_GOLD := 50
const DECK_SIZE := 20

# ===== 战斗 =====
const MAX_ENERGY := 3
# 第 1 回合的起手手牌数（之后每回合 = BASE_DRAW + 上回合剩余能量）
const FIRST_HAND := 5
const BASE_DRAW := 4
const GOLD_BATTLE := 15
const GOLD_ELITE := 40
const GOLD_BOSS := 100

# ===== 战斗奖励 =====
const REWARD_COUNT := 4
const ALLOW_SKIP := true

# ===== 休息 =====
const REST_HEAL_RATIO := 0.5

# ===== 局外成长 =====
const META_HP_PER_RUN := 5
const META_GOLD_PER_RUN := 3

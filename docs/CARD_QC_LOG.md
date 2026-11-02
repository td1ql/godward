# 卡面质检日志

标准见 `docs/CARD_QC.md`。每轮追加：卡名 / 版本 / 四关 / 结论 / 原因。

统计口径：**合格率 = 通过张数 / 214**

---

## 第 1 批 · cardart6（v7 首发）· 1-24 张

| 卡名 | Gate1 脸 | Gate2 好看 | Gate3 AI感 | Gate4 内容 | 结论 | 原因 |
|------|---------|-----------|-----------|-----------|------|------|
| 久候 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 余烬 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 光之隙 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 利滚利 | ✅ | 6/6 | ✅ | ✅ | **通过** | 表情生动 |
| 启程 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 回望 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 圣辉 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 守夜 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 尘光 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 执念 | ✅ | 4/6 | ✅ | ✅ | **通过** | — |
| 断章 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 无上耀光 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 旧伤 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 旧誓 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 晨光 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 最后一击 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 未竟 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 残响 | ✅ | 5/6 | ✅ | ✅ | **通过** | — |
| 灯 | ✅ | 4/6 | ✅ | ❌ | **打回** | 只有老妇翻纸，**没有油灯** |
| 遗志 | ✅ | 4/6 | ✅ | ❌ | **打回** | 只有持剑，**没有断剑插地 + 旗** |
| 遗忘 | ✅ | 4/6 | ✅ | ❌ | **打回** | 只是走路，**没有石碑** |
| 遗恨 | ✅ | 4/6 | ✅ | ❌ | **打回** | 只是看书，**没有半烧的信** |
| 遗言 | ✅ | 4/6 | ✅ | ❌ | **打回** | 埋头写字，**看不出盖火漆** |
| 长夜 | ✅ | 4/6 | ✅ | ❌ | **打回** | 看信，**没有黑蜡烛** |

**本轮：通过 18 / 24 = 75%；累计 18/214**

打回原因归纳：**6 张全是「关键道具没出现在手里」**（Gate4），不是脸的问题也不是 AI 感。

### 打回后的改写（下一轮重出）

```
灯   : placing a small clay oil lamp on a windowsill with both hands, an old woman in a dim cottage
遗志 : planting a broken sword into the ground beside a folded banner, a young squire on a battlefield
遗忘 : running both hands over a worn stone tablet, an old man in a dusty crypt
遗恨 : pressing a half-burned letter to his chest with one hand, a wounded soldier against a wall
遗言 : sealing a letter with red wax using a seal ring, an old scribe at a candlelit desk
长夜 : lighting a black candle stub with a taper, a woman alone in a dark bedchamber
```

### 本批确认的规律

- Gate1（脸）：**0 打回** —— 二次元脸在这版很稳
- Gate2（好看）：全部 ≥4/6 —— 水墨笔触 + 和风改为欧式之后层次够
- Gate3（AI 感）：**0 打回** —— 没有塑料质感、没有背景崩解
- Gate4（内容）：**唯一的失分点** —— 描述写了道具但模型没画出来

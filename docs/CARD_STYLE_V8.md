# 卡面 v8「墨色」风格基准

> 目标：把 214 张卡面统一成参考图（锻铁之神）那套水墨观感。
> 本文件是这套风格的唯一口径：提示词、参数、调色、质检都以这里为准。

---

## 一、参考图

- 来源：用户提供的 1773×2364 竖版图（右下角有「豆包AI生成」水印）
- 预处理：裁掉底部 8.5% 水印 → `tools/ref/v8_style_ref.png`（1024×1249）
- 纹理裁切（只取墨/衣褶，不含脸和手）：`tools/ref/v8_style_tex.png`
- 取色（k-means）：

| 色 | 占比 | 用途 |
|---|---|---|
| `#1B2B3B` | 38% | 主暗底 |
| `#213141` | 21% | 次暗底 |
| `#F2E2CA` | 12% | 皮肤 / 发 / 高光 |
| `#3A4752` | 8% | 中调 |
| `#15202C` / `#0E141D` | 11% | 最暗部 |
| `#6A6868` / `#AB9A8A` | 11% | 少量暖灰（石头、道具） |

指标：平均饱和 **0.116**，平均亮度 **0.288**，高光面积（>205）很低。

## 二、目标观感（五条）

1. **单人**，3/4 侧脸，脸和头发是画面最亮的地方；手和道具在画面中部。
2. **暗场**：背景 65–80% 是最深墨，只有淡淡的晕染/溅点，没有白色纸底、没有光晕。
3. **水墨画法**：湿墨晕开、枯笔飞白、边缘墨点、粗纸颗粒；不要硬边漫画线。
4. **低饱和双色**：墨蓝 + 奶油，允许极少量暖灰（石头、木、铜锈）；无金、无霓虹。
5. **构图**：three-quarter shot（头到大腿），头在上三分之一，适配卡面 146×82 的横窗口。

> 关于服装：参考图本身是交领长袍，IP-Adapter 会把「交领深袍」带过来。
> 这是风格的一部分，接受；但**不要**腰带结、和服纹样、木屐、武士刀。

## 三、生成配方（已标定）

| 项 | 值 |
|---|---|
| 底模 | `DreamShaperXL_Turbo_v2_1.safetensors` |
| 尺寸 | 832×480（≈16:9，卡面窗口 146×82） |
| 采样 | 20 步 · cfg 3.8 · `dpmpp_2m` · `karras` |
| 风格锚 | IP-Adapter `ip-adapter-plus_sdxl_vit-h` + `CLIP-ViT-H-14` |
| 锚参数 | weight **0.60**、`style transfer`、start 0.0 / **end 0.45** |
| 文本 | subject 与 style 分两段编码后 `ConditioningConcat`（避免 77 token 截断） |
| 调色 | `tools/grade_v8.py`（keep 0.15 / exposure 0.90 / gamma 1.12 / 对比 1.12 / 暗角 0.35 / 颗粒 2.0） |

标定对比（6 卡 × 4 方案）结论：
- **B（IP-Adapter 全图）最好**：有二次元脸 + 奶油发色 + 墨底，最接近参考图。
- A（纯提示词）：墨感好但脸偏写实、容易出兜帽。
- C（纹理裁切锚）：画法接近，但背景偏亮、更容易出和服。
- D（Animagine→DreamShaper img2img）：构图崩坏，弃用。

## 四、提示词结构

```
positive = [卡描述（自动删颜色词）] + [服装兜底] + [空墨背景池]  → 第一次 CLIP encode
         + STYLE（水墨/双色/暗场/构图/脸）                        → 第二次 CLIP encode
         → ConditioningConcat

negative = NEG（低质量/多人/亮底/光晕/和风/金/3D/漫画/文字水印/边框/剪影/无脸）
```

- 颜色词自动清洗：green / red / golden / bright…（避免和双色板打架）
- 服装兜底：描述里没有服装词时补 `wearing a tattered dark medieval robe`
- 背景池 5 种（纯墨场 / 湿墨云 / 溅点 / 纸纹 / 低墨带），按卡名 hash 轮换

### STYLE（当前正式版）

```
sumi-e ink wash painting, wet ink bloom, dry brush strokes with flying white, ink splatter,
coarse xuan paper grain, monochrome duotone, deep navy ink, warm cream highlights,
very dark low-key scene, single soft key light from upper left, strong chiaroscuro,
three-quarter shot, head to mid-thigh, head in upper third, hands and prop clearly visible,
background almost entirely darkest ink, large dark negative space, three-quarter face,
face visible, anime-influenced minimal facial features, calm restrained expression,
dark tattered medieval robe, no gold, matte finish, no text, no watermark
```

### NEG（当前正式版）

```
lowres, blurry, bad anatomy, bad hands, extra fingers, fused fingers, extra limbs,
deformed face, multiple people, crowd, group, faceless, blank face, silhouette,
cropped head, hood covering face, white halo, spotlight, glowing background, paper cutout,
bright background, white background, light paper background, bright wash, background scenery,
landscape, sky, clouds, buildings, architecture, kimono, obi, crossed collar, wide sleeves,
japanese clothing, hakama, samurai, katana, gold, brass, silver shine, glossy, specular highlight,
vivid colors, saturated, neon, rainbow, glowing magic, energy aura, 3d render, photorealistic,
photo, dslr, plastic, cel shading, thick black outline, comic, chibi, cute, text, watermark,
signature, border
```

## 五、质检口径（v8）

在 `docs/CARD_QC.md` 四关之前加一道 **Gate 0 · 色板**：

| 指标 | 合格带 | 不合格处理 |
|---|---|---|
| 平均饱和 | 0.05–0.15 | 重抽或调 keep |
| 平均亮度 | 0.22–0.38 | 重抽 |
| 高光面积（>205） | < 12% | 重抽（说明背景发白） |
| 与参考色板距离 | 见 `tools/qc_v8.py` penalty < 30 | 重抽 |

四关沿用：
- Gate 1 脸：五官不崩、不无脸、不多眼
- Gate 2 好看：剪影 / 光源 / 三个明度层 / 单一主高光 / 焦点在脸或手
- Gate 3 AI 感：背景不崩、光源不矛盾、无漂浮无意义装饰、手不崩
- Gate 4 内容：动作与卡名相关、道具在画面里、现代/和风元素不出现

## 六、已知问题与对策

| 问题 | 对策 |
|---|---|
| 道具丢失（v7 最大坑） | 描述写「双手压/握/抵住 X」；对打回卡用 `card_subjects_v8_fix.py` 覆盖 |
| 背景发白 / 白色光晕 | NEG 加 `white halo, spotlight, paper cutout, bright background`；调色压暗 |
| 交领长袍（参考图自带） | 接受；NEG 禁 obi / 腰带结 / 和服纹样 |
| 脸部过写实 | STYLE 里 `anime-influenced minimal facial features` + `face visible` |
| 画面太黑看不清 | 调色 exposure 提到 0.95、vignette 降到 0.28 |
| 214 张同质化 | 背景池 5 种 + 每卡独立 seed + 同卡 2 seed 选优 |

## 七、复现命令

```bash
# 参考图预处理（裁水印、出 texture 图、色板）
python tools/style_ref_v8.py

# 单卡试跑
python tools/gen_card_art_v8.py --stage probe --cards 打击 --recipe B --seeds 1

# 试点 24 张
python tools/gen_card_art_v8.py --stage pilot --recipe B --seeds 2
python tools/qc_v8.py pick --stage pilot

# 全量
python tools/gen_card_art_v8.py --stage full --recipe B --seeds 2
python tools/qc_v8.py report --stage full
python tools/qc_v8.py pick --stage full
```

## 八、v8 与 v7 的差别

| 项 | v7（cardart6） | v8（cardart7） |
|---|---|---|
| 风格 | 高饱和彩色水墨漫画 | 低饱和墨蓝/奶油双色 |
| 底模 | DreamShaperXL Turbo | 同（+ IP-Adapter 风格锚） |
| 尺寸 | 832×960 竖版 | 832×480 横版 |
| 构图 | 半身，背景池 10 种 | 三分身，空墨场 |
| 调色 | 双色 38% 强度 | 双色映射 + 暗角 + 颗粒 |
| 游戏图 | 832×960 PNG | 512×288 PNG |

## 九、工具链

| 工具 | 用途 |
|------|------|
| `tools/style_ref_v8.py` | 参考图裁水印、出风格图/纹理图、取色板 |
| `tools/gen_card_art_v8.py` | 主生成器（`--stage` / `--recipe` / `--seeds` / `--init` / `--width` / `--style` / `--extra-neg`） |
| `tools/gen_variants_v8.py` | 一张卡 × 多个不同动作（读 JSON） |
| `tools/grade_v8.py` | 双色映射 + 暗角 + 颗粒 |
| `tools/qc_v8.py` | 指标 + 打分 + 选优 + 落盘 512×288 |
| `tools/mock_card.py` | 按 `card_ui.gd` 常量拼 150×200 实机卡面 |
| `tools/sheet_v8.py` | 对照图 / 审阅图 |
| `tools/sketch_*.py` | 草图引导：飘带 / 包裹 / 骷髅 / 断头台 |
| `tools/fog_overlay.py` | 可控黑雾叠加（脸周围遮罩） |

**分辨率**：批量用 832×480；需要看清手/脸/小道具时用 1024×576（`--width 1024 --height 576`）。1024 下手指明显更稳。

## 十、协作方式

- **逐张审核**：一次出 6 个不同动作 → 用户挑编号 → 落盘 → 下一张。
- 用户说「再来一轮」= 同卡换 6 个动作；说「保持这个姿势/形象」= 用该图当 `--init` 再跑。
- 每 20~25 张提交一次；当前进度见 `docs/CARD_V8_PROGRESS.md`。

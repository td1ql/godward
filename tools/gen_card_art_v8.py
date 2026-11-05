# -*- coding: utf-8 -*-
"""卡面 v8「墨色」批量生成器

风格锚：tools/ref/v8_style_ref.png（参考图，裁掉水印）
统一调色：tools/grade_v8.py
输出：母版 832x480（原始 + 已调色），游戏图由 pick_best 步骤落进 cardart7

用法：
  # 标定：6 张探针卡 × 4 个方案 × 1 seed
  python tools/gen_card_art_v8.py --stage probe --recipes A,B,C,D --probes

  # 试点 24 张，每张 2 seed
  python tools/gen_card_art_v8.py --stage pilot --recipe B --seeds 2

  # 全量 214 张
  python tools/gen_card_art_v8.py --stage full --recipe B --seeds 2

  # 只看提示词，不连 ComfyUI
  python tools/gen_card_art_v8.py --stage probe --probes --dry-run
"""
import argparse
import json
import os
import re
import shutil
import sys
import time
import urllib.request
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from grade_v8 import grade, stats  # noqa: E402
from card_subjects_v4a import SUBJECTS_V4_A  # noqa: E402
from card_subjects_v4b import SUBJECTS_V4_B  # noqa: E402
from card_subjects_v4c import SUBJECTS_V4_C  # noqa: E402
from card_subjects_v4d import SUBJECTS_V4_D  # noqa: E402

try:
    from card_subjects_v8_fix import FIXES_V8  # noqa: E402
except Exception:
    FIXES_V8 = {}

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMFY_OUT = r"C:\ComfyUI\output"
COMFY_INPUT_DIR = r"C:\ComfyUI\input"
MASTER_ROOT = os.path.join(ROOT, "assets", "art", "_src_v8")
DESKTOP_ROOT = os.path.join(os.path.expanduser("~"), "Desktop", "逐神卡面v8")
GAME_DIR = os.path.join(ROOT, "assets", "art", "cardart7")

DREAM = "DreamShaperXL_Turbo_v2_1.safetensors"
ANIME = "animagine-xl-4.0.safetensors"

WIDTH, HEIGHT = 832, 480  # ≈ 卡面窗口 146x82 的 16:9

PROBES = ["打击", "淬毒", "祈祷", "铁骨", "落子", "磨刃"]

STYLE = (
    "sumi-e ink wash painting, wet ink bloom, dry brush strokes with flying white, ink splatter, "
    "coarse xuan paper grain, monochrome duotone, deep navy ink, warm cream highlights, very dark low-key scene, "
    "single soft key light from upper left, strong chiaroscuro, three-quarter shot, head to mid-thigh, "
    "head in upper third, hands and prop clearly visible, background almost entirely darkest ink, "
    "large dark negative space, three-quarter face, face visible, anime face with large expressive eyes, "
    "cel-shaded face, clean anime hair, calm expression, dark tattered medieval robe, no gold, matte finish, no text, no watermark"
)

NEG = (
    "lowres, blurry, bad anatomy, bad hands, deformed hand, missing fingers, missing thumb, four fingers, "
    "claw hand, mutated hand, extra fingers, fused fingers, extra limbs, deformed face, "
    "distorted face, asymmetric eyes, hidden face, back of head, two swords, dual wield, "
    "multiple people, crowd, group, faceless, blank face, silhouette, cropped head, hood covering face, "
    "white halo, spotlight, glowing background, paper cutout, bright background, white background, "
    "light paper background, bright wash, background scenery, landscape, sky, clouds, buildings, architecture, "
    "vase, flower vase, flowerpot, teapot, tableware, still life, shelf, flowers, blossom, petals, lotus, "
    "black tears, tears on face, dark streaks on face, ink dripping from the face, black liquid on face, "
    "smeared face paint, face markings, undead, corpse, skull, "
    "kimono, obi, crossed collar, wide sleeves, japanese clothing, hakama, samurai, katana, gold, brass, "
    "silver shine, glossy, specular highlight, vivid colors, saturated, neon, rainbow, glowing magic, "
    "energy aura, 3d render, photorealistic, photo, dslr, plastic, thick black outline, "
    "nude, naked, exposed genitals, sexual, suggestive, "
    "chibi, cute mascot, text, watermark, signature, border"
)

ANIME_STYLE = (
    "masterpiece, best quality, absurdres, anime illustration, single character, medium shot, "
    "upper body and head visible, hands in frame, three-quarter face, dark navy monochrome, "
    "deep blue shadows, warm cream highlights, single light source, simple dark background, "
    "european medieval clothing, no kimono, no japanese clothing, no text, no watermark"
)

BG_POOL = [
    "against a plain dark ink field with faint vertical wash strokes",
    "against a dark ink field with soft wet blooms and drifting mist",
    "against a dark ink field with a few ink splatters and dry brush streaks",
    "against a dark ink field with subtle paper grain and faint brush texture",
    "against a dark ink field with a low band of ink wash, no scenery",
]

COLOR_WORDS = re.compile(
    r"\b(?:green|red|blue|golden|gold|silver|crimson|emerald|amber|bronze|copper|violet|purple|"
    r"yellow|white-hot|glowing|bright|vivid|scarlet|azure|teal|orange)\b\s*",
    re.IGNORECASE,
)
CLOTHING = re.compile(
    r"\b(?:armor|armour|robe|dress|cassock|gambeson|cloak|tunic|apron|rags|ragged|mail|plate|"
    r"bracers|helmet|hood|veil|gown|coat|mantle)\b",
    re.IGNORECASE,
)


def load_subjects():
    s = {}
    for part in (SUBJECTS_V4_A, SUBJECTS_V4_B, SUBJECTS_V4_C, SUBJECTS_V4_D):
        s.update(part)
    s.update(FIXES_V8)
    return s


SUBJECTS = load_subjects()


def clean_subject(text):
    text = COLOR_WORDS.sub("", text)
    text = re.sub(r"\s*,\s*,+", ", ", text)
    text = re.sub(r"\s{2,}", " ", text).strip(" ,")
    return text


def subject_prompt_text(raw, index):
    """把任意一条英文动作描述包成 v8 的 subject 段（服装兜底 + 空墨背景池）"""
    raw = clean_subject(raw)
    extra = ""
    if not CLOTHING.search(raw):
        extra = ", wearing a tattered dark medieval robe"
    bg = BG_POOL[index % len(BG_POOL)]
    return "%s%s, %s" % (raw, extra, bg)


def subject_prompt(name, index):
    return subject_prompt_text(SUBJECTS[name], index)


def post(wf):
    body = json.dumps({"prompt": wf}).encode()
    req = urllib.request.Request(API + "/prompt", data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())["prompt_id"]


def wait(pid, timeout=900):
    t0 = time.time()
    while time.time() - t0 < timeout:
        time.sleep(1.5)
        with urllib.request.urlopen(API + "/history/" + pid, timeout=30) as r:
            h = json.loads(r.read())
        if pid in h:
            st = h[pid].get("status", {}).get("status_str", "")
            if st == "error":
                return {}
            return h[pid].get("outputs", {})
    return {}


def free_vram():
    try:
        req = urllib.request.Request(
            API + "/free",
            data=json.dumps({"unload_models": True, "free_memory": True}).encode(),
            headers={"Content-Type": "application/json"},
        )
        urllib.request.urlopen(req, timeout=30).read()
        print("已请求 ComfyUI 释放显存", flush=True)
    except Exception as e:
        print("free 失败（忽略）:", e, flush=True)


def ipadapter_nodes(image_name, weight, weight_type, end_at=0.85):
    return {
        "20": {"class_type": "CLIPVisionLoader",
               "inputs": {"clip_name": "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"}},
        "21": {"class_type": "IPAdapterModelLoader",
               "inputs": {"ipadapter_file": "ip-adapter-plus_sdxl_vit-h.safetensors"}},
        "22": {"class_type": "LoadImage", "inputs": {"image": image_name}},
        "23": {"class_type": "IPAdapterAdvanced", "inputs": {
            "model": ["4", 0], "ipadapter": ["21", 0], "image": ["22", 0],
            "clip_vision": ["20", 0], "weight": weight, "weight_type": weight_type,
            "combine_embeds": "concat", "start_at": 0.0, "end_at": end_at,
            "embeds_scaling": "V only"}},
    }


def build(recipe, name, seed, ip_weight=None, ip_end=0.45, init_image=None, denoise=0.45,
          subject_override=None):
    if subject_override:
        sp = subject_prompt_text(subject_override, abs(zlib.crc32(subject_override.encode())) % 97)
    else:
        sp = subject_prompt(name, abs(zlib.crc32(name.encode())) % 97)
    base = {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": DREAM}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": WIDTH, "height": HEIGHT, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"text": sp, "clip": ["4", 1]}},
        "14": {"class_type": "CLIPTextEncode", "inputs": {"text": STYLE, "clip": ["4", 1]}},
        "15": {"class_type": "ConditioningConcat",
               "inputs": {"conditioning_to": ["6", 0], "conditioning_from": ["14", 0]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
    }
    latent = ["5", 0]
    if init_image:
        # 以已有图为底做 img2img：保住姿势，只换细节
        base.update({
            "40": {"class_type": "LoadImage", "inputs": {"image": init_image}},
            "41": {"class_type": "ImageScale", "inputs": {
                "image": ["40", 0], "upscale_method": "lanczos",
                "width": WIDTH, "height": HEIGHT, "crop": "center"}},
            "42": {"class_type": "VAEEncode", "inputs": {"pixels": ["41", 0], "vae": ["4", 2]}},
        })
        latent = ["42", 0]
    pos = ["15", 0]
    model = ["4", 0]
    if recipe in ("B", "C"):
        if recipe == "B":
            base.update(ipadapter_nodes("v8_style_ref.png", ip_weight or 0.60, "style transfer", ip_end))
        else:
            base.update(ipadapter_nodes("v8_style_tex.png", ip_weight or 0.70, "style transfer precise", ip_end))
        model = ["23", 0]

    if recipe in ("A", "B", "C"):
        base.update({
            "3": {"class_type": "KSampler", "inputs": {
                "seed": seed, "steps": 20, "cfg": 3.8,
                "sampler_name": "dpmpp_2m", "scheduler": "karras",
                "denoise": denoise if init_image else 1.0,
                "model": model, "positive": pos, "negative": ["7", 0],
                "latent_image": latent}},
            "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
            "9": {"class_type": "SaveImage",
                  "inputs": {"filename_prefix": "c8%s_" % recipe, "images": ["8", 0]}},
        })
        return base

    # D：Animagine 出构图 → DreamShaper img2img 补水墨
    sp_anime = "%s, %s" % (clean_subject(SUBJECTS[name]), ANIME_STYLE)
    base.update({
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": ANIME}},
        "30": {"class_type": "CLIPTextEncode", "inputs": {"text": sp_anime, "clip": ["1", 1]}},
        "31": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "32": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 26, "cfg": 6.0,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["1", 0], "positive": ["30", 0], "negative": ["31", 0],
            "latent_image": ["5", 0]}},
        "33": {"class_type": "VAEDecode", "inputs": {"samples": ["32", 0], "vae": ["1", 2]}},
        "34": {"class_type": "VAEEncode", "inputs": {"pixels": ["33", 0], "vae": ["1", 2]}},
        "35": {"class_type": "KSampler", "inputs": {
            "seed": seed + 1, "steps": 20, "cfg": 3.8,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.45,
            "model": ["4", 0], "positive": pos, "negative": ["7", 0],
            "latent_image": ["34", 0]}},
        "36": {"class_type": "VAEDecode", "inputs": {"samples": ["35", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": "c8D_", "images": ["36", 0]}},
    })
    return base


def seed_of(name, recipe, idx):
    return zlib.crc32(("v8|%s|%s|%d" % (recipe, name, idx)).encode()) % 900000 + 1000


def already(raw_path):
    return os.path.exists(raw_path) and os.path.getsize(raw_path) > 1000


def main():
    global STYLE, NEG, WIDTH, HEIGHT
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", default="probe", help="输出子目录名：probe / pilot / full / 任意实验名")
    ap.add_argument("--recipe", default="B", help="A/B/C/D，可逗号分隔；probe 常用 A,B,C,D")
    ap.add_argument("--recipes", default="", help="同 --recipe，可逗号分隔")
    ap.add_argument("--cards", default="", help="逗号分隔卡名；默认探针/试点/全量")
    ap.add_argument("--probes", action="store_true")
    ap.add_argument("--seeds", type=int, default=1)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--ip-weight", type=float, default=0.0)
    ap.add_argument("--ip-end", type=float, default=0.45)
    ap.add_argument("--init", default="", help="img2img 底图（ComfyUI input 里的文件名或绝对路径）")
    ap.add_argument("--denoise", type=float, default=0.45)
    ap.add_argument("--width", type=int, default=0)
    ap.add_argument("--height", type=int, default=0)
    ap.add_argument("--extra-pos", default="")
    ap.add_argument("--style-prefix", default="")
    ap.add_argument("--style", default="", help="整段替换 STYLE（大远景等特殊构图用）")
    ap.add_argument("--extra-neg", default="")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--no-free", action="store_true")
    ap.add_argument("--force", action="store_true", help="已存在也重出")
    args = ap.parse_args()

    if args.style:
        STYLE = args.style
    if args.style_prefix:
        STYLE = args.style_prefix.rstrip(" ,") + ", " + STYLE
    if args.width and args.height:
        WIDTH, HEIGHT = args.width, args.height
    if args.extra_pos:
        STYLE = STYLE + ", " + args.extra_pos
    if args.extra_neg:
        NEG = args.extra_neg.rstrip(" ,") + ", " + NEG
    ip_weight = args.ip_weight or None
    init_name = ""
    if args.init:
        if os.path.isabs(args.init):
            os.makedirs(COMFY_INPUT_DIR, exist_ok=True)
            init_name = os.path.basename(args.init)
            shutil.copy2(args.init, os.path.join(COMFY_INPUT_DIR, init_name))
        else:
            init_name = args.init

    recipes = [r.strip() for r in (args.recipes or args.recipe).split(",") if r.strip()]
    for r in recipes:
        if r not in ("A", "B", "C", "D"):
            raise SystemExit("未知方案: %s" % r)

    if args.cards:
        names = [n.strip() for n in args.cards.split(",") if n.strip()]
    elif args.stage == "probe" or args.probes:
        names = PROBES
    elif args.stage == "pilot":
        names = PILOT_CARDS
    else:
        names = list(SUBJECTS.keys())

    unknown = [n for n in names if n not in SUBJECTS]
    if unknown:
        raise SystemExit("没有这些卡的描述: %s" % unknown)

    jobs = []
    for recipe in recipes:
        for name in names:
            for i in range(args.seeds):
                jobs.append((recipe, name, i))

    print("阶段 %s · %d 张卡 · 方案 %s · 每卡 %d seed → %d 个任务"
          % (args.stage, len(names), "".join(recipes), args.seeds, len(jobs)), flush=True)

    todo = []
    for recipe, name, i in jobs:
        raw = os.path.join(MASTER_ROOT, args.stage, name, "%s_s%d_raw.png" % (recipe, i))
        if args.force or not already(raw):
            todo.append((recipe, name, i, raw))
    print("待生成 %d 个（跳过已完成 %d）" % (len(todo), len(jobs) - len(todo)), flush=True)

    if args.dry_run:
        for recipe, name, i, raw in todo[:4]:
            print("\n--- %s %s seed%d ---" % (recipe, name, i))
            print("positive-subject:", subject_prompt(name, i)[:400])
            print("positive-style  :", STYLE[:200], "...")
            print("negative        :", NEG[:160], "...")
        return

    if not args.no_free:
        free_vram()

    manifest = os.path.join(MASTER_ROOT, args.stage, "manifest.jsonl")
    os.makedirs(os.path.dirname(manifest), exist_ok=True)
    t0 = time.time()
    ok = fail = 0
    for k, (recipe, name, i, raw) in enumerate(todo, 1):
        el = time.time() - t0
        eta = (el / max(k, 1)) * (len(todo) - k)
        print("[%d/%d] %s %s s%d  已用 %d 分 剩余约 %d 分"
              % (k, len(todo), recipe, name, i, el / 60, eta / 60), flush=True)
        seed = seed_of(name, recipe, i)
        try:
            pid = post(build(recipe, name, seed, ip_weight, args.ip_end, init_name or None, args.denoise))
            outs = wait(pid)
            imgs = outs.get("9", {}).get("images", [])
            if not imgs:
                print("   FAIL：没有输出", flush=True)
                fail += 1
                continue
            src = os.path.join(COMFY_OUT, imgs[0]["filename"])
            for _ in range(40):
                if os.path.exists(src) and os.path.getsize(src) > 1000:
                    break
                time.sleep(0.5)
            from PIL import Image
            im = Image.open(src).convert("RGB")
            os.makedirs(os.path.dirname(raw), exist_ok=True)
            im.save(raw)
            graded = grade(im)
            gpath = raw.replace("_raw.png", "_g.png")
            graded.save(gpath)
            ok += 1
            with open(manifest, "a", encoding="utf-8") as f:
                f.write(json.dumps({
                    "card": name, "recipe": recipe, "seed": seed, "seed_idx": i,
                    "raw": os.path.relpath(raw, ROOT), "graded": os.path.relpath(gpath, ROOT),
                    "stats": stats(graded),
                }, ensure_ascii=False) + "\n")
        except Exception as e:
            print("   ERR:", e, flush=True)
            fail += 1
    print("完成：成功 %d / 失败 %d，用时 %.1f 分" % (ok, fail, (time.time() - t0) / 60), flush=True)


# 试点 24 张：每流派 3 张，其中至少 1 张是 v7 打回过的卡
PILOT_CARDS = [
    # 毒
    "淬毒", "毒刃", "剧毒",
    # 力
    "以血换力", "铁骨", "苦修",
    # 守
    "重甲", "死守", "盾墙",
    # 抽
    "启程", "灯", "浮木",
    # 斩
    "打击", "斩首", "破防斩",
    # 血
    "血祭", "余烬", "渴血",
    # 技
    "预兆", "落子", "剑息",
    # 愈
    "再生术", "祈祷", "急救术",
]

if __name__ == "__main__":
    main()

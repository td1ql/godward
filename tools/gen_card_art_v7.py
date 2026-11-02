# -*- coding: utf-8 -*-
"""卡面 v3 批量生成：人物 + 动作 + 场景"""
import json, os, re, shutil, sys, time, urllib.request, zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from grade import grade
from card_subjects_v4a import SUBJECTS_V4_A
from card_subjects_v4b import SUBJECTS_V4_B
from card_subjects_v4c import SUBJECTS_V4_C
from card_subjects_v4d import SUBJECTS_V4_D

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "cardart6")
DESKTOP = os.path.join(os.path.expanduser("~"), "Desktop", "逐神卡面v7")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "DreamShaperXL_Turbo_v2_1.safetensors"

STYLE = (
    "ink wash illustration, sumi-e brush texture, bold expressive brushwork, "
    "strong value contrast, vivid saturated color accents, high chroma, "
    "emerald green, deep crimson, cobalt blue, burnt orange, bright gold on off-white paper, "
    "elegant elongated figure, clear silhouette, flowing heavy cloth, "
    "atmospheric brush flourishes and drifting shadow shapes behind the figure, "
    "european medieval fantasy illustration, anime-influenced face, cel-shaded face, large expressive eyes, clean line art, "
    "medieval dark fantasy, modest clothing, medium shot, hands in frame, "
    "no text, no watermark, no border"
)
NEG = (
    "lowres, bad anatomy, bad hands, extra limbs, extra fingers, "
    "text, watermark, signature, frame, border, "
    "photograph, photorealistic, dslr, skin pores, 3d render, cgi, "
    "realistic face, photorealistic face, mature face, "
    "bright, overexposed, neon, nude, naked, shirtless, cleavage, "
    "spaceship, cannon, firearm, gun, rifle, machine, technology, robot, "
    "sci-fi, futuristic, modern building, city street, car"
)

SUBJECTS = {}
SUBJECTS.update(SUBJECTS_V4_A)
SUBJECTS.update(SUBJECTS_V4_B)
SUBJECTS.update(SUBJECTS_V4_C)
SUBJECTS.update(SUBJECTS_V4_D)
# 去掉 hooded / cloaked / robed —— 这三个词会让 SDXL 把人画成兜帽黑影
SUBJECTS = {k: re.sub(r"\\b(hooded|cloaked|robed)\\s+", "", v) for k, v in SUBJECTS.items()}
try:
    from card_subjects_v4_fix import FIXES as F4
    SUBJECTS.update(F4)
    print("v4 修正表 %d 条" % len(F4))
except Exception as _e:
    print("无 v4 修正表")
print("使用 v4 描述表 %d 条" % len(SUBJECTS))


# 背景池：按卡序号轮换，避免 214 张全是同一堵墙
BG_POOL = [
    "in a dim candlelit room",
    "in a torch-lit stone corridor",
    "on a foggy forest road",
    "inside a ruined chapel",
    "on a muddy battlefield",
    "in a bare stone cell",
    "in a snowy mountain pass",
    "in a crowded tavern corner",
    "by a river at dusk",
    "in a collapsed cloister garden",
]


# 按描述里的关键词给服装，避免 214 张全是同一件深绿长袍
GARMENTS = [
    (("knight", "paladin", "guard", "soldier", "sentry", "watchman", "shield"), "wearing steel plate armor and a tabard"),
    (("nun", "priest", "bishop", "monk", "preacher", "acolyte", "cleric"), "wearing a rough wool cassock"),
    (("assassin", "rogue", "spy", "thief", "poisoner"), "wearing a dark leather harness and hood"),
    (("smith", "woodcutter", "mason", "sapper", "gravedigger"), "wearing a leather apron over a linen shirt"),
    (("scholar", "scribe", "librarian", "astronomer", "clerk", "student", "poet"), "wearing a scholar's long coat and collar"),
    (("peasant", "widow", "beggar", "child", "woman", "girl", "mourner"), "wearing a plain wool dress with an apron"),
    (("warrior", "fighter", "berserker", "duelist", "swordsman", "spearman", "archer"), "wearing a padded gambeson and leather bracers"),
    (("king", "warlord", "commander", "general", "judge"), "wearing a fur-lined cloak over a heavy coat"),
    (("mage", "alchemist", "prophet", "diviner"), "wearing a layered robe with a wide belt"),
]


def clothed(subject):
    low = subject.lower()
    for keys, wear in GARMENTS:
        if any(k in low for k in keys):
            return subject + ", " + wear
    return subject + ", wearing plain linen clothes"


def styled(subject, index):
    bg = BG_POOL[index % len(BG_POOL)]
    return "%s, %s, %s" % (clothed(subject), bg, STYLE)


def post(wf):
    body = json.dumps({"prompt": wf}).encode()
    req = urllib.request.Request(API + "/prompt", data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())["prompt_id"]


def wait(pid, timeout=600):
    t0 = time.time()
    while time.time() - t0 < timeout:
        time.sleep(2)
        with urllib.request.urlopen(API + "/history/" + pid, timeout=30) as r:
            h = json.loads(r.read())
        if pid in h:
            return h[pid]["outputs"]
    return {}


def build(prompt, seed):
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 832, "height": 960, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": prompt, "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 16, "cfg": 3.0,
            "sampler_name": "dpmpp_sde", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "card6_", "images": ["8", 0]}},
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(DESKTOP, exist_ok=True)
    names = list(SUBJECTS.keys())
    todo = [n for n in names if not os.path.exists(os.path.join(OUT, n + ".png"))]
    print("共 %d 张，待生成 %d 张" % (len(names), len(todo)), flush=True)
    t0 = time.time()
    for i, name in enumerate(todo, 1):
        el = time.time() - t0
        eta = (el / i * (len(todo) - i)) if i > 1 else 0
        print("[%d/%d] %-8s 已用 %ds 剩余约 %ds" % (i, len(todo), name, int(el), int(eta)), flush=True)
        pid = post(build(styled(SUBJECTS[name], i), zlib.crc32(("c4" + name).encode()) % 900000 + 1000))
        outs = wait(pid)
        imgs = outs.get("9", {}).get("images", [])
        if not imgs:
            print("  FAIL", name, flush=True)
            continue
        src = os.path.join(COMFY_OUT, imgs[0]["filename"])
        for _ in range(30):
            if os.path.exists(src):
                break
            time.sleep(0.5)
        dst = os.path.join(OUT, name + ".png")
        try:
            from PIL import Image as _I
            from grade import grade as _g
            _g(_I.open(src)).save(dst)
        except Exception as _e:
            print('  调色失败，直接复制:', _e, flush=True)
            shutil.copy2(src, dst)
        try:
            shutil.copy2(dst, os.path.join(DESKTOP, name + ".png"))
        except Exception:
            pass
    print("完成", flush=True)


main()

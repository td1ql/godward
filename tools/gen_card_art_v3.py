# -*- coding: utf-8 -*-
"""卡面 v3 批量生成：人物 + 动作 + 场景"""
import json, os, re, shutil, sys, time, urllib.request, zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from card_subjects_v4a import SUBJECTS_V4_A
from card_subjects_v4b import SUBJECTS_V4_B
from card_subjects_v4c import SUBJECTS_V4_C
from card_subjects_v4d import SUBJECTS_V4_D

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "cardart3c")
DESKTOP = os.path.join(os.path.expanduser("~"), "Desktop", "逐神卡面v3c")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

STYLE = (
    "masterpiece, best quality, absurdres, "
    "medieval dark fantasy illustration, single character, "
    "medium shot, full upper body and head visible, hands in frame, "
    "face visible in three-quarter view, centered composition, "
    "detailed clothing, layered fabric, dirt and wear, "
    "visible face, face clearly lit from the side, warm light on the face, "
    "semi-realistic painterly concept art, matte surfaces, "
    "desaturated muted colors, deep teal shadows, soft directional light, "
    
    "clear readable silhouette, no text, no watermark, no frame"
)
NEG = (
    "lowres, text, watermark, signature, frame, border, "
    "spaceship, cannon, firearm, gun, rifle, machine, technology, robot, "
    "sci-fi, futuristic, neon, glowing outline, rim light on figure, "
    "modern building, city street, car, "
    "extra limbs, extra fingers, bad hands, bad anatomy, deformed face, "
    "multiple people, crowd, cute, cartoon, chibi, 3d render, photorealistic, "
    "faceless, blank face, featureless, dark silhouette, backlit silhouette"
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


def styled(subject, index):
    bg = BG_POOL[index % len(BG_POOL)]
    return "%s, %s, %s" % (subject, bg, STYLE)


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
              "inputs": {"width": 832, "height": 704, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": prompt, "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 30, "cfg": 7.0,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "card3c_", "images": ["8", 0]}},
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
        pid = post(build(styled(SUBJECTS[name], i), zlib.crc32(("c3c" + name).encode()) % 900000 + 1000))
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
        shutil.copy2(src, dst)
        try:
            shutil.copy2(dst, os.path.join(DESKTOP, name + ".png"))
        except Exception:
            pass
    print("完成", flush=True)


main()

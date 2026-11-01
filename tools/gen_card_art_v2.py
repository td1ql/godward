# -*- coding: utf-8 -*-
"""卡面批量生成 v2 —— 写法 1（具体物件）+ 与敌人立绘统一的哑光油画风

每张卡的画面主体来自 tools/card_subjects.py（214 条手写）
风格：still life / plain white background / painterly / matte / desaturated
输出：assets/art/cardart2/，同时同步到 桌面\\逐神卡面v2\\
"""
import json, os, shutil, sys, time, urllib.request, zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from card_subjects import SUBJECTS

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "cardart2")
DESKTOP = os.path.join(os.path.expanduser("~"), "Desktop", "逐神卡面v2")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

STYLE = (
    "masterpiece, best quality, absurdres, "
    "still life, single object, front view, centered, "
    "plain white background, simple background, no environment, "
    "semi-realistic dark fantasy concept art, painterly brush strokes, "
    "matte surfaces, weathered texture, "
    "desaturated muted colors, deep teal shadows, faint warm amber rim light, "
    "clear readable silhouette, no text, no watermark, no frame"
)
NEG = (
    "lowres, blurry, text, watermark, signature, frame, border, "
    "multiple objects, crowd, scenery, landscape, background elements, "
    "abstract, glowing magic circle, rune, ornate decoration, filigree, "
    "gemstone, sparkle, lens flare, bloom, neon, colorful, "
    "cute, cartoon, chibi, 3d render, photorealistic, "
    "people, person, character, human body, portrait, cute girl"
)


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


def build(prompt, seed, name):
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": "%s, %s" % (prompt, STYLE), "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 28, "cfg": 6.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "card2_%s" % "x", "images": ["8", 0]}},
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
        print("[%d/%d] %-8s  已用 %ds  剩余约 %ds" % (i, len(todo), name, int(el), int(eta)), flush=True)
        subj = SUBJECTS[name]
        # 提示词里不能出现卡名（会让 SDXL 画中文字），只用物件描述
        seed = zlib.crc32(("c2" + name).encode()) % 900000 + 1000
        pid = post(build(subj, seed, name))
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

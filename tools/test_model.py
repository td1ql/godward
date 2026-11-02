# -*- coding: utf-8 -*-
"""底模对照测试：同一张卡的描述，用 animagine 和 Juggernaut 各出 1 张

Juggernaut 是写实向模型，不吃动漫那套词（absurdres/masterpiece），
改用 cinematic / volumetric light / detailed skin 这类摄影/绘画词。
"""
import json, os, shutil, sys, time, urllib.request, zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from card_subjects_v4a import SUBJECTS_V4_A
from card_subjects_v4b import SUBJECTS_V4_B
from card_subjects_v4c import SUBJECTS_V4_C
from card_subjects_v4d import SUBJECTS_V4_D
try:
    from card_subjects_v4_fix import FIXES
except Exception:
    FIXES = {}

SUBJECTS = {}
for _p in (SUBJECTS_V4_A, SUBJECTS_V4_B, SUBJECTS_V4_C, SUBJECTS_V4_D):
    SUBJECTS.update(_p)
SUBJECTS.update(FIXES)

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "model_test")
COMFY_OUT = r"C:\ComfyUI\output"

ANIMAGINE = "animagine-xl-4.0.safetensors"
JUGG = "Juggernaut-XL_v9.safetensors"

# animagine 用原来的动漫向词
STYLE_ANIME = (
    "masterpiece, best quality, absurdres, "
    "medieval dark fantasy illustration, single character, "
    "medium shot, full upper body and head visible, hands in frame, "
    "face visible in three-quarter view, centered composition, "
    "detailed clothing, layered fabric, dirt and wear, "
    "semi-realistic painterly concept art, matte surfaces, "
    "desaturated muted colors, warm light from the side, clear light and shadow, "
    "clear readable silhouette, no text, no watermark, no frame"
)
# juggernaut 用写实/电影向词
STYLE_JUGG = (
    "cinematic portrait, medieval dark fantasy, one person, "
    "waist-up composition, sharp focus on face and hands, "
    "detailed skin texture, realistic fabric folds, worn leather and wool, "
    "soft volumetric light from the side, deep shadows, warm amber rim light, "
    "muted earthy palette, film grain, shallow depth of field, "
    "photorealistic painterly, 85mm lens, high detail, "
    "no text, no watermark, no border"
)
NEG_ANIME = (
    "lowres, text, watermark, signature, frame, border, "
    "spaceship, cannon, firearm, gun, machine, robot, sci-fi, futuristic, neon, "
    "modern building, car, extra limbs, extra fingers, bad hands, bad anatomy, "
    "deformed face, multiple people, crowd, cute, cartoon, chibi, 3d render, "
    "abstract shapes, geometric poster, blank silhouette, faceless, blank face"
)
NEG_JUGG = (
    "lowres, blurry, text, watermark, signature, frame, border, "
    "cartoon, anime, chibi, illustration, drawing, sketch, "
    "spaceship, cannon, firearm, gun, machine, robot, sci-fi, futuristic, neon, "
    "modern building, car, extra limbs, extra fingers, bad hands, bad anatomy, "
    "deformed face, multiple people, crowd, "
    "abstract, geometric"
)

TESTS = ["沉默的执剑人" if False else "打击", "磨刃", "祈祷"]


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


def build(ckpt, prompt, style, neg, seed):
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": ckpt}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 832, "height": 704, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": "%s, %s" % (prompt, style), "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 32, "cfg": 5.5 if ckpt == JUGG else 7.0,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "mt_", "images": ["8", 0]}},
    }


def gen(tag, ckpt, prompt, style, neg, seed):
    pid = post(build(ckpt, prompt, style, neg, seed))
    outs = wait(pid)
    imgs = outs.get("9", {}).get("images", [])
    if not imgs:
        print("  FAIL", tag, flush=True)
        return
    src = os.path.join(COMFY_OUT, imgs[0]["filename"])
    for _ in range(30):
        if os.path.exists(src):
            break
        time.sleep(0.5)
    shutil.copy2(src, os.path.join(OUT, tag + ".png"))
    print("  OK", tag, flush=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in TESTS:
        subj = SUBJECTS.get(name)
        if not subj:
            print("跳过", name)
            continue
        seed = zlib.crc32(("mt" + name).encode()) % 900000 + 1000
        print("[%s] animagine" % name, flush=True)
        gen("%s_animagine" % name, ANIMAGINE, subj, STYLE_ANIME, NEG_ANIME, seed)
        print("[%s] juggernaut" % name, flush=True)
        gen("%s_juggernaut" % name, JUGG, subj, STYLE_JUGG, NEG_JUGG, seed)
    print("完成", flush=True)


main()

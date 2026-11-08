# -*- coding: utf-8 -*-
"""对白底抠不干净的那几张：改用「深色底」重生成，再按亮度从边框抠

深色底的优点：角色是亮的、背景是暗的，两者亮度差极大，flood fill 一次干净。
"""
import json, os, re, shutil, sys, time, urllib.request, zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "assets", "art", "enemy_dark")
OUT = os.path.join(ROOT, "assets", "art", "enemy_cut")
COMFY = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

TARGETS = ["headless_knight", "judge", "flame_elem", "world_tree",
           "elite_mage", "elite_guard", "blind_seer", "thorn_idol"]

# 复用的造型描述（与 gen_enemy_art.py 保持一致）
DESC = {
    "headless_knight": "a headless knight in dark plate armor, holding a huge notched greatsword point down",
    "judge": "a tall judge in black robes, holding a long thin blade, hooded, faceless",
    "flame_elem": "a burning humanoid of flame and smoke, arms raised",
    "world_tree": "a colossal dead world tree, thick pale trunk with a dark hollow doorway, bare twisted branches",
    "elite_mage": "a gaunt mage in layered dark robes, holding a staff, hooded",
    "elite_guard": "an elite guard in ornate dark plate, holding a tall kite shield",
    "blind_seer": "a blind seer with bandaged eyes, leaning on a tall staff",
    "thorn_idol": "an idol made of twisted black thorns, humanoid shape",
}

STYLE = (
    "masterpiece, high score, great score, absurdres, "
    "full body character illustration, single character, "
    "plain near-black background, simple background, no environment, "
    "semi-realistic dark fantasy concept art, painterly brush strokes, "
    "detailed shading, matte surfaces, weathered texture, "
    "deep teal shadows, faint warm amber rim light, "
    "standing pose, centered, no text, no watermark, no frame, "
    "faceless, face hidden in shadow, no visible facial features"
)
NEG = (
    "lowres, bad anatomy, bad hands, extra limbs, extra fingers, fewer digits, "
    "text, watermark, signature, frame, border, multiple characters, crowd, "
    "scenery, landscape, background elements, "
    "shiny, glossy, polished metal, specular highlight, lens flare, bloom, "
    "bright, overexposed, neon, colorful, cute, chibi, cartoon, "
    "3d render, photorealistic, cropped head, "
    "detailed face, eyes, nose, lips, teeth, smile, expression, portrait, "
    "female, woman, girl, nude, naked, "
    "white background, bright background"
)


def post(wf):
    body = json.dumps({"prompt": wf}).encode()
    req = urllib.request.Request(API + "/prompt", data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())["prompt_id"]


def wait(pid, timeout=900):
    t0 = time.time()
    while time.time() - t0 < timeout:
        time.sleep(2)
        with urllib.request.urlopen(API + "/history/" + pid, timeout=30) as r:
            h = json.loads(r.read())
        if pid in h:
            return h[pid]["outputs"]
    return {}


def build(prompt, seed, key):
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1024, "height": 1152, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": "%s, %s" % (prompt, STYLE), "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": zlib.crc32(("dark" + key).encode()) % 900000 + 1000,
            "steps": 32, "cfg": 6.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "dark_%s" % key, "images": ["8", 0]}},
    }


def main():
    os.makedirs(RAW, exist_ok=True)
    for i, key in enumerate(TARGETS, 1):
        dst = os.path.join(RAW, key + ".png")
        if os.path.exists(dst) and os.path.getsize(dst) > 30000:
            print("[%d/%d] %s 已存在，跳过" % (i, len(TARGETS), key), flush=True)
            continue
        print("[%d/%d] %s" % (i, len(TARGETS), key), flush=True)
        pid = post(build(DESC[key], 0, key))
        outs = wait(pid)
        imgs = outs.get("9", {}).get("images", [])
        if not imgs:
            print("  FAIL", key, flush=True)
            continue
        src = os.path.join(COMFY, imgs[0]["filename"])
        for _ in range(30):
            if os.path.exists(src):
                break
            time.sleep(0.5)
        shutil.copy2(src, dst)
        print("  OK", key, flush=True)
    print("完成", flush=True)


main()

# -*- coding: utf-8 -*-
"""卡面风格试验：同一张卡用不同的「直观度」写法，对比哪种最容易认出来"""
import json, os, shutil, time, urllib.request, zlib

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "cardstyle")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

# 和敌人立绘同一套风格（哑光 / 低饱和 / 油彩笔触），但改成「静物 + 纯色底」
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
    "people, person, character, face, hands"
)

TESTS = [
    ("A_防御_1", "a heavy iron round shield standing upright, dented rim, leather straps behind"),
    ("A_防御_2", "one single round shield seen from the front, plain iron surface, one old crack"),
    ("B_打击_1", "one straight double-edged sword blade standing point-down in the ground"),
    ("B_打击_2", "a single long steel blade lying horizontally, plain and clean"),
    ("C_磨刃_1", "a flat grey whetstone with one short blade resting on it"),
    ("C_磨刃_2", "a sharpening stone and a knife side by side on a plain surface"),
    ("D_静养_1", "a folded grey cloth and a shallow bowl of water side by side"),
    ("D_静养_2", "a small wooden bowl of clear water with a folded cloth beside it"),
    ("E_毒刃_1", "a short dagger with a dark green stained blade, a small vial beside it"),
    ("E_毒刃_2", "one dagger coated with green venom, drops falling from the tip"),
    ("F_斩首_1", "a single heavy executioner axe, wide blade, plain handle"),
    ("F_斩首_2", "one large axe head resting on a plain surface, cutting edge facing viewer"),
]


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
              "inputs": {"filename_prefix": "cstyle_%s" % "x", "images": ["8", 0]}},
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    for i, (name, prompt) in enumerate(TESTS, 1):
        dst = os.path.join(OUT, name + ".png")
        if os.path.exists(dst):
            continue
        print("[%d/%d] %s" % (i, len(TESTS), name), flush=True)
        pid = post(build(prompt, zlib.crc32(name.encode()) % 900000 + 1000))
        outs = wait(pid)
        imgs = outs.get("9", {}).get("images", [])
        if not imgs:
            print("  FAIL", name)
            continue
        src = os.path.join(COMFY_OUT, imgs[0]["filename"])
        for _ in range(30):
            if os.path.exists(src):
                break
            time.sleep(0.5)
        shutil.copy2(src, dst)
        print("  OK", name, flush=True)
    print("完成")


main()

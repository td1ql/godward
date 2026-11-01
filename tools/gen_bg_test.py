# -*- coding: utf-8 -*-
"""背景图样张：地图背景 + 战斗背景（SDXL）

用法：python tools/gen_bg_test.py
输出：assets/art/bgtest/
"""
import json, os, time, urllib.request, shutil

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "bgtest")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

NEG = (
    "people, person, character, human, face, text, watermark, signature, "
    "frame, border, low quality, blurry, oversaturated, neon, "
    "cartoon, chibi, 3d render, photorealistic, cluttered"
)

BASE = (
    "masterpiece, high score, absurdres, no humans, "
    "landscape background, wide shot, scenery, atmospheric, "
    "semi-realistic dark fantasy concept art, dramatic lighting, "
    "cool teal shadows with warm amber light, rich muted colors, "
    "mist, depth of field, no text, no watermark, no frame"
)

TESTS = [
    # ── 地图背景：俯视墨线地图 ──
    ("map_1", "top down aerial view of an ancient painted map, ink wash mountains and rivers, "
              "winding roads, tiny ruined towers, parchment texture but dark teal, "
              "faint gold contour lines, aged cartography, no text"),
    ("map_2", "aerial view of a withered fantasy land seen from high above, "
              "dark ink wash terrain, glowing rivers, gold route lines scratched over it, "
              "ancient map aesthetic, muted teal and dust, no text"),

    # ── 战斗背景：废墟 / 神国 ──
    ("battle_1", "a broken stone bridge over a bottomless chasm, dark sky, "
                 "dramatic backlight through the gap, dust and embers, "
                 "wide symmetrical composition, empty center for combat"),
    ("battle_2", "the interior of a ruined cathedral, shattered stained glass, "
                 "shafts of pale light through holes in the roof, rubble and ash, "
                 "wide symmetrical composition, empty center for combat"),
    ("battle_3", "a battlefield under an enormous dead world tree, roots cracking the ground, "
                 "dark clouds, distant golden light on the horizon, "
                 "wide symmetrical composition, empty center for combat"),
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
              "inputs": {"width": 1536, "height": 864, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": "%s, %s" % (prompt, BASE), "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 30, "cfg": 6.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "bgtest", "images": ["8", 0]}},
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    for i, (name, prompt) in enumerate(TESTS, 1):
        dst = os.path.join(OUT, name + ".png")
        if os.path.exists(dst):
            print("跳过", name)
            continue
        print("[%d/%d] %s" % (i, len(TESTS), name), flush=True)
        pid = post(build(prompt, 1000 + i * 77))
        outs = wait(pid)
        imgs = outs.get("9", {}).get("images", [])
        if not imgs:
            print("  ❌", name)
            continue
        src = os.path.join(COMFY_OUT, imgs[0]["filename"])
        for _ in range(30):
            if os.path.exists(src):
                break
            time.sleep(0.5)
        shutil.copy2(src, dst)
        print("  ✅", dst)
    print("完成")


main()

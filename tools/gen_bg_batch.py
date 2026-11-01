# -*- coding: utf-8 -*-
"""补齐所有战斗背景 + 三幕地图背景

战斗背景要求（已定稿）：
  · 强纵深：消失点、地面向远处延伸
  · 下方 1/3 是**可站立的地面**（敌人在 y≈560 站立）
  · 中央留空、不要人物

地图背景要求：
  · 俯视 / 高视角的「手绘古地图」，有路线、山脊、河流
  · 冷色墨洗感，不要太花
"""
import json, os, shutil, time, urllib.request, zlib

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_B = os.path.join(ROOT, "assets", "art", "bg_battle")
OUT_M = os.path.join(ROOT, "assets", "art", "bg_map_new")
DESK_B = os.path.join(os.path.expanduser("~"), "Desktop", "逐神背景")
DESK_M = os.path.join(os.path.expanduser("~"), "Desktop", "逐神地图背景")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

BATTLE_STYLE = (
    "masterpiece, best quality, absurdres, "
    "wide landscape background, no humans, scenery, "
    "strong perspective, vanishing point, deep depth of field, "
    "wide empty ground plane in the lower third, receding into distance, "
    "foreground floor clearly visible, "
    "semi-realistic dark fantasy concept art, painterly, "
    "desaturated muted colors, deep teal shadows, warm amber light source, "
    "dramatic atmospheric haze, layers of distance, "
    "empty center for combat, no text, no watermark, no frame"
)
BATTLE_NEG = (
    "lowres, bad anatomy, text, watermark, signature, frame, border, "
    "people, person, character, human, face, creature, monster, "
    "shiny, glossy, specular highlight, lens flare, bloom, "
    "bright, overexposed, neon, colorful, cute, cartoon, 3d render, "
    "flat, no depth, top-down, top view, close-up, "
    "cluttered, foreground object blocking view"
)

MAP_STYLE = (
    "masterpiece, best quality, absurdres, "
    "top down aerial view of a hand drawn fantasy map, no humans, "
    "ink wash illustration, dark parchment texture, "
    "mountain ridges, winding rivers, carved roads, tiny ruined towers, "
    "desaturated cold palette, deep teal and dusty grey, faint gold contour lines, "
    "aged cartography, no text, no labels, no watermark, no frame"
)
MAP_NEG = (
    "lowres, text, letters, words, numbers, watermark, signature, frame, border, "
    "people, person, character, creature, bird's eye view of a scene, 3d terrain, "
    "bright, saturated, colorful, neon, cartoon, 3d render, photorealistic, "
    "close-up, single object, poster"
)

BATTLE = {
    "bg_battle_4": "a ruined village square at night, broken wooden houses receding, "
                   "empty dirt road in the foreground, distant fog",
    "bg_battle_5": "a frozen river bank at dusk, cracked ice sheet receding, "
                   "dead reeds, distant black mountains",
    # 第二幕 · 伪神国
    "bg_battle_2_1": "the nave of an enormous dark cathedral, rows of columns receding, "
                     "empty marble floor, cold light from high windows",
    "bg_battle_2_2": "a flooded crypt, shallow black water over stone floor, "
                     "columns receding into darkness",
    "bg_battle_2_3": "a vast reliquary hall, glass cases lined into the distance, "
                     "empty stone floor, dim gold light",
    # 第三幕 · 神明之土
    "bg_battle_3_1": "a floating stone platform above an endless void, "
                     "cracked pale floor receding to nothing, cold stars above",
    "bg_battle_3_2": "the interior of a colossal bone cathedral, ribs arching overhead, "
                     "empty pale floor receding, faint amber light",
    "bg_battle_3_3": "a wasteland of broken giant statues, heads half buried, "
                     "dust plain receding into haze, dim golden horizon",
    # Boss 场景
    "bg_battle_asclepius": "a circular temple of healing, ringed stone floor receding, "
                           "a tall altar in the far center, pale green light",
    "bg_battle_hephaestus": "a vast forge hall, anvils and channels receding, "
                            "empty scorched stone floor, orange glow from below",
    "bg_battle_hermes": "a long colonnade open to a dark sky, wind-blown dust on the floor, "
                        "columns receding, distant wing-shaped gate",
    "bg_battle_odin": "a broken throne hall open to the sky, cracked stone floor receding, "
                      "two ruined seats in the distance, cold grey light",
}

MAPS = {
    "bg_map": "an ancient ink-wash map of a mountainous human realm, winding roads, "
              "ruined towers marked as tiny shapes, cold dark parchment",
    "bg_map_2": "an ink-wash map of a false divine realm, symmetrical temple districts, "
                "wide processional roads, cold teal parchment",
    "bg_map_3": "an ink-wash map of a land of gods, colossal broken statues and dead trees, "
                "cracked plains, deep teal parchment",
}


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


def build(prompt, style, neg, seed, name, w, h):
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "5": {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": "%s, %s" % (prompt, style), "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 30, "cfg": 6.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "bg2_%s" % name, "images": ["8", 0]}},
    }


def gen(name, prompt, style, neg, out_dir, desk_dir, w, h):
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(desk_dir, exist_ok=True)
    dst = os.path.join(out_dir, name + ".png")
    if os.path.exists(dst) and os.path.getsize(dst) > 30000:
        print("  skip", name, flush=True)
        return
    pid = post(build(prompt, style, neg, zlib.crc32(("bg2" + name).encode()) % 900000 + 1000, name, w, h))
    outs = wait(pid)
    imgs = outs.get("9", {}).get("images", [])
    if not imgs:
        print("  FAIL", name, flush=True)
        return
    src = os.path.join(COMFY_OUT, imgs[0]["filename"])
    for _ in range(30):
        if os.path.exists(src):
            break
        time.sleep(0.5)
    shutil.copy2(src, dst)
    shutil.copy2(dst, os.path.join(desk_dir, name + ".png"))
    print("  OK", name, flush=True)


def main():
    keys = list(BATTLE.keys())
    print("战斗背景 %d 张" % len(keys), flush=True)
    for i, k in enumerate(keys, 1):
        print("[%d/%d] %s" % (i, len(keys), k), flush=True)
        gen(k, BATTLE[k], BATTLE_STYLE, BATTLE_NEG, OUT_B, DESK_B, 1536, 864)
    mkeys = list(MAPS.keys())
    print("地图背景 %d 张" % len(mkeys), flush=True)
    for i, k in enumerate(mkeys, 1):
        print("[%d/%d] %s" % (i, len(mkeys), k), flush=True)
        gen(k, MAPS[k], MAP_STYLE, MAP_NEG, OUT_M, DESK_M, 1536, 864)
    print("完成", flush=True)


main()

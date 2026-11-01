# -*- coding: utf-8 -*-
"""战斗背景批量生成（SDXL / Animagine XL 4.0）

要求（来自需求）：
  · 有纵深：消失点透视、地面向远处延伸
  · 有站立的地方：画面下方 1/3 必须是**可站立的地面**（石桥、石板、雪地、焦土…）
  · 中间留空：不要有人物/怪物挡住战斗区域
  · 地面线大约在画面高度 78% 处（y≈560/720），和敌人立绘的底对齐线一致

输出：assets/art/bg_battle/（1920×1080 会超出 8G 显存，用 1536×864）
"""
import json, os, shutil, time, urllib.request, zlib

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "bg_battle")
DESKTOP = os.path.join(os.path.expanduser("~"), "Desktop", "逐神背景")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

STYLE = (
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
NEG = (
    "lowres, bad anatomy, text, watermark, signature, frame, border, "
    "people, person, character, human, face, creature, monster, "
    "shiny, glossy, specular highlight, lens flare, bloom, "
    "bright, overexposed, neon, colorful, cute, cartoon, 3d render, "
    "flat, no depth, top-down, top view, close-up, "
    "cluttered, foreground object blocking view"
)

BGS = {
    "bg_battle_1": "a vast ruined stone bridge at dusk, broken arches receding into mist, "
                   "empty cracked flagstone floor in the foreground, distant towers",
    "bg_battle_2": "the interior of a colossal abandoned cathedral, rows of stone columns receding, "
                   "shattered stained glass far above, empty stone floor, shafts of pale light",
    "bg_battle_3": "a withered battlefield at the foot of a dead world tree, "
                   "cracked earth floor receding toward distant roots, low fog, dim amber glow on the horizon",
    "bg_battle_tut": "a narrow stone corridor in a monastery, wooden beams and hanging cloth, "
                     "empty floorboards receding into darkness, a single lantern glow",
    "bg_battle_3_boss": "a vast underground throne hall, cracked marble floor receding, "
                        "a distant colossal broken throne in shadow, cold teal light from above",
    "bg_battle_tree": "an enormous hollow beneath a world tree, roots forming arches overhead, "
                      "empty root-covered ground receding into golden mist",
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


def build(prompt, seed, name):
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1536, "height": 864, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": "%s, %s" % (prompt, STYLE), "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 30, "cfg": 6.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "bg_%s" % name, "images": ["8", 0]}},
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(DESKTOP, exist_ok=True)
    keys = list(BGS.keys())
    for i, key in enumerate(keys, 1):
        print("[%d/%d] %s" % (i, len(keys), key), flush=True)
        pid = post(build(BGS[key], zlib.crc32(("bg" + key).encode()) % 900000 + 1000, key))
        outs = wait(pid)
        imgs = outs.get("9", {}).get("images", [])
        if not imgs:
            print("  FAIL", key)
            continue
        src = os.path.join(COMFY_OUT, imgs[0]["filename"])
        for _ in range(30):
            if os.path.exists(src):
                break
            time.sleep(0.5)
        dst = os.path.join(OUT, key + ".png")
        shutil.copy2(src, dst)
        shutil.copy2(dst, os.path.join(DESKTOP, key + ".png"))
        print("  OK", key, flush=True)
    print("完成")


main()

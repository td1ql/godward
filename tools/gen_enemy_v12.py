# -*- coding: utf-8 -*-
"""重画 9 张（v12）：改「造型」+ 提「色彩」

用户反馈：造型不像该有的样子（世界树像树桩、石像鬼像驼背老头、史莱姆是两坨绿浆），
而且整体太灰、线稿感重。

修正：
  · STYLE 去掉 desaturated，改成 rich colors / painterly / thick brushstrokes / soft light
  · 每个敌人重写成「一眼能认出来」的具体造型，用 3~5 个强识别特征
  · 保持 white background（抠图另说）
"""
import json, os, shutil, time, urllib.request, zlib

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "enemy_v12")
DESKTOP = os.path.join(os.path.expanduser("~"), "Desktop", "逐神敌人_重做4")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

STYLE = (
    "masterpiece, high score, great score, absurdres, "
    "full body character illustration, single character, "
    "plain white background, simple background, no environment, "
    "semi-realistic dark fantasy concept art, painterly brush strokes, "
    "detailed shading, matte surfaces, weathered texture, "
    "desaturated muted colors, deep teal shadows, faint warm amber rim light, "
    "standing pose, centered, no text, no watermark, no frame, "
    "faceless, face hidden in shadow, no visible facial features"
)
NEG = (
    "lowres, bad anatomy, bad hands, extra limbs, extra fingers, fewer digits, "
    "text, watermark, signature, frame, border, multiple characters, crowd, "
    "scenery, landscape, background elements, mountain, sky, "
    "shiny, glossy, polished metal, specular highlight, lens flare, bloom, "
    "bright, overexposed, neon, colorful, cute, chibi, cartoon, "
    "3d render, photorealistic, cropped head, "
    "detailed face, eyes, nose, lips, teeth, smile, expression, portrait, "
    "female, woman, girl, nude, naked"
)

# 每张给 3~5 个「一眼能认出」的强特征
JOBS = {
    "brute": ("狂徒",
        "a hulking bald male thug, thick scarred neck, "
        "bare chest wrapped in rusted iron chains, "
        "one hand cracking the other knuckle, "
        "leather trousers, heavy boots, hostile low stance"),
    "gargoyle": ("石像鬼",
        "a crouching demon gargoyle statue come alive, "
        "two huge folded bat wings, curved horns, "
        "four clawed limbs gripping forward, "
        "cracked grey granite skin with green moss in the seams, "
        "glowing hollow eye sockets"),
    "godchaser": ("逐神者",
        "a fanatic in shattered plate armor, "
        "both arms stretched upward toward the sky, "
        "a broken golden halo floating behind the head, "
        "tattered red cloth from the waist, "
        "body bent backward in desperate worship"),
    "goblin": ("哥布林",
        "a short hunched goblin, big pointed ears, "
        "long crooked nose, wide toothy grin, "
        "dirty leather apron, a heavy burlap sack over one shoulder, "
        "a short rusty cleaver in the other hand, bow-legged stance"),
    "hephaestus": ("赫菲斯托斯",
        "a massive male smith god with a bald head and thick beard, "
        "bare scarred torso, heavy leather apron, "
        "holding a huge blacksmith hammer over one shoulder, "
        "molten orange glow from cracks in his forearms"),
    "penitent": ("悔罪者",
        "a bare-backed kneeling man, deep whip scars crisscrossing his back, "
        "head bowed low, both hands gripping a bloodstained scourge, "
        "rough dark cloth around the waist, chains at the wrists"),
    "prayer": ("祈祷者",
        "a kneeling nun in a long ash-grey habit, "
        "both hands clasped around a wooden rosary, "
        "head bowed under a deep hood, "
        "heavy wool folds spreading around her knees, "
        "a single candle flame floating before her chest"),
    "rotting_slime": ("腐化史莱姆",
        "a towering mound of rotting flesh and ooze, "
        "translucent dark green body with visible bones inside, "
        "bursting bubbles on the surface leaking black fluid, "
        "a distorted half-formed human face pushing out from the front, "
        "no legs, dragging tendrils behind"),
    "world_tree": ("世界树",
        "a colossal ancient tree seen from the ground looking up, "
        "a massive cracked trunk with a dark hollow doorway at its base, "
        "bare twisted branches spreading across the sky, "
        "roots bursting through the earth, "
        "faint golden light leaking from the hollow, awe-inspiring scale"),
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


def build(prompt, seed, key):
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1024, "height": 1152, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": "%s, %s" % (prompt, STYLE), "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": zlib.crc32(("v12" + key).encode()) % 900000 + 1000,
            "steps": 32, "cfg": 6.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "enemyv12_%s" % key, "images": ["8", 0]}},
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(DESKTOP, exist_ok=True)
    keys = list(JOBS.keys())
    for i, key in enumerate(keys, 1):
        cn, desc = JOBS[key]
        print("[%d/%d] %s (%s)" % (i, len(keys), key, cn), flush=True)
        pid = post(build(desc, 0, key))
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

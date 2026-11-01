# -*- coding: utf-8 -*-
"""重出用户点名的 10 张敌人（v9：更优美 + 更易读）

问题：
  · 画面偏「草稿感」，素描线太乱 → 加 refined linework / clean rendering / graceful pose
  · world_tree 完全看不懂 → 换成明确的「巨树 + 中空树干 + 拱门」

输出：assets/art/enemy_v9/<英文名>.png
"""
import json, os, shutil, time, urllib.request, zlib

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "enemy_v9")
DESKTOP = os.path.join(os.path.expanduser("~"), "Desktop", "逐神敌人_重做")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

STYLE = (
    "masterpiece, best quality, absurdres, "
    "full body character illustration, single character, "
    "plain white background, simple background, no environment, "
    "elegant and graceful, refined linework, clean rendering, "
    "semi-realistic dark fantasy concept art, polished, "
    "soft cinematic lighting, detailed fabric folds, "
    "desaturated muted palette, teal and warm amber, "
    "dignified composition, standing or kneeling pose, centered, "
    "faceless, face hidden in shadow, no visible facial features, "
    "no text, no watermark, no frame"
)
NEG = (
    "lowres, bad anatomy, bad hands, extra limbs, extra fingers, fewer digits, "
    "text, watermark, signature, frame, border, multiple characters, crowd, "
    "scenery, environment, landscape, background elements, mist, fog, ground, floor, "
    "sketch, rough draft, messy lines, unfinished, crude, ugly, "
    "shiny, glossy, polished metal, specular highlight, lens flare, bloom, "
    "bright, overexposed, neon, colorful, cute, chibi, cartoon, "
    "3d render, photorealistic, cropped head, "
    "detailed face, eyes, nose, lips, teeth, smile, expression, portrait, "
    "female, woman, girl, nude, naked"
)

JOBS = {
    "ash_nun": ("灰烬修女",
        "an elegant nun in an ash-grey habit, long flowing veil, "
        "holding a thin silver cross, calm restrained posture, "
        "smooth clean fabric folds"),
    "brute": ("狂徒",
        "a muscular male brawler in torn dark trousers, bare scarred back, "
        "both fists raised in a grounded fighting stance, heavy silhouette, "
        "clean anatomy, no armor"),
    "gargoyle": ("石像鬼",
        "a crouching stone gargoyle with folded bat wings, horned head, "
        "clawed hands resting on a stone ledge, weathered granite surface with moss, "
        "elegant gothic silhouette"),
    "godchaser": ("逐神者",
        "a lean male fanatic in a tattered dark cloak, both arms raised upward, "
        "body arched back as if reaching for the sky, "
        "cloth flowing in wind, elegant upward gesture"),
    "goblin": ("哥布林",
        "a slender male goblin with grey-green skin, long pointed ears, "
        "wearing a dark leather apron, holding a curved cleaver low, "
        "hunched but graceful stance"),
    "hephaestus": ("赫菲斯托斯",
        "a broad male smith god in a heavy leather apron, bare muscular arms, "
        "holding a large smith's hammer at his side, calm imposing posture, "
        "soot-stained but refined"),
    "penitent": ("悔罪者",
        "a bare-backed male penitent, scars across his back, "
        "holding a thin whip loosely in one hand, head bowed, "
        "dark cloth wrapped around the waist, quiet suffering"),
    "prayer": ("祈祷者",
        "a kneeling figure in a long grey hooded robe, hands clasped before the chest, "
        "head bowed, deep cloth folds pooling on the floor, "
        "elegant and solemn"),
    "rotting_slime": ("腐化史莱姆",
        "a towering rotting sludge creature, an amorphous mass of dark green ooze, "
        "dripping and bubbling, a faint hollow face-like dent near the top, "
        "no limbs, elegant abstract silhouette"),
    "world_tree": ("世界树",
        "a colossal dead world tree standing alone, a thick hollow trunk forming a doorway, "
        "bare twisted branches spreading wide, roots cracking the ground, "
        "seen from a distance, awe-inspiring scale, clean silhouette"),
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
            "seed": seed, "steps": 32, "cfg": 6.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "enemyv9_%s" % key, "images": ["8", 0]}},
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(DESKTOP, exist_ok=True)
    keys = list(JOBS.keys())
    for i, key in enumerate(keys, 1):
        cn, desc = JOBS[key]
        print("[%d/%d] %s (%s)" % (i, len(keys), key, cn), flush=True)
        pid = post(build(desc, zlib.crc32(("v9" + key).encode()) % 900000 + 1000, key))
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

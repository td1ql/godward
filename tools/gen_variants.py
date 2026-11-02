# -*- coding: utf-8 -*-
"""多版本生成：同一张卡抽 N 个版本，人工挑最好的

用法：
  python tools/gen_variants.py               # 默认 20 张 × 3 版
  python tools/gen_variants.py 受激,赎罪 4   # 指定卡名 + 版本数

输出：assets/art/variants/<卡名>_1.png ...
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
OUT = os.path.join(ROOT, "assets", "art", "variants")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

STYLE = (
    "masterpiece, best quality, absurdres, "
    "medieval dark fantasy illustration, single character, "
    "medium shot, full upper body and head visible, hands in frame, "
    "face visible in three-quarter view, centered composition, "
    "detailed clothing, layered fabric, dirt and wear, "
    "semi-realistic painterly concept art, matte surfaces, "
    "desaturated muted colors, warm light from the side, clear light and shadow, "
    "strong rim light on the figure, dramatic composition, "
    "clear readable silhouette, no text, no watermark, no frame"
)
NEG = (
    "lowres, text, watermark, signature, frame, border, "
    "spaceship, cannon, firearm, gun, rifle, machine, technology, robot, "
    "sci-fi, futuristic, neon, modern building, city street, car, "
    "extra limbs, extra fingers, bad hands, bad anatomy, deformed face, "
    "multiple people, crowd, cute, cartoon, chibi, 3d render, photorealistic, "
    "abstract shapes, geometric poster, blank silhouette, faceless, blank face"
)

DEFAULT_CARDS = [
    "受激", "赎罪", "双重打击", "数星", "速记", "吐锋", "吞噬", "瓦解", "万钧", "妄言",
    "吸血", "陷阱", "星位", "虚弱打击", "星辉", "蓄力", "虚弱药剂", "削弱", "血祭", "血刃",
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
              "inputs": {"width": 832, "height": 704, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": prompt, "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 32, "cfg": 7.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "var_", "images": ["8", 0]}},
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    cards = DEFAULT_CARDS
    nver = 3
    if len(sys.argv) > 1:
        cards = [c.strip() for c in sys.argv[1].split(",") if c.strip()]
    if len(sys.argv) > 2:
        nver = int(sys.argv[2])
    total = len(cards) * nver
    print("共 %d 张卡 × %d 版 = %d 张" % (len(cards), nver, total), flush=True)
    i = 0
    for name in cards:
        if name not in SUBJECTS:
            print("  跳过（无描述）:", name, flush=True)
            continue
        base = SUBJECTS[name]
        for v in range(nver):
            i += 1
            print("[%d/%d] %s v%d" % (i, total, name, v + 1), flush=True)
            # 每版换一个 seed，并在提示词尾部微调光照描述，制造差异
            tweaks = ["", ", warm torchlight from the left", ", cold light through a high window"]
            prompt = base + ", " + STYLE + tweaks[v % len(tweaks)]
            pid = post(build(prompt, zlib.crc32(("%s%d" % (name, v)).encode()) % 900000 + 1000))
            outs = wait(pid)
            imgs = outs.get("9", {}).get("images", [])
            if not imgs:
                print("  FAIL", flush=True)
                continue
            src = os.path.join(COMFY_OUT, imgs[0]["filename"])
            for _ in range(30):
                if os.path.exists(src):
                    break
                time.sleep(0.5)
            shutil.copy2(src, os.path.join(OUT, "%s_%d.png" % (name, v + 1)))
    print("完成", flush=True)


main()

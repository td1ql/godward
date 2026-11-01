# -*- coding: utf-8 -*-
"""SDXL 卡面批量生成（Animagine XL 4.0）

用法：
  python tools/gen_card_art_xl.py --demo      # 先出 10 张看效果
  python tools/gen_card_art_xl.py --all       # 出全部
  python tools/gen_card_art_xl.py --all --from 50   # 从第 50 张续跑

产物：
  assets/art/cardart/<卡名>.png   （1024×1024）
  最后会同步一份到 桌面\\逐神卡面\\
"""
import argparse, json, os, shutil, sys, time, urllib.request, zlib

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMPTS = os.path.join(ROOT, "tools", "card_prompts.json")
OUT_DIR = os.path.join(ROOT, "assets", "art", "cardart")
DESKTOP = os.path.join(os.path.expanduser("~"), "Desktop", "逐神卡面")
COMFY_OUT = r"C:\ComfyUI\output"

CKPT = "animagine-xl-4.0.safetensors"

STYLE_OBJ = (
    "masterpiece, high score, great score, absurdres, "
    "still life, no humans, object focus, "
    "semi-realistic dark fantasy illustration, dramatic chiaroscuro lighting, "
    "rich muted colors, cool teal shadows with warm amber key light, "
    "intricate detail, centered composition, dark background with soft glow, "
    "no text, no watermark, no frame"
)
STYLE_SIL = (
    "masterpiece, high score, great score, absurdres, "
    "silhouette, backlit figure, no visible face, dramatic backlight, "
    "semi-realistic dark fantasy illustration, rich muted colors, "
    "cool teal shadows with warm amber key light, motion, dust, "
    "centered composition, no text, no watermark, no frame"
)
NEG = (
    "lowres, bad anatomy, bad hands, text, error, missing fingers, "
    "extra digit, fewer digits, cropped, worst quality, low quality, "
    "normal quality, jpeg artifacts, signature, watermark, username, blurry, "
    "face, closeup, portrait, bright cheerful, saturated neon, "
    "frame, border, multiple views, sepia, monochrome orange, brown tint"
)


def post_prompt(wf: dict) -> str:
    body = json.dumps({"prompt": wf}).encode()
    req = urllib.request.Request(API + "/prompt", data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())["prompt_id"]


def wait_result(pid: str, timeout: int = 600) -> dict:
    t0 = time.time()
    while time.time() - t0 < timeout:
        time.sleep(2)
        with urllib.request.urlopen(API + "/history/" + pid, timeout=30) as r:
            h = json.loads(r.read())
        if pid in h:
            return h[pid]["outputs"]
    return {}


def build_workflow(symbol: str, seed: int, kind: str) -> dict:
    style = STYLE_SIL if kind == "sil" else STYLE_OBJ
    pos = "%s, %s" % (symbol, style)
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 30, "cfg": 6.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "cardartxl", "images": ["8", 0]}},
    }


def gen_one(name: str, entry: dict, seed: int) -> bool:
    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, name + ".png")
    if os.path.exists(out_path) and os.path.getsize(out_path) > 10000:
        return True
    try:
        pid = post_prompt(build_workflow(entry["prompt"], seed, entry.get("kind", "obj")))
    except Exception as e:
        print("   提交失败:", e)
        return False
    outs = wait_result(pid)
    imgs = outs.get("9", {}).get("images", [])
    if not imgs:
        print("   ❌ 无输出:", name)
        return False
    src = os.path.join(COMFY_OUT, imgs[0]["filename"])
    for _ in range(30):
        if os.path.exists(src):
            break
        time.sleep(0.5)
    try:
        shutil.copy2(src, out_path)
    except Exception as e:
        print("   复制失败:", e)
        return False
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--demo", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--from", dest="start", type=int, default=0)
    a = ap.parse_args()

    data = json.load(open(PROMPTS, encoding="utf-8"))
    names = list(data.keys())
    if a.demo:
        keys = ["防御", "打击", "格挡", "中毒", "回复", "抽牌", "力量", "处决", "蓄力", "金币"]
        names = [k for k in keys if k in data]
        names += [k for k in list(data.keys())[:3] if k not in names]
    if a.start:
        names = names[a.start:]

    t0 = time.time()
    ok = 0
    for i, name in enumerate(names, 1):
        seed = zlib.crc32(name.encode('utf-8')) % 900000 + 1000
        el = time.time() - t0
        eta = (el / i * (len(names) - i)) if i > 1 else 0
        print("[%d/%d] %-10s 已用 %ds  剩余约 %ds" % (i, len(names), name, int(el), int(eta)), flush=True)
        if gen_one(name, data[name], seed):
            ok += 1
    print("\n完成 %d / %d 张" % (ok, len(names)))

    # 同步到桌面
    if os.path.isdir(OUT_DIR):
        os.makedirs(DESKTOP, exist_ok=True)
        n = 0
        for f in os.listdir(OUT_DIR):
            if f.lower().endswith(".png"):
                shutil.copy2(os.path.join(OUT_DIR, f), os.path.join(DESKTOP, f))
                n += 1
        print("已同步 %d 张到 %s" % (n, DESKTOP))


main()

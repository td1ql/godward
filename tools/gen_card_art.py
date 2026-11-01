# -*- coding: utf-8 -*-
"""给卡牌出图：提交 ComfyUI → 拿结果 → 存到 assets/art/cardart/

用法：
  python tools/gen_card_art.py --sample          # 出 3 张样张
  python tools/gen_card_art.py --all             # 出全部 214 张
  python tools/gen_card_art.py --only 防御,打击   # 只出指定卡
"""
import argparse, json, os, sys, time, urllib.request, shutil

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "art", "cardart")
COMFY_OUT = r"C:\ComfyUI\output"

STYLE_POS = (
    "masterpiece, best quality, still life, no humans, object only, "
    "semi-realistic anime illustration, "
    "dramatic cinematic lighting, strong rim light from behind, "
    "deep teal and amber color palette, rich but muted colors, "
    "intricate linework, dark moody background with soft glow, "
    "centered composition, highly detailed, "
    "no text, no frame, no border, no watermark"
)
STYLE_NEG = (
    "(face:1.4), (eyes:1.4), portrait, closeup, "
    "text, letters, watermark, signature, frame, border, "
    "low quality, blurry, chibi, cartoon, 3d render, photorealistic, "
    "cluttered, oversaturated, neon, multiple objects"
)


# 每张卡 → 象征物（没写到的用默认兜底）
SYMBOLS = {
    # ── 物件类：画一个东西 ──
    "防御": ("obj", "an ancient round shield, cracked, glowing runes along the rim, standing in darkness"),
    "格挡": ("obj", "a wall of stacked stone blocks, a faint protective sigil glowing on its surface"),
    "中毒": ("obj", "a glass vial of black venom tipping over, dark liquid spreading on stone"),
    "回复": ("obj", "a small white flower blooming out of cracked ash and stone, soft light"),
    "抽牌": ("obj", "three glowing cards floating in a spiral, edges catching fire"),
    "金币": ("obj", "a pile of ancient gold coins with a strange eye engraved on the top one"),
    "血": ("obj", "a thin dagger with a single drop of blood at the tip, dark red glow"),

    # ── 剪影类：画一个人在做一个动作（背光，不画脸）──
    "打击": ("sil", "silhouette of a warrior mid-swing with a long blade, backlit, motion blur"),
    "处决": ("sil", "silhouette of an executioner raising a heavy blade, chains, backlit"),
    "蓄力": ("sil", "silhouette of an archer drawing a glowing longbow, backlit"),
    "力量": ("sil", "silhouette of a fighter clenching a fist, golden light leaking between fingers"),
    "冲锋": ("sil", "silhouette of a knight charging forward, cape flying, dust behind"),
    "祈祷": ("sil", "silhouette of a kneeling figure praying, hands clasped, light from above"),
}


def post_prompt(wf: dict) -> str:
    body = json.dumps({"prompt": wf}).encode()
    req = urllib.request.Request(API + "/prompt", data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())["prompt_id"]


def wait_result(pid: str, timeout: int = 300) -> dict:
    t0 = time.time()
    while time.time() - t0 < timeout:
        time.sleep(2)
        with urllib.request.urlopen(API + "/history/" + pid, timeout=30) as r:
            h = json.loads(r.read())
        if pid in h:
            return h[pid]["outputs"]
    return {}


def build_workflow(ckpt: str, symbol: str, seed: int, kind: str = "obj") -> dict:
    if kind == "sil":
        lead = "silhouette, backlit figure, no visible face, dramatic backlight, "
    else:
        lead = "still life, no humans, object only, "
    pos = "%s, %s%s" % (symbol, lead, STYLE_POS)
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": ckpt}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 512, "height": 512, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": STYLE_NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 28, "cfg": 7.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "cardart", "images": ["8", 0]}},
    }


def first_checkpoint() -> str:
    with urllib.request.urlopen(API + "/object_info/CheckpointLoaderSimple", timeout=30) as r:
        info = json.loads(r.read())
    ck = info["CheckpointLoaderSimple"]["input"]["required"]["ckpt_name"][0]
    return ck[0] if ck else ""


def gen_one(ckpt: str, name: str, symbol: str, seed: int, kind: str = "obj") -> str:
    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, name + ".png")
    if os.path.exists(out_path):
        print("  跳过（已存在）:", name)
        return out_path
    pid = post_prompt(build_workflow(ckpt, symbol, seed, kind))
    outs = wait_result(pid)
    imgs = outs.get("9", {}).get("images", [])
    if not imgs:
        print("  ❌ 没有输出:", name)
        return ""
    fn = imgs[0]["filename"]
    src = os.path.join(COMFY_OUT, fn)
    for _ in range(20):
        if os.path.exists(src):
            break
        time.sleep(0.5)
    shutil.copy2(src, out_path)
    print("  ✅ %-8s -> %s" % (name, os.path.basename(out_path)))
    return out_path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sample", action="store_true")
    ap.add_argument("--demo", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--only", default="")
    a = ap.parse_args()

    ckpt = first_checkpoint()
    print("模型:", ckpt)

    if a.sample:
        targets = [("防御", "防御", 11), ("打击", "打击", 22), ("中毒", "中毒", 33)]
    elif a.demo:
        names = ["防御", "打击", "格挡", "中毒", "回复", "抽牌", "力量", "处决", "蓄力", "金币"]
        targets = [(n, n, 100 + i * 37) for i, n in enumerate(names)]
    elif a.only:
        names = [x.strip() for x in a.only.split(",") if x.strip()]
        targets = [(n, n, hash(n) % 100000) for n in names]
    else:
        print("需要 --sample / --all / --only")
        return

    for i, (name, sym_key, seed) in enumerate(targets):
        entry = SYMBOLS.get(sym_key, ("obj", sym_key))
        kind, sym = entry
        print("[%d/%d] %-6s (%s)" % (i + 1, len(targets), name, kind))
        gen_one(ckpt, name, sym, seed, kind)


main()

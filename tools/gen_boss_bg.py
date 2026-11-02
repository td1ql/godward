# -*- coding: utf-8 -*-
"""Boss 背景生成（用英雄立绘做 IP-Adapter 参考）

前置：
  · ComfyUI 已装 ComfyUI_IPAdapter_plus（custom_nodes 下）
  · models/ipadapter/ip-adapter_sdxl.safetensors
  · models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors
  · 改完 node 后**必须重启 ComfyUI** 才生效

用法：
  python tools/gen_boss_bg.py            # 全部 Boss
  python tools/gen_boss_bg.py odin       # 只出奥丁

输出：assets/art/boss_bg/ + 桌面\\逐神Boss背景\\
"""
import json, os, shutil, sys, time, urllib.request, zlib

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "boss_bg")
DESKTOP = os.path.join(os.path.expanduser("~"), "Desktop", "逐神Boss背景")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"
IPADAPTER = "ip-adapter-plus_sdxl_vit-h.safetensors"
CLIP_VISION = "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
HERO_DIR = os.path.join(ROOT, "assets", "art", "vocation")

STYLE = (
    "masterpiece, best quality, absurdres, "
    "wide cinematic background, one single figure standing in the center distance, "
    "medieval dark fantasy, monumental scale, "
    "strong perspective, empty ground plane in the lower third, "
    "semi-realistic painterly concept art, matte surfaces, "
    "desaturated muted colors, deep teal shadows, warm amber light source, "
    "atmospheric haze, layers of distance, "
    "no text, no watermark, no frame"
)
NEG = (
    "lowres, text, watermark, signature, frame, border, "
    "spaceship, cannon, firearm, gun, rifle, machine, technology, robot, "
    "sci-fi, futuristic, neon, modern building, crowd, "
    "extra limbs, extra fingers, bad hands, deformed face, "
    "cartoon, chibi, 3d render, photorealistic"
)

# Boss 名 → (场景描述, 参考立绘文件名不含扩展名)
BOSSES = {
    "odin": ("a broken throne hall open to a stormy sky, a lone crowned figure standing far away, cracked stone floor receding", "疯癫的先知"),
    "pope": ("a vast cathedral nave, a single robed figure on the steps far ahead, rows of columns receding", "数星星的瞎子"),
    "asclepius": ("a circular healing temple, one figure kneeling at the far altar, ringed stone floor receding", "等死的病人"),
    "hephaestus": ("a colossal forge hall, one smith standing before a glowing anvil far away, channels of molten metal", "磨刀的哑巴"),
    "hermes": ("a long colonnade open to a dark sky, one figure walking away down the center", "无名的旅人"),
    "godchaser": ("a ruined battlefield at dusk, one armored figure standing alone in the distance", "断臂的旗手"),
    "world_tree": ("an immense hollow beneath a world tree, one tiny figure standing at the base of the trunk", "饥饿的朝圣者"),
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


def build(scene, ref_name, seed):
    """IP-Adapter 工作流：参考图 → 视觉编码 → 注入 UNet"""
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "IPAdapterModelLoader",
              "inputs": {"ipadapter_file": IPADAPTER}},
        "3": {"class_type": "CLIPVisionLoader",
              "inputs": {"clip_name": CLIP_VISION}},
        "4": {"class_type": "LoadImage", "inputs": {"image": ref_name + ".webp"}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1536, "height": 864, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": scene + ", " + STYLE, "clip": ["1", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "8": {"class_type": "IPAdapterAdvanced", "inputs": {
            "model": ["1", 0], "ipadapter": ["2", 0], "image": ["4", 0],
            "clip_vision": ["3", 0], "weight": 0.42, "weight_type": "style transfer",
            "combine_embeds": "concat", "start_at": 0.0, "end_at": 0.7,
            "embeds_scaling": "V only"}},
        "9": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 32, "cfg": 6.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["8", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}},
        "11": {"class_type": "SaveImage",
               "inputs": {"filename_prefix": "bossbg_", "images": ["10", 0]}},
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(DESKTOP, exist_ok=True)
    only = sys.argv[1] if len(sys.argv) > 1 else None
    keys = [only] if only else list(BOSSES.keys())
    for i, key in enumerate(keys, 1):
        if key not in BOSSES:
            print("no such boss:", key)
            continue
        scene, ref = BOSSES[key]
        ref_path = os.path.join(HERO_DIR, ref + ".webp")
        if not os.path.exists(ref_path):
            print("[%d/%d] %s 缺少参考图 %s" % (i, len(keys), key, ref_path), flush=True)
            continue
        print("[%d/%d] %s (ref=%s)" % (i, len(keys), key, ref), flush=True)
        try:
            pid = post(build(scene, ref, zlib.crc32(("boss" + key).encode()) % 900000 + 1000))
        except Exception as e:
            print("  提交失败:", e, flush=True)
            continue
        outs = wait(pid)
        imgs = outs.get("11", {}).get("images", [])
        if not imgs:
            print("  FAIL", key, flush=True)
            continue
        src = os.path.join(COMFY_OUT, imgs[0]["filename"])
        for _ in range(30):
            if os.path.exists(src):
                break
            time.sleep(0.5)
        dst = os.path.join(OUT, key + ".png")
        shutil.copy2(src, dst)
        try:
            shutil.copy2(dst, os.path.join(DESKTOP, key + ".png"))
        except Exception:
            pass
        print("  OK", key, flush=True)
    print("完成", flush=True)


main()

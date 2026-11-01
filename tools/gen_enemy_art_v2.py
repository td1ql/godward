# -*- coding: utf-8 -*-
"""重出用户点名的 20 张敌人立绘（v2 提示词）

问题诊断：
  · 整体过暗，几乎全是黑色剪影 → 提亮到 mid key，强调「能被看清的材质」
  · 兽型/男性敌人被画成女性（甚至裸体剪影）→ 显式写 male / monster，负面堆死 female+nude
  · 部分描述太抽象（「a winged goat」）→ 改成「具体姿势 + 具体装备」
"""
import json, os, shutil, time, urllib.request, zlib

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "enemy2")
DESKTOP = os.path.join(os.path.expanduser("~"), "Desktop", "逐神敌人")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

STYLE = (
    "masterpiece, high score, great score, absurdres, "
    "full body character illustration, single character, "
    "plain white background, simple background, no environment, "
    "semi-realistic dark fantasy concept art, painterly brush strokes, "
    "detailed shading, matte surfaces, weathered texture, "
    "desaturated muted colors, soft rim light, "
    "standing pose, centered, no text, no watermark, no frame"
)
NEG = (
    "lowres, bad anatomy, bad hands, extra limbs, extra fingers, fewer digits, "
    "text, watermark, signature, frame, border, multiple characters, crowd, "
    "scenery, environment, landscape, background elements, mist, fog, ground, floor, "
    "shiny, glossy, polished metal, specular highlight, lens flare, bloom, "
    "bright, overexposed, neon, colorful, cute, chibi, cartoon, "
    "3d render, photorealistic, cropped head, "
    "female, woman, girl, nude, naked"
)

# 20 张重做：显式性别、显式装备、显式姿势
JOBS = {
    "ascetic": ("苦行僧",
        "a gaunt middle-aged MALE monk in torn grey rags, ribs showing, "
        "iron ring around his neck, whip scars on his back, bald head, "
        "kneeling with head bowed, holding a wooden prayer bead"),
    "asclepius": ("阿斯克勒庇俄斯",
        "a MALE healer god with a long grey beard, pale layered robes, "
        "holding a wooden staff with a snake coiled around it, "
        "calm eyes, standing in a ruined temple"),
    "bats": ("蝙蝠群",
        "a dense swarm of black vampire bats filling the frame, "
        "many small winged silhouettes, several large bats in the foreground, "
        "empty dark cavern, no people"),
    "blind_seer": ("盲眼先知",
        "an old MALE blind prophet, bandage wrapped over both eyes, "
        "long grey robe, gnarled hand raised, mouth slightly open, "
        "standing in a stone corridor"),
    "brute": ("狂徒",
        "a bulky MALE brawler with a scarred face and bruised knuckles, "
        "bare chest, leather straps across shoulders, fists raised, "
        "aggressive stance, dusty arena"),
    "choir": ("唱诗班",
        "three MALE choir singers in identical grey hooded robes, "
        "standing in a row, faces hidden, mouths open in song, "
        "candlelit stone chapel"),
    "death_knight": ("亡灵骑士",
        "a MALE undead knight in blackened plate armor, horned helm, "
        "tattered dark cape, holding a broken greatsword, "
        "standing in a ruined hall, dust"),
    "faceless_bard": ("无面乐师",
        "a MALE musician in dark finery, face completely blank and smooth, "
        "a horned mask on his head, holding a dark violin and bow, "
        "standing under faint spotlight"),
    "flame_elem": ("火元素",
        "a towering creature made of dull embers and ash, "
        "a body of cracked charcoal with glowing orange lines, "
        "no face, arms of smoke, standing in scorched ground"),
    "gargoyle": ("石像鬼",
        "a crouching stone gargoyle, cracked granite skin, "
        "bat wings folded, horned head, clawed hands, "
        "perched on a broken cathedral ledge"),
    "gatekeeper": ("守门人",
        "a huge MALE gatekeeper in battered dark plate armor, "
        "tower helm with a narrow visor, holding a chained spiked mace, "
        "standing before an iron gate"),
    "goblin": ("哥布林",
        "a small male goblin creature, green-grey wrinkled skin, "
        "long pointed ears, hunched back, sharp teeth, ragged leather apron, "
        "holding a crude cleaver, in a dark tunnel"),
    "godchaser": ("逐神者",
        "a MALE fanatic in broken armor, face wrapped in cloth, "
        "both hands raised toward the sky, cracked halo behind him, "
        "standing on rubble"),
    "gregory": ("格里高利",
        "a broad-shouldered MALE saint in layered dark robes, "
        "short grey beard, hands folded in prayer, "
        "stone pillars behind him"),
    "hephaestus": ("赫菲斯托斯",
        "a muscular MALE smith god with a burnt leather apron, "
        "soot on his face, holding a heavy hammer, "
        "standing in a dark forge with faint fire glow"),
    "hermes": ("赫尔墨斯",
        "a MALE traveller god in a dark hooded cloak, "
        "small feathered wings on his sandals and hat, "
        "holding a caduceus staff, walking pose"),
    "judge": ("审判者",
        "a MALE judge in black robes, full face mask of carved bone, "
        "holding a pair of brass scales in one hand and a thin blade in the other, "
        "standing in a dark courtroom"),
    "prayer": ("祈祷者",
        "a MALE figure in a grey hooded robe, kneeling, "
        "hands clasped in prayer, head bowed, "
        "soft light from above, stone floor"),
    "scribe": ("书记官",
        "a MALE clerk in a heavy dark coat, face hidden under a hood, "
        "holding a large ledger and a long quill, "
        "standing behind a candlelit desk"),
    "skeleton": ("骷髅兵",
        "a skeleton soldier, bare bones with rusted iron shoulder plate, "
        "holding a cracked round wooden shield, "
        "standing in a dark corridor"),
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


def build(prompt, seed):
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1024, "height": 1152, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": "%s, %s" % (prompt, STYLE), "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["4", 1]}},
        "3": {"class_type": "KSampler", "inputs": {
            "seed": zlib.crc32(("v2" + prompt[:20]).encode()) % 900000 + 1000,
            "steps": 30, "cfg": 6.5,
            "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0],
            "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "enemyv2", "images": ["8", 0]}},
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    keys = list(JOBS.keys())
    for i, key in enumerate(keys, 1):
        cn, desc = JOBS[key]
        print("[%d/%d] %s (%s)" % (i, len(keys), key, cn), flush=True)
        pid = post(build(desc, 0))
        outs = wait(pid)
        imgs = outs.get("9", {}).get("images", [])
        if not imgs:
            print("  ❌", key)
            continue
        src = os.path.join(COMFY_OUT, imgs[0]["filename"])
        for _ in range(30):
            if os.path.exists(src):
                break
            time.sleep(0.5)
        dst = os.path.join(OUT, key + ".png")
        shutil.copy2(src, dst)
        try:
            os.makedirs(DESKTOP, exist_ok=True)
            shutil.copy2(dst, os.path.join(DESKTOP, key + ".png"))
        except Exception:
            pass
        print("  ✅", key, flush=True)
    print("完成 %d 张" % len(keys))


main()

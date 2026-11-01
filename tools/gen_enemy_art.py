# -*- coding: utf-8 -*-
"""敌人立绘批量生成（SDXL / Animagine XL 4.0）

输出：assets/art/enemy2/<英文名>.png（1024×1152，3:3.375）
      最后同步一份到 桌面\\逐神敌人\\
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
    "standing pose, centered, no text, no watermark, no frame, "
    "faceless, face hidden in shadow, no visible facial features"
)
NEG = (
    "lowres, bad anatomy, bad hands, extra limbs, extra fingers, fewer digits, "
    "text, watermark, signature, frame, border, multiple characters, crowd, "
    "scenery, environment, landscape, background elements, mist, fog, ground, floor, "
    "shiny, glossy, polished metal, specular highlight, lens flare, bloom, "
    "bright, overexposed, neon, colorful, cute, chibi, cartoon, "
    "3d render, photorealistic, cropped head, "
    "detailed face, eyes, nose, lips, teeth, smile, expression, portrait, "
    "ugly face, deformed face, mismatched eyes, "
    "female, woman, girl, nude, naked"
)

# 英文名 → (中文名, 描述)
ENEMIES = {
    # ── 第一幕 · 人间 ──
    "slime":       ("史莱姆", "a translucent grey ooze creature shaped like a lump, wet dripping surface, no eyes"),
    "goblin":      ("哥布林", "a hunched male goblin with green-grey wrinkled skin, ragged leather apron, crude dagger, long pointed ears, sharp teeth"),
    "skeleton":    ("骷髅兵", "a skeleton soldier in rusted half armor, cracked shield, empty eye sockets"),
    "spider":      ("毒蜘蛛", "a huge black venom spider with dripping fangs, eight bristled legs, no human features, crawled low to the ground"),
    "brute":       ("狂徒", "a bulky male thug with a scarred face, bare chest, torn wraps, fists raised"),
    "rotting_slime": ("腐化史莱姆", "a rotting sludge creature with bubbling green-black surface, leaking fumes"),
    "hexer":       ("咒术师", "a hooded hexer holding a bone charm, faint smoke around hands"),
    "thorn_beast": ("荆棘兽", "a four-legged beast covered in long black thorns, bone plating, no human features, crouching low"),
    "bats":        ("蝙蝠群", "a swirling swarm of dark bats in the shape of a cloud"),
    "gargoyle":    ("石像鬼", "a crouching stone gargoyle with cracked wings, moss in the seams"),
    "corpse":      ("腐尸", "a bloated walking corpse in waterlogged cloth, grey skin"),
    "flame_elem":  ("火元素", "a humanoid shape made of dull embers and ash, no face"),
    "frost_wisp":  ("冰霜精", "a small floating ice spirit with pale blue cracks, trailing frost"),
    "ogre":        ("食人魔", "a massive ogre with a crude club, scarred grey hide"),
    "twin_assassin": ("双子刺客", "two lean assassins back to back in dark cloth, twin curved blades"),
    "death_knight": ("亡灵骑士", "an undead knight in blackened plate, tattered cape, broken sword"),
    "lava_colossus": ("熔岩巨像", "a towering stone colossus with molten cracks glowing in its chest"),
    "elite_guard": ("精英守卫", "an elite guard in heavy dark plate, tower shield, faceless helm"),
    "elite_mage":  ("精英法师", "a gaunt mage in layered dark robes, staff topped with a dull crystal"),
    "blood_priest": ("血祭司", "a blood priest in stained ceremonial robes, chalice in hand"),

    # ── 第二幕 · 伪神国 ──
    "headless_knight": ("断头骑士", "a headless knight in rusted plate holding a greatsword, neck stump wrapped in cloth"),
    "hanged":      ("缢死者", "a hanged corpse still standing, rope around neck, arms limp"),
    "reliquary":   ("圣骸行者", "a walking reliquary of bones and gold, many arms"),
    "scribe":      ("书记官", "a robed clerk with a heavy ledger and quill, face hidden"),
    "ash_nun":     ("灰烬修女", "a nun in ash-grey habit, face veiled, holding a burnt cross"),
    "faceless_bard": ("无面乐师", "a faceless musician in dark finery, holding a stringed instrument"),
    "gatekeeper":  ("守门人", "a huge gatekeeper in battered armor, chained mace, standing before a closed gate"),
    "augustine":   ("奥古斯丁", "a tall bishop in black and gold vestments, chain of office, cold gaze"),
    "ambrose":     ("安布罗斯", "a choir-master saint in white and grey, arms raised, faint halo of dust"),
    "jerome":      ("耶柔米", "a gaunt scholar-saint with a heavy book chained to his wrist"),
    "gregory":     ("格里高利", "a broad saint in layered robes, hands folded, stone-like stillness"),
    "chrysostom":  ("金口约翰", "a golden-mouthed preacher, jaw faintly glowing, robes of dark gold"),
    "penitent":    ("悔罪者", "a bare-backed penitent with a whip, scars across the back"),
    "blind_seer":  ("盲眼先知", "a blind seer with milky eyes and bandaged face, hand raised"),
    "prayer":      ("祈祷者", "a kneeling figure in grey, hands clasped, head bowed"),
    "idol":        ("圣像", "a carved stone idol of a saint, hollow eyes, gold leaf peeling"),
    "choir":       ("唱诗班", "three hooded choir singers in a row, mouths open, no faces"),
    "ascetic":     ("苦行僧", "a thin ascetic in rags, ribs visible, iron ring around neck"),
    "thorn_idol":  ("荆棘像", "a statue wrapped in black thorn vines, cracks glowing faintly"),

    # ── 第三幕 · 神明之土 ──
    "holy_reliquary": ("圣骸", "a towering skeletal relic draped in torn holy cloth, bone spikes"),
    "godchaser":   ("逐神者", "a fanatic in broken armor climbing upward, hands raised"),
    "judge":       ("审判者", "a masked judge in black robes, scales in one hand, blade in the other"),
    "divine_knight": ("神国骑士", "a knight in white-gold ruined plate, cracked halo, lance"),
    "lampbearer":  ("执灯者", "a thin figure carrying a rusted lantern, face hidden"),
    "pope":        ("教皇", "a colossal imposing pope in heavy layered black and gold vestments, tall golden mitre, arms spread wide in blessing, faceless white mask, aura of authority, seen from slightly below, dominating the frame"),
    "odin":        ("奥丁", "a one-eyed god in a wide hat and dark cloak, ravens circling, spear"),
    "hermes":      ("赫尔墨斯", "a winged god in a traveller's cloak, caduceus, sandals with feathers"),
    "asclepius":   ("阿斯克勒庇俄斯", "a healer god with a serpent staff, pale robes, many hands"),
    "hephaestus":  ("赫菲斯托斯", "a smith god with a hammer, burnt apron, glowing forge behind"),
    "world_tree":  ("世界树", "an enormous dead world tree with a hollow trunk shaped like a door, roots everywhere"),
    "jormungandr": ("耶梦加得", "a colossal serpent coiling around a broken world, scales like stone"),
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


def build(prompt, seed, key="x"):
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1024, "height": 1152, "batch_size": 1}},
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
              "inputs": {"filename_prefix": "enemy_%s" % key, "images": ["8", 0]}},
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    keys = list(ENEMIES.keys())
    for i, key in enumerate(keys, 1):
        cn, desc = ENEMIES[key]
        dst = os.path.join(OUT, key + ".png")
        if os.path.exists(dst) and os.path.getsize(dst) > 20000:
            print("[%d/%d] %s 跳过" % (i, len(keys), key))
            continue
        print("[%d/%d] %s (%s)" % (i, len(keys), key, cn), flush=True)
        pid = post(build(desc, zlib.crc32(key.encode()) % 900000 + 1000, key))
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
        shutil.copy2(src, dst)
        print("  ✅", dst, flush=True)

    os.makedirs(DESKTOP, exist_ok=True)
    n = 0
    for f in os.listdir(OUT):
        if f.endswith(".png"):
            shutil.copy2(os.path.join(OUT, f), os.path.join(DESKTOP, f))
            n += 1
    print("完成，共 %d 张，已同步到 %s" % (n, DESKTOP))


main()

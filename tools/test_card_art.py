# -*- coding: utf-8 -*-
"""卡面样张测试：指定几张卡，用当前提示词出图到 assets/art/cardtest/"""
import json, os, shutil, sys, time, urllib.request, zlib

API = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMPTS = os.path.join(ROOT, "tools", "card_prompts.json")
OUT = os.path.join(ROOT, "assets", "art", "cardtest")
COMFY_OUT = r"C:\ComfyUI\output"
CKPT = "animagine-xl-4.0.safetensors"

sys.path.insert(0, os.path.join(ROOT, "tools"))
import gen_card_art_xl as G


def gen(name, entry):
    os.makedirs(OUT, exist_ok=True)
    dst = os.path.join(OUT, name + ".png")
    seed = zlib.crc32(("v2" + name).encode("utf-8")) % 900000 + 1000
    pid = G.post_prompt(G.build_workflow(entry["prompt"], seed, entry.get("kind", "obj")))
    outs = G.wait_result(pid)
    imgs = outs.get("9", {}).get("images", [])
    if not imgs:
        print("  ❌", name)
        return
    src = os.path.join(COMFY_OUT, imgs[0]["filename"])
    for _ in range(30):
        if os.path.exists(src):
            break
        time.sleep(0.5)
    shutil.copy2(src, dst)
    print("  ✅", name, "->", dst)


def main():
    data = json.load(open(PROMPTS, encoding="utf-8"))
    keys = ["防御", "焚页", "敲钟", "星位", "药渣", "盾墙", "斩首", "长夜"]
    for k in keys:
        if k in data:
            print("出图:", k)
            gen(k, data[k])
    print("完成")


main()

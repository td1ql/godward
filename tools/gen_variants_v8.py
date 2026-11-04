# -*- coding: utf-8 -*-
"""同一张卡：一轮里每张换一个动作

读一份 JSON（{"V1": "动作描述", ...}），每条出一张图，动作互不相同。
输出：assets/art/_src_v8/variants/<卡名>/<标签>.png（原始 + 调色版）

用法：
  python tools/gen_variants_v8.py --card 淬毒 --file tools/variants_淬毒.json
"""
import argparse
import json
import os
import sys
import time
import zlib

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_card_art_v8 as G  # noqa: E402

ROOT = G.ROOT
COMFY_OUT = G.COMFY_OUT


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--card", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--recipe", default="B")
    ap.add_argument("--seeds", type=int, default=1)
    ap.add_argument("--width", type=int, default=0)
    ap.add_argument("--height", type=int, default=0)
    ap.add_argument("--style", default="", help="整段替换 STYLE（用于大远景等特殊构图）")
    ap.add_argument("--extra-neg", default="")
    ap.add_argument("--neg", default="", help="整段替换 NEG（需要露脸/蒙面等特殊需求时用）")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    if args.width and args.height:
        G.WIDTH, G.HEIGHT = args.width, args.height
    if args.style:
        G.STYLE = args.style
    if args.extra_neg:
        G.NEG = args.extra_neg.rstrip(" ,") + ", " + G.NEG
    if args.neg:
        G.NEG = args.neg

    with open(args.file, encoding="utf-8") as f:
        variants = json.load(f)

    out_dir = os.path.join(G.MASTER_ROOT, "variants", args.card)
    os.makedirs(out_dir, exist_ok=True)
    G.free_vram()

    t0 = time.time()
    for i, (label, text) in enumerate(variants.items(), 1):
        for s in range(args.seeds):
            tag = label if args.seeds == 1 else "%s_s%d" % (label, s)
            raw = os.path.join(out_dir, tag + ".png")
            if os.path.exists(raw) and not args.force:
                print("跳过已有", tag, flush=True)
                continue
            seed = zlib.crc32(("var|%s|%s|%d" % (args.card, label, s)).encode()) % 900000 + 1000
            print("[%d/%d] %s  %s" % (i, len(variants), tag, text[:60]), flush=True)
            try:
                pid = G.post(G.build(args.recipe, args.card, seed, subject_override=text))
                outs = G.wait(pid)
                imgs = outs.get("9", {}).get("images", [])
                if not imgs:
                    print("  FAIL", flush=True)
                    continue
                src = os.path.join(COMFY_OUT, imgs[0]["filename"])
                for _ in range(40):
                    if os.path.exists(src) and os.path.getsize(src) > 1000:
                        break
                    time.sleep(0.5)
                im = Image.open(src).convert("RGB")
                im.save(raw)
                G.grade(im).save(raw.replace(".png", "_g.png"))
            except Exception as e:
                print("  ERR", e, flush=True)
    print("完成，用时 %.1f 分 → %s" % ((time.time() - t0) / 60, out_dir), flush=True)


if __name__ == "__main__":
    main()

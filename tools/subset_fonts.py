"""
字体子集化工具
--------------------------------------------------
用途：把 assets/fonts/source/ 里的原始 Noto 字体，按游戏实际用到的字符
      裁剪成小字体，输出到 assets/fonts/ 供游戏直接使用。

什么时候要重新跑：
  1. 改动/新增了剧情文案、卡名、状态名等
  2. 加了一门语言
  3. 换了字体

用法：
  python tools/subset_fonts.py

依赖：
  pip install fonttools

注意：
  - source/ 里的字体不进 git（太大），需要时从 Google Fonts 下载：
      Noto Serif CJK SC : https://fonts.google.com/noto/specimen/Noto+Serif+SC
      Noto Sans SC      : https://fonts.google.com/noto/specimen/Noto+Sans+SC
  - 子集化后如果游戏里出现「方块字」，说明有字符没被收集到，
    检查是不是从外部文件/数据库动态读进来的文本。
"""
import os
import re
import glob
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = os.path.join(ROOT, "assets", "fonts")
SRC_DIR = os.path.join(FONT_DIR, "source")
CHARSET = os.path.join(FONT_DIR, "_charset.txt")

FONTS = [
    "NotoSerifCJKsc-Regular.otf",
    "NotoSansSC-Regular.otf",
]

# 即便脚本里没出现，也一定要保留的符号
EXTRA = (
    "".join(chr(c) for c in range(0x20, 0x7F))
    + "，。！？：；、「」『』（）《》【】—…·～¥％＋－×÷=①②③④⑤⑥⑦⑧⑨⑩"
    + "〇一二三四五六七八九十百千万亿零"
    + "▲▼▶◀★☆●○◆◇■□▲△▽"
)


def collect_charset() -> str:
    chars = set(EXTRA)
    for path in glob.glob(os.path.join(ROOT, "scripts", "*.gd")):
        text = open(path, encoding="utf-8").read()
        for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', text):
            chars |= set(m.group(1))
    for pattern in ("*.godot", os.path.join("scenes", "*.tscn")):
        for path in glob.glob(os.path.join(ROOT, pattern)):
            text = open(path, encoding="utf-8", errors="ignore").read()
            chars |= set(text)
    chars = {c for c in chars if ord(c) >= 0x20}
    return "".join(sorted(chars))


def main() -> int:
    if not os.path.isdir(SRC_DIR):
        print("找不到 assets/fonts/source/，请先把原始字体放进去")
        return 1
    charset = collect_charset()
    with open(CHARSET, "w", encoding="utf-8") as fh:
        fh.write(charset)
    print("字符集: %d 个字符（其中汉字 %d）" % (
        len(charset), len([c for c in charset if "\u4e00" <= c <= "\u9fff"])))

    for name in FONTS:
        src = os.path.join(SRC_DIR, name)
        dst = os.path.join(FONT_DIR, name)
        if not os.path.exists(src):
            print("跳过（缺源文件）:", name)
            continue
        subprocess.run([
            sys.executable, "-m", "fontTools.subset", src,
            "--text-file=" + CHARSET,
            "--output-file=" + dst,
            "--layout-features=*",
            "--glyph-names", "--symbol-cmap", "--legacy-cmap",
            "--notdef-glyph", "--notdef-outline", "--recommended-glyphs",
            "--name-IDs=*", "--name-legacy", "--name-languages=*",
        ], check=True)
        size = os.path.getsize(dst) / 1024 / 1024
        print("  %-32s %.2f MB" % (name, size))

    print("完成。回 Godot 里它会自动重新导入。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Синхронизация Noto Lottie + unicode в client/assets/emojis/.

Источник имён — прежний список из pubspec /tmp/emoji_names.txt или
assets/emojis/lottie/*.json. Каталог метаданных магазина остаётся на бэкенде.
"""

from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PKG_LOTTIE = Path.home() / '.pub-cache/hosted/pub.dev'
EMOJI_G = None


def find_package_lottie() -> Path:
    global EMOJI_G
    cands = sorted(PKG_LOTTIE.glob('animated_emoji-*'))
    if not cands:
        raise SystemExit('animated_emoji package not found in pub-cache')
    pkg = cands[-1]
    EMOJI_G = pkg / 'lib/emojis.g.dart'
    return pkg / 'lib/lottie'


def main() -> None:
    src = find_package_lottie()
    dest = ROOT / 'assets/emojis/lottie'
    dest.mkdir(parents=True, exist_ok=True)

    names_file = Path('/tmp/emoji_names.txt')
    if names_file.exists():
        names = [n for n in names_file.read_text().splitlines() if n]
    else:
        names = sorted(p.stem for p in dest.glob('*.json'))

    for n in names:
        f = src / f'{n}.json'
        if f.exists():
            shutil.copy2(f, dest / f'{n}.json')

    g = EMOJI_G.read_text()
    pairs = re.findall(
        r"Animated(?:Toned)?EmojiData\(\s*'([0-9a-fA-F_]+)',\s*name:\s*'([A-Za-z0-9_]+)'",
        g,
    )
    name_to_id = {name: eid for eid, name in pairs}

    def to_unicode(eid: str) -> str:
        return ''.join(chr(int(p, 16)) for p in eid.split('_'))

    mapping = {}
    for n in names:
        eid = name_to_id.get(n)
        if eid:
            mapping[n] = to_unicode(eid)

    (ROOT / 'assets/emojis/unicode.json').write_text(
        json.dumps(mapping, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    static_dir = ROOT / 'assets/emojis/static'
    static_dir.mkdir(parents=True, exist_ok=True)
    for n, u in mapping.items():
        (static_dir / f'{n}.txt').write_text(u, encoding='utf-8')

    keys = sorted(mapping)
    lines = [
        '// GENERATED — do not edit by hand.',
        '// ignore_for_file: public_member_api_docs',
        '',
        '/// Unicode fallbacks for bundled animated emoji assets.',
        'const Map<String, String> kBundledEmojiUnicode = {',
    ]
    for k in keys:
        v = mapping[k].replace('\\', '\\\\').replace("'", "\\'")
        lines.append(f"  '{k}': '{v}',")
    lines += [
        '};',
        '',
        '/// Asset directory for Noto Lottie JSON files.',
        "const String kBundledEmojiLottieDir = 'assets/emojis/lottie';",
        '',
        'String bundledEmojiLottieAsset(String animatedName) =>',
        "    '$kBundledEmojiLottieDir/$animatedName.json';",
        '',
        'bool hasBundledEmojiLottie(String animatedName) =>',
        '    kBundledEmojiUnicode.containsKey(animatedName);',
        '',
    ]
    (ROOT / 'lib/shop/emoji_asset_catalog.dart').write_text(
        '\n'.join(lines) + '\n', encoding='utf-8'
    )
    print(f'synced {len(mapping)} emojis → assets/emojis/')


if __name__ == '__main__':
    main()

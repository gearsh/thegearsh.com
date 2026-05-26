#!/usr/bin/env python3
"""Patch showcase artist hourlyRate and solo portrait image paths."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

VERIFIED_RATES = {
    "tyla": 15000000,
    "black-coffee": 5500000,
    "shimza": 350000,
    "kabza-de-small": 300000,
    "cassper-nyovest": 207000,
    "nasty-c": 100000,
    "kwesta": 85000,
    "dj-maphorisa": 75000,
    "sho-madjozi": 70000,
    "dj-zinhle": 70000,
    "king-monada": 50000,
    "prince-kaybee": 50000,
    "a-reece": 50000,
    "focalistic": 30000,
    "master-kg": 120000,
    "uncle-waffles": 85000,
    "emtee": 65000,
    "blxckie": 55000,
    "sjava": 75000,
    "makhadzi": 80000,
    "the-kiffness": 45000,
    "lloyiso": 40000,
    "sun-el-musician": 55000,
    "kamo-mphela": 45000,
    "big-zulu": 55000,
    "shekhinah": 65000,
    "elaine": 55000,
    "nomcebo-zikode": 90000,
    "kelly-khumalo": 75000,
    "benjamin-dube": 85000,
    "joyous-celebration": 65000,
    "seether": 350000,
    "die-antwoord": 250000,
    "yung-swiss": 35000,
    "rixelton": 2000,
    "zj90": 3500,
    "empress-ngqama": 4500,
    "dripmaker": 3500,
    "yde": 3000,
    "scotts-maphuma": 2500,
}

SOLO_IMAGES = {
    "kabza-de-small": "assets/images/artists/P9-Kabza-de-Small.webp",
    "cassper-nyovest": "assets/images/artists/cassper.png",
    "nasty-c": "assets/images/artists/nastyc.png",
    "sho-madjozi": "assets/images/artists/sho.png",
    "dj-zinhle": "assets/images/artists/zinhle_dj.png",
    "prince-kaybee": "assets/images/artists/majorl.png",
    "king-monada": "assets/images/artists/game.png",
    "emtee": "assets/images/artists/emtee.webp",
}


def tier_rate(mastery_hours: int) -> int:
    if mastery_hours >= 10000:
        return 500000
    if mastery_hours >= 7500:
        return 150000
    if mastery_hours >= 5000:
        return 75000
    if mastery_hours >= 3000:
        return 45000
    if mastery_hours >= 1000:
        return 25000
    return 12000


def patch_file(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(
        r"(username: '([^']+)'[\s\S]*?masteryHours: (\d+)[\s\S]*?hourlyRate: )(\d+)",
        re.MULTILINE,
    )

    updated = 0

    def repl(match: re.Match) -> str:
        nonlocal updated
        username = match.group(2)
        hours = int(match.group(3))
        rate = VERIFIED_RATES.get(username, tier_rate(hours))
        updated += 1
        return f"{match.group(1)}{rate}"

    text = pattern.sub(repl, text)

    for username, image in SOLO_IMAGES.items():
        text, count = re.subn(
            rf"(username: '{re.escape(username)}'[\s\S]*?image: ')[^']*(')",
            rf"\1{image}\2",
            text,
            count=1,
        )
        if count:
            updated += count

    path.write_text(text, encoding="utf-8")
    return updated


def main() -> None:
    targets = [
        ROOT / "functions" / "api" / "sa-showcase-data.js",
        ROOT / "web" / "sa-showcase-data.js",
    ]
    for target in targets:
        if not target.exists():
            print(f"skip missing {target}")
            continue
        count = patch_file(target)
        print(f"updated rates in {count} artists -> {target}")


if __name__ == "__main__":
    main()

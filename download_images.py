#!/usr/bin/env python3
"""
Artist image downloader with direct image URLs
This script will download artist images from available sources
"""

import os
import requests
import time
from pathlib import Path
from PIL import Image
from io import BytesIO
import shutil

# Direct image sources for artists (artist name -> image URL)
IMAGE_SOURCES = {
    "tyla.jpg": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/Tyla_%28singer%29.png/220px-Tyla_%28singer%29.png",
    "makhadzi.jpg": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Makhadzi_%28cropped%29.jpg/220px-Makhadzi_%28cropped%29.jpg",
    "masterkg.jpg": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Master_KG_by_Albert_Gonzalez.jpg/220px-Master_KG_by_Albert_Gonzalez.jpg",
    "lloyiso.jpg": "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/LLOYISO_BET_Experience.jpg/220px-LLOYISO_BET_Experience.jpg",
    "sjava.jpg": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Sjava_%282017%29.jpg/200px-Sjava_%282017%29.jpg",
    "amapiano": "https://media.graphassets.com/VfuQKC3nSMCK7VBm5bOb",
    "nastyc.jpg": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Nasty_C_at_MOBO_Awards_2019.png/220px-Nasty_C_at_MOBO_Awards_2019.png",
    "kellykhumalo.jpg": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Kelly_Khumalo_%282019%29.jpg/220px-Kelly_Khumalo_%282019%29.jpg",
    "djzinhle.jpg": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/DJ_Zinhle_%28cropped%29.jpg/220px-DJ_Zinhle_%28cropped%29.jpg",
    "elaine.jpg": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/Elaine_Akinsooto.jpg/220px-Elaine_Akinsooto.jpg",
}

ARTISTS_DIR = Path("assets/images/artists")
ARTISTS_DIR.mkdir(parents=True, exist_ok=True)

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}

def download_and_resize(url, filename, size=400):
    """Download image from URL and resize to 400x400"""
    try:
        print(f"  Downloading from: {url[:50]}...")
        response = requests.get(url, headers=HEADERS, timeout=15)
        response.raise_for_status()

        # Open image
        img = Image.open(BytesIO(response.content))

        # Convert to RGB if needed
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'RGBA':
                background.paste(img, mask=img.split()[-1])
            else:
                background.paste(img)
            img = background

        # Resize to 400x400
        img = img.resize((size, size), Image.Resampling.LANCZOS)

        filepath = ARTISTS_DIR / filename

        # Determine format from extension
        ext = filename.split('.')[-1].lower()
        if ext == 'webp':
            img.save(filepath, 'WEBP', quality=90)
        else:
            img.save(filepath, 'JPEG' if ext == 'jpg' else 'PNG', quality=90)

        print(f"  ✅ Saved: {filename}")
        return True
    except Exception as e:
        print(f"  ❌ Error: {str(e)}")
        return False

def create_placeholder(filename, artist_name):
    """Create a placeholder image if download fails"""
    try:
        # Create simple colored placeholder
        img = Image.new('RGB', (400, 400), color=(70, 130, 180))

        filepath = ARTISTS_DIR / filename
        img.save(filepath, 'JPEG', quality=90)
        print(f"  📍 Created placeholder: {filename}")
        return True
    except Exception as e:
        print(f"  ❌ Placeholder failed: {str(e)}")
        return False

def main():
    print("=" * 70)
    print("🎵 GEARSH ARTIST IMAGE DOWNLOADER")
    print("=" * 70)
    print(f"\n📁 Target: {ARTISTS_DIR.absolute()}\n")

    # Check what's already there
    existing = list(ARTISTS_DIR.glob("*"))
    print(f"📊 Found {len(existing)} existing images\n")

    downloaded = 0
    failed = 0

    for filename, url in IMAGE_SOURCES.items():
        filepath = ARTISTS_DIR / filename

        if filepath.exists():
            print(f"⏭️  {filename} - already exists")
            continue

        print(f"\n📥 {filename}")

        if download_and_resize(url, filename):
            downloaded += 1
            time.sleep(1)  # Rate limiting
        else:
            print(f"   Trying placeholder...")
            if create_placeholder(filename, filename.replace('.jpg', '')):
                failed += 1
            else:
                failed += 1

    print("\n" + "=" * 70)
    print(f"✅ Downloaded: {downloaded} images")
    print(f"❌ Failed/Placeholders: {failed} images")
    print("=" * 70)
    print("\n📌 FOR REMAINING IMAGES:")
    print("   1. Run: search_artist_images.bat")
    print("   2. Manually download good quality images")
    print("   3. Save with correct filenames to: assets/images/artists/")
    print("=" * 70)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")


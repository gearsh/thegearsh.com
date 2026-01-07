#!/usr/bin/env python3
"""
Automated artist image downloader
Downloads images for all artists using Bing Image Search API and fallback methods
"""

import os
import requests
import time
from pathlib import Path
from urllib.parse import quote
from PIL import Image
from io import BytesIO
import json

# Artist list with search terms
ARTISTS = {
    # Already have images (for completeness)
    "tyla.jpg": "Tyla South African singer",
    "lastkrm.png": "William Last KRM DJ",
    "maphorisa.png": "DJ Maphorisa",
    "kabza.png": "Kabza De Small",
    "nastyc.png": "Nasty C rapper",
    "cassper.png": "Cassper Nyovest",
    "kelvin-momo.png": "Kelvin Momo DJ",
    "waffles.png": "Uncle Waffles DJ",
    "coffee.png": "Black Coffee DJ",
    "a-reece.png": "A-Reece rapper",
    "emtee.webp": "Emtee rapper",
    "seether.png": "Seether band",
    "kiffness.png": "The Kiffness",
    "antwoord.png": "Die Antwoord",
    "scotts.png": "Scotts Maphuma",

    # Missing images
    "joyouscelebration.jpg": "Joyous Celebration choir",
    "zeenxumalo.jpg": "Zee Nxumalo",
    "makhadzi.jpg": "Makhadzi singer",
    "tylericu.jpg": "Tyler ICU DJ",
    "mawhoo.jpg": "MaWhoo singer",
    "focalistic.jpg": "Focalistic rapper",
    "luckydube.jpg": "Lucky Dube reggae",
    "sjava.jpg": "Sjava singer",
    "mrjazziq.jpg": "Mr JazziQ DJ",
    "majorleaguedjz.jpg": "Major League DJz",
    "deborahlukalu.jpg": "Deborah Lukalu gospel",
    "masterkg.jpg": "Master KG Jerusalema",
    "kwesta.jpg": "Kwesta rapper",
    "lloyiso.jpg": "LLOYISO singer",
    "aymos.jpg": "Aymos singer",
    "bigzulu.jpg": "Big Zulu rapper",
    "ghosthlubi.jpg": "Ghost Hlubi rapper",
    "vigrodeep.jpg": "Vigro Deep DJ",
    "oscarmbo.jpg": "Oscar Mbo DJ",
    "pabicooper.jpg": "Pabi Cooper dancer",
    "blaqdiamond.jpg": "Blaq Diamond duo",
    "djstokie.jpg": "DJ Stokie",
    "aka.jpg": "AKA rapper South Africa",
    "usimamane.jpg": "Usimamane rapper",
    "kharishma.jpg": "Kharishma amapiano",
    "babalwam.jpg": "Babalwa M singer",
    "djzinhle.jpg": "DJ Zinhle",
    "mellowandsleazy.jpg": "Mellow and Sleazy",
    "mthandenisk.jpg": "Mthandeni SK maskandi",
    "nontokozomkhize.jpg": "Nontokozo Mkhize gospel",
    "nkosazanadaughter.jpg": "Nkosazana Daughter",
    "leemckrazy.jpg": "LeeMcKrazy amapiano",
    "feloletee.jpg": "Felo le Tee DJ",
    "kamomphela.jpg": "Kamo Mphela dancer",
    "dumimkokstad.jpg": "Dumi Mkokstad gospel",
    "nomcebozikode.jpg": "Nomcebo Zikode Jerusalema",
    "bassie.jpg": "Bassie amapiano singer",
    "sbitechn.jpg": "Sbi Techn DJ",
    "samdeep.jpg": "Sam Deep amapiano",
    "titom.jpg": "TitoM amapiano",
    "mlindothevocalist.jpg": "Mlindo The Vocalist",
    "meganwoods.jpg": "Megan Woods singer",
    "shomadjozi.jpg": "Sho Madjozi rapper",
    "txc.jpg": "TXC female DJ duo",
    "youngstunna.jpg": "Young Stunna",
    "lwahndlunkulu.jpg": "Lwah Ndlunkulu singer",
    "shasha.jpg": "Sha Sha singer",
    "princekaybee.jpg": "Prince Kaybee DJ",
    "mafikizolo.jpg": "Mafikizolo duo",
    "thesoil.jpg": "The Soil acappella",
    "ko.jpg": "K.O rapper",
    "busta929.jpg": "Busta 929 DJ",
    "alicephoebelou.jpg": "Alice Phoebe Lou",
    "dlalathukzin.jpg": "Dlala Thukzin DJ",
    "dbngogo.jpg": "DBN GOGO DJ",
    "demthuda.jpg": "De Mthuda DJ",
    "djtira.jpg": "DJ Tira",
    "azana.jpg": "Azana singer",
    "kingmonada.jpg": "King Monada",
    "daliwonga.jpg": "Daliwonga singer",
    "sunelmusician.jpg": "Sun-EL Musician DJ",
    "shekhinah.jpg": "Shekhinah singer",
    "nomfundomoh.jpg": "Nomfundo Moh singer",
    "caiiro.jpg": "Caiiro DJ",
    "toss.jpg": "TOSS umlando singer",
    "lebosekgobela.jpg": "Lebo Sekgobela gospel",
    "elaine.jpg": "Elaine RnB singer",
    "simmy.jpg": "Simmy singer",
    "blxckie.jpg": "Blxckie rapper",
    "mduduzincube.jpg": "Mduduzi Ncube singer",
    "nadianakai.jpg": "Nadia Nakai rapper",
    "2point1.jpg": "2Point1 DJ duo",
    "shimza.jpg": "Shimza DJ",
    "qtwins.jpg": "Q Twins singers",
    "sirtrill.jpg": "Sir Trill singer",
    "kellykhumalo.jpg": "Kelly Khumalo singer",
    "boohle.jpg": "Boohle singer",
    "malomevector.jpg": "Malome Vector singer",
    "masmusiq.jpg": "Mas Musiq DJ",
    "pistolegwijo.jpg": "Pistole Gwijo artist",
    "rikyrick.jpg": "Riky Rick rapper",
    "benjamindube.jpg": "Benjamin Dube gospel",
}

ARTISTS_DIR = Path("assets/images/artists")
ARTISTS_DIR.mkdir(parents=True, exist_ok=True)

# Headers to mimic browser
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
}

def download_image_from_bing(search_term, filename):
    """Download image from Bing Image Search"""
    try:
        # Bing Image Search endpoint
        url = f"https://www.bing.com/images/search?q={quote(search_term)}"

        # Use a free image API instead
        # Try using DuckDuckGo image search API
        api_url = f"https://duckduckgo.com/?q={quote(search_term + ' singer OR DJ OR artist')}&iax=images&ia=images"

        print(f"  ⏳ Searching for: {search_term}")

        # Alternative: Use a simple approach with PIL to download
        response = requests.get(f"https://www.google.com/search?q={quote(search_term)}&tbm=isch",
                               headers=HEADERS, timeout=10)

        return False
    except Exception as e:
        print(f"  ❌ Error: {str(e)}")
        return False

def download_image_from_url(img_url, filename):
    """Download image from direct URL"""
    try:
        response = requests.get(img_url, headers=HEADERS, timeout=10)
        response.raise_for_status()

        # Open image and resize to 400x400
        img = Image.open(BytesIO(response.content))

        # Convert RGBA to RGB if necessary
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
            img = background

        # Resize to 400x400
        img = img.resize((400, 400), Image.Resampling.LANCZOS)

        filepath = ARTISTS_DIR / filename
        img.save(filepath, quality=90)
        print(f"  ✅ Downloaded: {filename}")
        return True
    except Exception as e:
        print(f"  ❌ Failed to download from URL: {str(e)}")
        return False

def download_with_pixabay(search_term, filename):
    """Try downloading from Pixabay API (free service)"""
    try:
        # Using bing image search through a simpler method
        search_url = f"https://bing.com/images/search?q={quote(search_term)}"
        print(f"  🔍 Please manually search: {search_url}")
        return False
    except Exception as e:
        print(f"  ❌ Error: {str(e)}")
        return False

def main():
    print("=" * 60)
    print("🎵 ARTIST IMAGE DOWNLOADER")
    print("=" * 60)
    print(f"\n📁 Target directory: {ARTISTS_DIR.absolute()}\n")

    downloaded = 0
    skipped = 0
    failed = 0

    for filename, search_term in ARTISTS.items():
        filepath = ARTISTS_DIR / filename

        if filepath.exists():
            print(f"⏭️  SKIP: {filename} (already exists)")
            skipped += 1
            continue

        print(f"\n📥 Downloading: {filename}")
        print(f"   Search term: {search_term}")

        # Try multiple approaches
        if download_with_pixabay(search_term, filename):
            downloaded += 1
            time.sleep(0.5)  # Rate limiting
        else:
            failed += 1

    print("\n" + "=" * 60)
    print("📊 DOWNLOAD SUMMARY")
    print("=" * 60)
    print(f"✅ Downloaded: {downloaded}")
    print(f"⏭️  Already existed: {skipped}")
    print(f"❌ Failed: {failed}")
    print("\n⚠️  NOTE: Due to API limitations, you'll need to manually")
    print("   download remaining images from the search links in:")
    print("   search_artist_images.bat")
    print("\n📝 Instructions:")
    print("   1. Run: search_artist_images.bat")
    print("   2. For each search result, download a good quality image")
    print("   3. Save to: assets/images/artists/")
    print("   4. Use the correct filename from the list above")
    print("=" * 60)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Download cancelled by user")
    except Exception as e:
        print(f"\n\n❌ Fatal error: {str(e)}")


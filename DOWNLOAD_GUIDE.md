# 🎵 Artist Images Download Guide

## Quick Start

You have 3 ways to download the remaining artist images:

### Option 1: Interactive Web Interface (Recommended)
1. Open `artist_downloader.html` in your browser
2. Search or browse through all 100 artists
3. Click "🔍 Search" to find images
4. Download and save with the correct filename

### Option 2: Batch Script with Pause
1. Run: `search_artist_images.bat`
2. Browser tabs will open in batches
3. Download images between batches
4. Save to: `assets/images/artists/`

### Option 3: PowerShell Downloader
```powershell
.\Download-ArtistImages.ps1
```

## Required Image Specifications

- **Size**: 400x400 pixels (square preferred)
- **Format**: JPG or PNG
- **Quality**: High quality, recent photos preferred
- **Save Location**: `assets/images/artists/`

## Complete Filename List

### ✅ Already Have Images (15)
```
tyla.jpg
lastkrm.png
maphorisa.png
kabza.png
nastyc.png
cassper.png
kelvin-momo.png
waffles.png
coffee.png
a-reece.png
emtee.webp
seether.png
kiffness.png
antwoord.png
scotts.png
```

### ❌ Still Need Images (85)
```
joyouscelebration.jpg      zeenxumalo.jpg             makhadzi.jpg
tylericu.jpg               mawhoo.jpg                 focalistic.jpg
luckydube.jpg              sjava.jpg                  mrjazziq.jpg
majorleaguedjz.jpg         deborahlukalu.jpg          masterkg.jpg
kwesta.jpg                 lloyiso.jpg                aymos.jpg
bigzulu.jpg                ghosthlubi.jpg             vigrodeep.jpg
oscarmbo.jpg               pabicooper.jpg             blaqdiamond.jpg
djstokie.jpg               aka.jpg                    usimamane.jpg
kharishma.jpg              babalwam.jpg               djzinhle.jpg
mellowandsleazy.jpg        mthandenisk.jpg            nontokozomkhize.jpg
nkosazanadaughter.jpg      leemckrazy.jpg             feloletee.jpg
kamomphela.jpg             dumimkokstad.jpg           nomcebozikode.jpg
bassie.jpg                 sbitechn.jpg               samdeep.jpg
titom.jpg                  mlindothevocalist.jpg      meganwoods.jpg
shomadjozi.jpg             txc.jpg                    youngstunna.jpg
lwahndlunkulu.jpg          shasha.jpg                 princekaybee.jpg
mafikizolo.jpg             thesoil.jpg                ko.jpg
busta929.jpg               dlalathukzin.jpg           dbngogo.jpg
demthuda.jpg               djtira.jpg                 azana.jpg
kingmonada.jpg             daliwonga.jpg              sunelmusician.jpg
shekhinah.jpg              nomfundomoh.jpg            caiiro.jpg
toss.jpg                   lebosekgobela.jpg          elaine.jpg
simmy.jpg                  blxckie.jpg                mduduzincube.jpg
nadianakai.jpg             2point1.jpg                
shimza.jpg                 qtwins.jpg                 sirtrill.jpg
kellykhumalo.jpg           boohle.jpg                 malomevector.jpg
masmusiq.jpg               pistolegwijo.jpg           rikyrick.jpg
benjamindube.jpg           alicephoebelou.jpg
```

## Image Sources

### Recommended Sources
- **Google Images**: Good for recent promo photos
- **Instagram**: Official artist accounts
- **Wikipedia**: High quality press photos
- **Spotify/Apple Music**: Artist profile images
- **Official Websites**: Artist management pages

## Manual Download Steps

1. **Search**: Click search button to find the artist
2. **Select**: Choose a good quality, recent photo
3. **Download**: Right-click → "Save image as..."
4. **Rename**: Use the exact filename from the list
5. **Save**: Place in `assets/images/artists/`

## Batch Download Scripts Included

### search_artist_images.bat
- Opens 80-100 Google Image Search tabs
- Organized in 9 batches with pauses between
- Instructions printed for manual download

### Download-ArtistImages.ps1
- PowerShell script
- Attempts automatic downloads from reliable sources
- Falls back to manual download instructions

## File Structure
```
assets/
└── images/
    └── artists/
        ├── tyla.jpg
        ├── makhadzi.jpg
        ├── masterkg.jpg
        └── ... (all 100 artist images)
```

## Notes

- For memorial artists (Lucky Dube, AKA, Riky Rick), use respectful, iconic photos
- Use royalty-free or official press images when possible
- For production deployment, consider licensing official photographs
- Images will improve app's visual appeal significantly

## Troubleshooting

**Script won't run?**
- Check that PowerShell execution policy allows scripts
- Use Command Prompt instead if needed
- Or use the HTML interface (browser-based)

**Can't find good images?**
- Try searching artist + "official photo"
- Check artist's official social media
- Use music platform artist pages
- Try reverse image search

**Images not showing in app?**
- Verify filenames match exactly (case-sensitive)
- Check images are saved in correct directory
- Ensure image format is JPG or PNG
- Rebuild app: `flutter run` or `flutter build`

## Next Steps

1. Choose your download method above
2. Download 85 remaining artist images
3. Save with correct filenames
4. Verify all images in `assets/images/artists/`
5. Rebuild the Flutter app
6. Test artist pages load with images

Good luck! 🎶


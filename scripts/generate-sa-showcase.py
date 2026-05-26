#!/usr/bin/env python3
"""Generate SA showcase artist data for Gearsh (100 claimable listings)."""

from pathlib import Path

FALLBACK = "assets/images/artists/artists.png"

# name, username, image file, category, genre label, location, mastery_hours
ARTISTS = [
    ("Black Coffee", "black-coffee", "coffee.png", "DJ", "House · International", "Johannesburg", 10000),
    ("Shimza", "shimza", "shimza.jpg", "DJ", "Afro House · Tembisa", "Tembisa", 10000),
    ("Kabza De Small", "kabza-de-small", "kabza.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 9800),
    ("DJ Maphorisa", "dj-maphorisa", "maphorisa.png", "Amapiano", "Amapiano · SA", "Soweto", 9200),
    ("Cassper Nyovest", "cassper-nyovest", "cassper.png", "Hip Hop", "Hip Hop · Joburg", "Johannesburg", 8800),
    ("Tyla", "tyla", "tyla.jpg", "Afropop", "Afropop · Global", "Johannesburg", 8500),
    ("Nasty C", "nasty-c", "nastyc.png", "Hip Hop", "Hip Hop · Durban", "Durban", 7800),
    ("Yung Swiss", "yung-swiss", "yung-swiss.jpg", "Hip Hop", "Hip Hop · Pretoria", "Pretoria", 6800),
    ("A-Reece", "a-reece", "a-reece.png", "Hip Hop", "Hip Hop · Pretoria", "Pretoria", 6200),
    ("Die Antwoord", "die-antwoord", "antwoord.png", "Rap-Rave", "Rap-Rave · Cape Town", "Cape Town", 7200),
    ("Master KG", "master-kg", "kg.png", "Afro House", "Afro House · Limpopo", "Limpopo", 7600),
    ("Uncle Waffles", "uncle-waffles", "waffles.png", "DJ", "DJ · Amapiano", "Swaziland / SA", 6500),
    ("Emtee", "emtee", "emtee.webp", "Hip Hop", "Hip Hop · SA", "Johannesburg", 5800),
    ("K.O", "ko", "artists.png", "Hip Hop", "Hip Hop · Soweto", "Soweto", 7400),
    ("Kwesta", "kwesta", "kwesta.png", "Hip Hop", "Hip Hop · Durban", "Durban", 7100),
    ("Nadia Nakai", "nadia-nakai", "artists.png", "Hip Hop", "Hip Hop · Pretoria", "Pretoria", 5900),
    ("Blxckie", "blxckie", "blxckie.png", "Hip Hop", "Hip Hop · Soweto", "Soweto", 5600),
    ("Focalistic", "focalistic", "focalistic.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 5400),
    ("Sho Madjozi", "sho-madjozi", "sho.png", "Gqom", "Gqom · Limpopo", "Limpopo", 5300),
    ("Kelvin Momo", "kelvin-momo", "kelvin-momo.png", "Amapiano", "Amapiano · SA", "South Africa", 5200),
    ("Tyler ICU", "tyler-icu", "icu.png", "Amapiano", "Amapiano · Johannesburg", "Johannesburg", 5100),
    ("Mr JazziQ", "mr-jazziq", "jazziq.png", "Amapiano", "Amapiano · Alexandra", "Alexandra", 5000),
    ("Major League DJz", "major-league-djz", "majorl.png", "Amapiano", "Amapiano · Johannesburg", "Johannesburg", 4900),
    ("Vigro Deep", "vigro-deep", "vigro.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 4800),
    ("Young Stunna", "young-stunna", "artists.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 4700),
    ("Sir Trill", "sir-trill", "artists.png", "Amapiano", "Amapiano · Johannesburg", "Johannesburg", 4600),
    ("Felo le Tee", "felo-le-tee", "felo-le-tee.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 4500),
    ("Makhadzi", "makhadzi", "makhadzi.png", "Afropop", "Afropop · Limpopo", "Limpopo", 4400),
    ("Sjava", "sjava", "sjava.png", "Afropop", "Afropop · Mpumalanga", "Mpumalanga", 4300),
    ("The Kiffness", "the-kiffness", "kiffness.png", "Electronic", "Music · Cape Town", "Cape Town", 4100),
    ("LLOYISO", "lloyiso", "lloyiso.png", "R&B", "R&B · East London", "East London", 4000),
    ("Seether", "seether", "seether.png", "Rock", "Rock · Pretoria", "Pretoria", 10000),
    ("Prince Kaybee", "prince-kaybee", "artists.png", "House", "House · Queenstown", "Queenstown", 3900),
    ("DJ Zinhle", "dj-zinhle", "zinhle_dj.png", "DJ", "DJ · Durban", "Durban", 3800),
    ("Sun-EL Musician", "sun-el-musician", "artists.png", "Afro House", "Afro House · Durban", "Durban", 3700),
    ("Caiiro", "caiiro", "caiiro.png", "Afro House", "Afro House · Pretoria", "Pretoria", 3600),
    ("Oscar Mbo", "oscar-mbo", "mbo.png", "Afro House", "Afro House · Pretoria", "Pretoria", 3500),
    ("De Mthuda", "de-mthuda", "artists.png", "Amapiano", "Amapiano · Durban", "Durban", 3400),
    ("Busta 929", "busta-929", "busta.png", "Amapiano", "Amapiano · Soweto", "Soweto", 3300),
    ("Mellow & Sleazy", "mellow-sleazy", "mellows.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 3200),
    ("MaWhoo", "mawhoo", "mawhoo.png", "Amapiano", "Amapiano · Durban", "Durban", 3100),
    ("Aymos", "aymos", "aymos.png", "Amapiano", "Amapiano · Alexandra", "Alexandra", 3000),
    ("Simmy", "simmy", "artists.png", "Amapiano", "Amapiano · Durban", "Durban", 2900),
    ("Kamo Mphela", "kamo-mphela", "kamo.png", "Dance", "Dance · Mamelodi", "Mamelodi", 2800),
    ("William Last KRM", "william-last-krm", "lastkrm.png", "Comedy", "Comedy · Music", "South Africa", 2800),
    ("Pabi Cooper", "pabi-cooper", "pabicooper.png", "Amapiano", "Amapiano · Soshanguve", "Soshanguve", 2700),
    ("Nkosazana Daughter", "nkosazana-daughter", "nkosazanadaughter.png", "Amapiano", "Amapiano · Durban", "Durban", 2600),
    ("Zee Nxumalo", "zee-nxumalo", "zee.png", "Amapiano", "Amapiano · KwaZulu-Natal", "KwaZulu-Natal", 2500),
    ("Kharishma", "kharishma", "kharishma.png", "Amapiano", "Amapiano · Limpopo", "Limpopo", 2400),
    ("Babalwa M", "babalwa-m", "babalwa.png", "Amapiano", "Amapiano · Eastern Cape", "Eastern Cape", 2300),
    ("DJ Stokie", "dj-stokie", "stokie.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 2200),
    ("Big Zulu", "big-zulu", "bigzulu.png", "Maskandi", "Maskandi · KZN", "KwaZulu-Natal", 2100),
    ("Usimamane", "usimamane", "usimamane.png", "Maskandi", "Maskandi · KZN", "KwaZulu-Natal", 2000),
    ("Joyous Celebration", "joyous-celebration", "joyous.png", "Gospel", "Gospel · SA", "South Africa", 1900),
    ("Blaq Diamond", "blaq-diamond", "blaq.png", "Afropop", "Afropop · Ladysmith", "Ladysmith", 1800),
    ("Elaine", "elaine", "artists.png", "R&B", "R&B · Pretoria", "Pretoria", 1700),
    ("Shekhinah", "shekhinah", "artists.png", "Pop", "Pop · Durban", "Durban", 1600),
    ("Nomfundo Moh", "nomfundo-moh", "artists.png", "Afropop", "Afropop · KwaZulu-Natal", "KwaZulu-Natal", 1500),
    ("Mduduzi Ncube", "mduduzi-ncube", "artists.png", "Maskandi", "Maskandi · KZN", "KwaZulu-Natal", 1400),
    ("King Monada", "king-monada", "artists.png", "Bolobedu", "Bolobedu · Limpopo", "Limpopo", 1300),
    ("Daliwonga", "daliwonga", "artists.png", "Amapiano", "Amapiano · Soweto", "Soweto", 1200),
    ("Azana", "azana", "artists.png", "Afropop", "Afropop · Durban", "Durban", 1100),
    ("TOSS", "toss", "artists.png", "Amapiano", "Amapiano · Soweto", "Soweto", 1050),
    ("LeeMcKrazy", "leemckrazy", "artists.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 1000),
    ("TitoM", "titom", "artists.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 950),
    ("Sam Deep", "sam-deep", "artists.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 900),
    ("Mlindo The Vocalist", "mlindo-the-vocalist", "artists.png", "Afropop", "Afropop · KZN", "KwaZulu-Natal", 850),
    ("Lwah Ndlunkulu", "lwah-ndlunkulu", "artists.png", "Afropop", "Afropop · Durban", "Durban", 800),
    ("Sha Sha", "sha-sha", "artists.png", "Amapiano", "Amapiano · Mutare / SA", "Mutare", 750),
    ("Mafikizolo", "mafikizolo", "artists.png", "Afropop", "Afropop · Johannesburg", "Johannesburg", 700),
    ("The Soil", "the-soil", "artists.png", "Acapella", "Acapella · Soweto", "Soweto", 650),
    ("Dlala Thukzin", "dlala-thukzin", "artists.png", "Gqom", "Gqom · Durban", "Durban", 600),
    ("DBN GOGO", "dbn-gogo", "artists.png", "Amapiano", "Amapiano · Durban", "Durban", 550),
    ("DJ Tira", "dj-tira", "artists.png", "Gqom", "Gqom · Durban", "Durban", 500),
    ("Nomcebo Zikode", "nomcebo-zikode", "artists.png", "Afropop", "Afropop · Hammarsdale", "Hammarsdale", 480),
    ("Kelly Khumalo", "kelly-khumalo", "artists.png", "Afropop", "Afropop · Johannesburg", "Johannesburg", 460),
    ("Boohle", "boohle", "boohle.png", "Amapiano", "Amapiano · Kimberley", "Kimberley", 440),
    ("Benjamin Dube", "benjamin-dube", "artists.png", "Gospel", "Gospel · Johannesburg", "Johannesburg", 420),
    ("Deborah Lukalu", "deborah-lukalu", "artists.png", "Gospel", "Gospel · Congo / SA", "Johannesburg", 400),
    ("Dumi Mkokstad", "dumi-mkokstad", "artists.png", "Gospel", "Gospel · KZN", "KwaZulu-Natal", 380),
    ("Lebo Sekgobela", "lebo-sekgobela", "artists.png", "Gospel", "Gospel · Limpopo", "Limpopo", 360),
    ("Q Twins", "q-twins", "artists.png", "Afropop", "Afropop · KZN", "KwaZulu-Natal", 340),
    ("Mas Musiq", "mas-musiq", "artists.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 320),
    ("2Point1", "2point1", "artists.png", "Amapiano", "Amapiano · Pretoria", "Pretoria", 300),
    ("Costa Titch", "costa-titch", "artists.png", "Hip Hop", "Hip Hop · Mpumalanga", "Mpumalanga", 280),
    ("AKA", "aka", "artists.png", "Hip Hop", "Hip Hop · Cape Town", "Cape Town", 8600),
    ("Riky Rick", "riky-rick", "artists.png", "Hip Hop", "Hip Hop · Durban", "Durban", 260),
    ("Malome Vector", "malome-vector", "artists.png", "Hip Hop", "Hip Hop · Free State", "Free State", 240),
    ("Lucky Dube", "lucky-dube", "artists.png", "Reggae", "Reggae · Johannesburg", "Johannesburg", 10000),
    ("Alice Phoebe Lou", "alice-phoebe-lou", "artists.png", "Folk", "Folk · Cape Town", "Cape Town", 220),
    ("TXC", "txc", "artists.png", "DJ", "DJ · Johannesburg", "Johannesburg", 200),
    ("Bassie", "bassie", "artists.png", "Amapiano", "Amapiano · Johannesburg", "Johannesburg", 180),
    ("Megan Woods", "megan-woods", "artists.png", "Pop", "Pop · Cape Town", "Cape Town", 160),
    ("Mthandeni SK", "mthandeni-sk", "artists.png", "Maskandi", "Maskandi · KZN", "KwaZulu-Natal", 140),
    ("ZJ90", "zj90", "ZJ90.jpg", "DJ", "House · Amapiano", "Johannesburg", 120),
    ("Rix Elton", "rixelton", "rixelton.jpg", "Amapiano DJ", "Amapiano DJ · Johannesburg", "Johannesburg", 50),
    ("Empress Ngqama", "empress-ngqama", "empress-ngqama.jpg", "Afro-Soul", "Afro-Soul · Reggae", "Eastern Cape", 95),
    ("Dripmaker", "dripmaker", "dripmaker.png", "Fashion", "Fashion · Thohoyandou", "Thohoyandou", 180),
    ("Y.D.E", "yde", "yde.png", "Hip Hop", "Hip Hop · Louis Trichardt", "Louis Trichardt", 0),
    ("Scotts Maphuma", "scotts-maphuma", "scotts.png", "Afropop", "Artist · SA", "South Africa", 40),
]

assert len(ARTISTS) == 100, f"Expected 100 artists, got {len(ARTISTS)}"

GENRE_SECTIONS = [
    ("amapiano", "Amapiano", "Log drums, soulful keys, and SA's biggest sound", "ti ti-piano"),
    ("hip-hop", "Hip Hop", "Bars, flow, and culture from Pretoria to Durban", "ti ti-microphone"),
    ("house", "House & Afro House", "From township clubs to global dance floors", "ti ti-vinyl"),
    ("afropop", "Afropop & R&B", "Melody, soul, and African pop excellence", "ti ti-heart"),
    ("gospel", "Gospel", "Praise, worship, and inspiration", "ti ti-pray"),
    ("maskandi", "Maskandi & Traditional", "Roots, culture, and storytelling", "ti ti-feather"),
    ("gqom", "Gqom & Dance", "Hard beats built for the dancefloor", "ti ti-bolt"),
    ("other", "More genres", "Rock, comedy, fashion, and beyond", "ti ti-stars"),
]

CATEGORY_TO_GENRE = {
    "Amapiano": "amapiano",
    "Amapiano DJ": "amapiano",
    "Hip Hop": "hip-hop",
    "Rap-Rave": "hip-hop",
    "DJ": "house",
    "House": "house",
    "Afro House": "house",
    "Afropop": "afropop",
    "R&B": "afropop",
    "Pop": "afropop",
    "Acapella": "afropop",
    "Gospel": "gospel",
    "Maskandi": "maskandi",
    "Bolobedu": "maskandi",
    "Gqom": "gqom",
    "Dance": "gqom",
    "Rock": "other",
    "Electronic": "other",
    "Comedy": "other",
    "Fashion": "other",
    "Folk": "other",
}


def resolve_genre_slug(category, genre_label):
    label = str(genre_label or "").lower()
    if "amapiano" in label:
        return "amapiano"
    if "hip hop" in label or "rap" in label:
        return "hip-hop"
    if "house" in label or "afro house" in label or label.startswith("dj"):
        return "house"
    if "gospel" in label:
        return "gospel"
    if "maskandi" in label or "bolobedu" in label:
        return "maskandi"
    if "gqom" in label or "dance" in label:
        return "gqom"
    if any(token in label for token in ("afropop", "r&b", "soul", "acapella", "pop")):
        return "afropop"
    return CATEGORY_TO_GENRE.get(category, "other")


def badge_for(hours):
    if hours >= 10000:
        return "Legend", "fb-feat", True
    if hours >= 5000:
        return "Expert", "fb-feat", False
    if hours >= 100:
        return "Rising", "fb-rise", False
    return "Listed", "fb-new", False


def js_string(value):
    return json_escape(str(value))


def json_escape(value):
    return value.replace("\\", "\\\\").replace("'", "\\'")


def hourly_rate(hours):
    if hours >= 10000:
        return 85000
    if hours >= 5000:
        return 45000
    if hours >= 1000:
        return 25000
    if hours >= 100:
        return 12000
    return 3500


lines = [
    "// 100 South African artists — listed for discovery, claimable later via claim-profile",
    "export const SA_SHOWCASE_ARTISTS = [",
]

for name, username, image_file, category, genre, location, hours in ARTISTS:
    badge, badge_class, large = badge_for(hours)
    genre_slug = resolve_genre_slug(category, genre)
    image = f"assets/images/artists/{image_file}" if image_file != FALLBACK else FALLBACK
    if not image_file.startswith("assets/"):
        image = f"assets/images/artists/{image_file}"
    bio = f"{name} — available to book on Gearsh. Claim this profile to manage bookings and payments."
    skills = [category]
    if "Hip Hop" in genre or category == "Hip Hop":
        skills = ["Hip Hop", "Rap", "Live Performance"]
    elif "Amapiano" in genre or category == "Amapiano":
        skills = ["Amapiano", "DJ", "Live Performance"]
    elif category == "DJ":
        skills = ["DJ", "House", "Live Performance"]
    else:
        skills = [category, "Live Performance"]

    lines.append("  {")
    lines.append(f"    name: '{js_string(name)}',")
    lines.append(f"    username: '{username}',")
    lines.append(f"    image: '{image}',")
    lines.append(f"    category: '{js_string(category)}',")
    lines.append(f"    genre: '{js_string(genre)}',")
    lines.append(f"    genreSlug: '{genre_slug}',")
    lines.append(f"    location: '{js_string(location)}',")
    lines.append("    country: 'South Africa',")
    lines.append(f"    masteryHours: {hours},")
    lines.append(f"    badge: '{badge}',")
    lines.append(f"    badgeClass: '{badge_class}',")
    if large:
        lines.append("    large: true,")
    lines.append(f"    hourlyRate: {hourly_rate(hours)},")
    lines.append(f"    bio: '{js_string(bio)}',")
    skills_js = ", ".join(f"'{js_string(s)}'" for s in skills)
    lines.append(f"    skills: [{skills_js}],")
    lines.append("  },")

lines.append("];")
lines.append("")
lines.append("export const GENRE_FEED_CATEGORIES = [")
lines.append("  {")
lines.append("    id: 'mastery-legends',")
lines.append("    title: 'Mastery legends',")
lines.append("    subtitle: 'Top artists — 10,000 hours of craft and countless stages',")
lines.append("    icon: 'ti ti-crown',")
lines.append("  },")
for slug, title, subtitle, icon in GENRE_SECTIONS:
    lines.append("  {")
    lines.append(f"    id: 'genre-{slug}',")
    lines.append(f"    title: '{js_string(title)}',")
    lines.append(f"    subtitle: '{js_string(subtitle)}',")
    lines.append(f"    icon: '{icon}',")
    lines.append("  },")
lines.append("];")
lines.append("")
lines.append("export function resolveArtistGenreSlug(category, genreLabel) {")
lines.append("  const label = String(genreLabel || '').toLowerCase();")
lines.append("  if (label.includes('amapiano')) return 'amapiano';")
lines.append("  if (label.includes('hip hop') || label.includes('rap')) return 'hip-hop';")
lines.append("  if (label.includes('house') || label.includes('afro house') || label.startsWith('dj')) return 'house';")
lines.append("  if (label.includes('gospel')) return 'gospel';")
lines.append("  if (label.includes('maskandi') || label.includes('bolobedu')) return 'maskandi';")
lines.append("  if (label.includes('gqom') || label.includes('dance')) return 'gqom';")
lines.append("  if (['afropop', 'r&b', 'soul', 'acapella', 'pop'].some(function(token) { return label.includes(token); })) return 'afropop';")
lines.append("  const map = {")
for cat, slug in sorted(CATEGORY_TO_GENRE.items()):
    lines.append(f"    '{js_string(cat)}': '{slug}',")
lines.append("  };")
lines.append("  return map[String(category || '')] || 'other';")
lines.append("}")
lines.append("")
lines.append("export function toMarketingShowcase(artist) {")
lines.append("  return {")
lines.append("    name: artist.name,")
lines.append("    username: artist.username,")
lines.append("    image: artist.image,")
lines.append("    genre: artist.genre,")
lines.append("    category: artist.category,")
lines.append("    genreSlug: artist.genreSlug,")
lines.append("    badge: artist.badge,")
lines.append("    badgeClass: artist.badgeClass,")
lines.append("    masteryHours: artist.masteryHours,")
lines.append("    large: artist.large || false,")
lines.append("  };")
lines.append("}")
lines.append("")
lines.append("export const SHOWCASE = SA_SHOWCASE_ARTISTS.map(toMarketingShowcase);")

out_api = Path("functions/api/sa-showcase-data.js")
out_web = Path("web/sa-showcase-data.js")

api_content = "\n".join(lines)
web_content = api_content.replace("export const SA_SHOWCASE_ARTISTS", "const SA_SHOWCASE_ARTISTS")
web_content = web_content.replace("export const GENRE_FEED_CATEGORIES", "var GENRE_FEED_CATEGORIES")
web_content = web_content.replace("export function resolveArtistGenreSlug", "function resolveArtistGenreSlug")
web_content = web_content.replace("export function toMarketingShowcase", "function toMarketingShowcase")
web_content = web_content.replace("export const SHOWCASE", "var SHOWCASE")
web_content = "// Auto-generated — 100 SA artists for Gearsh homepage\n" + web_content

out_api.write_text(api_content, encoding="utf-8")
out_web.write_text(web_content, encoding="utf-8")
print(f"Wrote {len(ARTISTS)} artists to {out_api} and {out_web}")

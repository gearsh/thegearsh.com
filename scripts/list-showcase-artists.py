import re
from pathlib import Path

lines = Path("web/sa-showcase-data.js").read_text(encoding="utf-8").splitlines()
block = "\n".join(lines[2:1608])  # SA_SHOWCASE_ARTISTS array only

# Split on artist object boundaries
chunks = re.split(r"\n  \},\n  \{", block)
artists = []
for i, chunk in enumerate(chunks):
    if i == 0:
        chunk = chunk.split("[", 1)[-1]
    if i == len(chunks) - 1:
        chunk = chunk.rsplit("]", 1)[0]
    chunk = "{" + chunk.strip().lstrip("{").rstrip("}").strip() + "}"

    def field(key):
        m = re.search(rf"{key}: '([^']*)'", chunk)
        return m.group(1) if m else ""

    def field_num(key):
        m = re.search(rf"{key}: (\d+)", chunk)
        return int(m.group(1)) if m else 0

    artists.append({
        "name": field("name"),
        "username": field("username"),
        "category": field("category"),
        "genre": field("genre"),
        "location": field("location"),
        "hours": field_num("masteryHours"),
    })

print(f"Total: {len(artists)}\n")

flags = {
    "AKA": "deceased (2023)",
    "Riky Rick": "deceased (2022)",
    "Costa Titch": "deceased (2023)",
    "Malome Vector": "deceased (2023)",
    "Lucky Dube": "deceased (2007) — legacy artist",
    "Die Antwoord": "controversial / not typical booking",
    "Alice Phoebe Lou": "indie — verify SA focus",
    "Seether": "rock band — verify booking fit",
}

for i, a in enumerate(artists):
    h = a["hours"]
    tier = "Legend" if h >= 10000 else "Expert" if h >= 5000 else "Rising" if h >= 100 else "New"
    flag = flags.get(a["name"], "")
    extra = f"  ⚠ {flag}" if flag else ""
    print(
        f"{i+1:3}. {a['name']:22} @{a['username']:22} "
        f"{a['category']:12} {a['genre']:28} {a['location']:16} {tier}{extra}"
    )

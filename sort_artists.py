import re

print("Starting sort script...")

# Read the file
with open('lib/data/gearsh_artists.dart', 'r', encoding='utf-8') as f:
    content = f.read()

print(f"File length: {len(content)} characters")

# Find the start of the artists list
list_start = content.find('const List<GearshArtist> gearshArtists = [')
if list_start == -1:
    print("Could not find artists list")
    exit(1)

print(f"Found list start at position {list_start}")

# Get the header (class definition)
header = content[:list_start]

# Get the list content (after the opening bracket)
list_content = content[list_start:]

# Split by "GearshArtist(" to get individual entries
parts = list_content.split('  GearshArtist(')
print(f"Found {len(parts) - 1} artist entries")

# First part is "const List<GearshArtist> gearshArtists = [\n"
list_header = parts[0]

# Remaining parts are artist entries
artist_entries = []
for i, part in enumerate(parts[1:], 1):
    # Add back the "  GearshArtist(" prefix
    entry = '  GearshArtist(' + part
    # Clean up - remove trailing ]; if it's the last entry
    if entry.rstrip().endswith('];'):
        entry = entry.rstrip()[:-2] + '\n'
    artist_entries.append(entry)

# Extract name for sorting
def get_name(entry):
    match = re.search(r"name: '([^']+)'", entry)
    return match.group(1) if match else "ZZZ"

# Sort entries by name (case-insensitive)
sorted_entries = sorted(artist_entries, key=lambda x: get_name(x).lower())

# Print sorted order
print("\nSorted order:")
for i, entry in enumerate(sorted_entries, 1):
    name = get_name(entry)
    print(f"{i}. {name}")

# Build the new content
new_content = header + list_header
for i, entry in enumerate(sorted_entries):
    new_content += entry
new_content = new_content.rstrip()
if not new_content.endswith('];'):
    new_content += '\n];'
new_content += '\n'

# Write back to file
with open('lib/data/gearsh_artists.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("\n✅ Artists sorted alphabetically!")


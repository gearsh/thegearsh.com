const fs = require('fs');

// Read the file
const content = fs.readFileSync('lib/data/gearsh_artists.dart', 'utf8');

// Find the class definition and list start
const classMatch = content.match(/^[\s\S]*?const List<GearshArtist> gearshArtists = \[/);
const header = classMatch[0];

// Find the helper functions at the end
const helperMatch = content.match(/\/\/ Helper function to get artist by ID[\s\S]*$/);
const helpers = helperMatch ? helperMatch[0] : '';

// Extract all GearshArtist entries
const listContent = content.slice(header.length);
const entriesEnd = listContent.indexOf('];');
const entriesStr = listContent.slice(0, entriesEnd);

// Split by GearshArtist( to get individual entries
const parts = entriesStr.split(/\n  GearshArtist\(/);
const entries = parts.slice(1).map(part => '  GearshArtist(' + part);

console.log(`Found ${entries.length} artist entries`);

// Extract name for sorting
function getName(entry) {
  const match = entry.match(/name: '([^']+)'/);
  return match ? match[1] : 'ZZZ';
}

// Sort entries by name (case-insensitive)
entries.sort((a, b) => {
  const nameA = getName(a).toLowerCase();
  const nameB = getName(b).toLowerCase();
  return nameA.localeCompare(nameB);
});

console.log('\nSorted order:');
entries.forEach((entry, i) => {
  console.log(`${i + 1}. ${getName(entry)}`);
});

// Build the new content
let newContent = header + '\n';
newContent += entries.join('\n');
newContent += '\n];\n\n';
newContent += helpers;

// Write back to file
fs.writeFileSync('lib/data/gearsh_artists.dart', newContent);

console.log('\n✅ Artists sorted alphabetically!');


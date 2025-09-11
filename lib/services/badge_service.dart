//The Gearsh App - lib/services/badge_service.dart

import '../models/badge.dart';

class BadgeService {
  static List<Badge> getBadges(int hoursEarned) {
    final List<Badge> badges = [];

    if (hoursEarned >= 500) {
      badges.add(badgeData["The Spark"]!);
    }
    if (hoursEarned >= 2000) {
      badges.add(badgeData["The Hustler"]!);
    }
    if (hoursEarned >= 4000) {
      badges.add(badgeData["The Flow"]!);
    }
    if (hoursEarned >= 6000) {
      badges.add(badgeData["The Vibe"]!);
    }
    if (hoursEarned >= 8000) {
      badges.add(badgeData["The Creator"]!);
    }
    if (hoursEarned >= 10000) {
      badges.add(badgeData["The Visionary"]!);
    }
    if (hoursEarned >= 12000) {
      badges.add(badgeData["King/Queen of Culture"]!);
    }

    return badges;
  }
}

final Map<String, Badge> badgeData = {
  "The Spark": Badge(
    name: "The Spark",
    description: "You've ignited your creative journey.",
    colorHex: "#FF0000",
    emoji: "🔥",
  ),
  "The Hustler": Badge(
    name: "The Hustler",
    description: "Grinding hard with 2K+ hours.",
    colorHex: "#FF7F00",
    emoji: "🚀",
  ),
  "The Flow": Badge(
    name: "The Flow",
    description: "You're in the zone.",
    colorHex: "#FFFF00",
    emoji: "🌊",
  ),
  "The Vibe": Badge(
    name: "The Vibe",
    description: "You're radiating creativity.",
    colorHex: "#00FF00",
    emoji: "🎶",
  ),
  "The Creator": Badge(
    name: "The Creator",
    description: "Master of your craft.",
    colorHex: "#0000FF",
    emoji: "🎨",
  ),
  "The Visionary": Badge(
    name: "The Visionary",
    description: "Shaping the culture.",
    colorHex: "#4B0082",
    emoji: "👁️",
  ),
  "King/Queen of Culture": Badge(
    name: "King/Queen of Culture",
    description: "The crown is yours.",
    colorHex: "#9400D3",
    emoji: "👑",
  ),
};

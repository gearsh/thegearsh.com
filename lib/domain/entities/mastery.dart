// Gearsh App - Domain Layer: Mastery System
// 10,000 Hours Mastery - Gamified artist progression

/// Mastery levels based on hours booked
enum MasteryLevel {
  newcomer,      // 0-99 hours
  rising,        // 100-499 hours
  established,   // 500-1999 hours
  professional,  // 2000-4999 hours
  expert,        // 5000-7499 hours
  master,        // 7500-9999 hours
  legend,        // 10000+ hours
}

/// Mastery information with computed properties
class MasteryInfo {
  final MasteryLevel level;
  final String title;
  final String icon;
  final int minHours;
  final int maxHours;
  final double progressToNext;

  const MasteryInfo({
    required this.level,
    required this.title,
    required this.icon,
    required this.minHours,
    required this.maxHours,
    required this.progressToNext,
  });

  /// Factory to create MasteryInfo from hours booked
  factory MasteryInfo.fromHours(int hoursBooked) {
    if (hoursBooked >= 10000) {
      return const MasteryInfo(
        level: MasteryLevel.legend,
        title: 'Legend',
        icon: '👑',
        minHours: 10000,
        maxHours: 10000,
        progressToNext: 1.0,
      );
    } else if (hoursBooked >= 7500) {
      return MasteryInfo(
        level: MasteryLevel.master,
        title: 'Master',
        icon: '🏆',
        minHours: 7500,
        maxHours: 9999,
        progressToNext: (hoursBooked - 7500) / 2500,
      );
    } else if (hoursBooked >= 5000) {
      return MasteryInfo(
        level: MasteryLevel.expert,
        title: 'Expert',
        icon: '⭐',
        minHours: 5000,
        maxHours: 7499,
        progressToNext: (hoursBooked - 5000) / 2500,
      );
    } else if (hoursBooked >= 2000) {
      return MasteryInfo(
        level: MasteryLevel.professional,
        title: 'Professional',
        icon: '💎',
        minHours: 2000,
        maxHours: 4999,
        progressToNext: (hoursBooked - 2000) / 3000,
      );
    } else if (hoursBooked >= 500) {
      return MasteryInfo(
        level: MasteryLevel.established,
        title: 'Established',
        icon: '🔥',
        minHours: 500,
        maxHours: 1999,
        progressToNext: (hoursBooked - 500) / 1500,
      );
    } else if (hoursBooked >= 100) {
      return MasteryInfo(
        level: MasteryLevel.rising,
        title: 'Rising',
        icon: '🚀',
        minHours: 100,
        maxHours: 499,
        progressToNext: (hoursBooked - 100) / 400,
      );
    } else {
      return MasteryInfo(
        level: MasteryLevel.newcomer,
        title: 'Newcomer',
        icon: '🌱',
        minHours: 0,
        maxHours: 99,
        progressToNext: hoursBooked / 100,
      );
    }
  }

  /// Hours remaining to reach 10,000 mastery
  static int hoursToMastery(int currentHours) =>
      (10000 - currentHours).clamp(0, 10000);

  /// Percentage progress to 10,000 hours (0.0 to 1.0)
  static double masteryProgress(int currentHours) =>
      (currentHours / 10000).clamp(0.0, 1.0);

  /// Check if Legend status achieved
  static bool isLegend(int hoursBooked) => hoursBooked >= 10000;

  @override
  String toString() => 'MasteryInfo($title, $icon, $minHours-$maxHours hours)';
}

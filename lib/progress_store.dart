import 'package:shared_preferences/shared_preferences.dart';
import 'levels.dart';

class Progress {
  final int highScore;
  final int bestStreak;
  final int unlockedLevels; // how many levels are playable (min 1)
  final List<int> stars; // best stars per level (0-3)

  const Progress({
    required this.highScore,
    required this.bestStreak,
    required this.unlockedLevels,
    required this.stars,
  });

  int get totalStars => stars.fold(0, (a, b) => a + b);
}

/// Saves progress on the device with shared_preferences.
class ProgressStore {
  static const _kHigh = 'highScore';
  static const _kStreak = 'bestStreak';
  static const _kUnlocked = 'unlockedLevels';
  static String _kStars(int i) => 'stars_$i';

  static Future<Progress> load() async {
    final p = await SharedPreferences.getInstance();
    return Progress(
      highScore: p.getInt(_kHigh) ?? 0,
      bestStreak: p.getInt(_kStreak) ?? 0,
      unlockedLevels: p.getInt(_kUnlocked) ?? 1,
      stars: List.generate(levels.length, (i) => p.getInt(_kStars(i)) ?? 0),
    );
  }

  static Future<void> recordLevel({
    required int levelIndex,
    required int stars,
    required int score,
    required int bestStreak,
  }) async {
    final p = await SharedPreferences.getInstance();

    if (stars > (p.getInt(_kStars(levelIndex)) ?? 0)) {
      await p.setInt(_kStars(levelIndex), stars);
    }
    if (score > (p.getInt(_kHigh) ?? 0)) await p.setInt(_kHigh, score);
    if (bestStreak > (p.getInt(_kStreak) ?? 0)) {
      await p.setInt(_kStreak, bestStreak);
    }

    final unlockTarget = (levelIndex + 2).clamp(1, levels.length);
    if (unlockTarget > (p.getInt(_kUnlocked) ?? 1)) {
      await p.setInt(_kUnlocked, unlockTarget);
    }
  }
}

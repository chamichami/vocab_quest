import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'levels.dart';
import 'user_service.dart';

class Progress {
  final int highScore;
  final int bestStreak;
  final int unlockedLevels;
  final List<int> stars;
  const Progress({
    required this.highScore,
    required this.bestStreak,
    required this.unlockedLevels,
    required this.stars,
  });

  factory Progress.empty() => Progress(
    highScore: 0,
    bestStreak: 0,
    unlockedLevels: 1,
    stars: List<int>.filled(levels.length, 0),
  );

  int get totalStars => stars.fold(0, (a, b) => a + b);
}

class ProgressStore {
  static DocumentReference<Map<String, dynamic>>? _doc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? null : UserService.userDoc(uid);
  }

  static List<int> _stars(Map<String, dynamic>? d) {
    final raw = (d?['stars'] as List?)?.map((e) => (e as num).toInt()).toList();
    final out = List<int>.filled(levels.length, 0);
    if (raw != null) {
      for (var i = 0; i < min(raw.length, out.length); i++) {
        out[i] = raw[i];
      }
    }
    return out;
  }

  static Future<Progress> load() async {
    final ref = _doc();
    if (ref == null) return Progress.empty();
    final d = (await ref.get()).data();
    if (d == null) return Progress.empty();
    return Progress(
      highScore: (d['highScore'] as num?)?.toInt() ?? 0,
      bestStreak: (d['bestStreak'] as num?)?.toInt() ?? 0,
      unlockedLevels: (d['unlockedLevels'] as num?)?.toInt() ?? 1,
      stars: _stars(d),
    );
  }

  static Future<void> recordLevel({
    required int levelIndex,
    required int stars,
    required int score,
    required int bestStreak,
  }) async {
    final ref = _doc();
    if (ref == null) return;

    final d = (await ref.get()).data();

    final starList = _stars(d);
    starList[levelIndex] = max(starList[levelIndex], stars);

    final highScore = max((d?['highScore'] as num?)?.toInt() ?? 0, score);
    final best = max((d?['bestStreak'] as num?)?.toInt() ?? 0, bestStreak);
    final unlocked = max(
      (d?['unlockedLevels'] as num?)?.toInt() ?? 1,
      min(levelIndex + 2, levels.length),
    );

    await ref.set({
      'highScore': highScore,
      'bestStreak': best,
      'unlockedLevels': unlocked,
      'stars': starList,
      'totalStars': starList.fold<int>(0, (a, b) => a + b),
    }, SetOptions(merge: true));
  }
}

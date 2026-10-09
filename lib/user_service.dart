import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsernameTakenException implements Exception {}

/// A player's public profile, stored in Firestore at users/{uid}.
class PlayerProfile {
  final String uid;
  final String username;
  final String photoUrl;
  final int highScore;
  final int bestStreak;
  final int level; // highest level unlocked
  final int totalStars;

  const PlayerProfile({
    required this.uid,
    required this.username,
    required this.photoUrl,
    required this.highScore,
    required this.bestStreak,
    required this.level,
    required this.totalStars,
  });

  factory PlayerProfile.fromMap(String uid, Map<String, dynamic> d) {
    return PlayerProfile(
      uid: uid,
      username: (d['username'] as String?) ?? 'Player',
      photoUrl: (d['photoUrl'] as String?) ?? '',
      highScore: (d['highScore'] as num?)?.toInt() ?? 0,
      bestStreak: (d['bestStreak'] as num?)?.toInt() ?? 0,
      level: (d['unlockedLevels'] as num?)?.toInt() ?? 1,
      totalStars: (d['totalStars'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlayerRank {
  final int rank;
  final int total;
  const PlayerRank(this.rank, this.total);
}

class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// usernames/{lowercase name} -> { uid, email }. Used for unique usernames
  /// and for "log in with username".
  static DocumentReference<Map<String, dynamic>> nameDoc(String lowerName) =>
      _db.collection('usernames').doc(lowerName);

  static String normalize(String name) => name.trim().toLowerCase();

  static Future<bool> isUsernameFree(String name) async {
    final snap = await nameDoc(normalize(name)).get();
    return !snap.exists;
  }

  /// Creates users/{uid} and claims the username in one transaction.
  static Future<void> createProfile({
    required User user,
    required String username,
    String? photoUrl,
  }) async {
    final key = normalize(username);
    await _db.runTransaction((tx) async {
      final taken = await tx.get(nameDoc(key));
      if (taken.exists) throw UsernameTakenException();

      tx.set(nameDoc(key), {'uid': user.uid, 'email': user.email});
      tx.set(userDoc(user.uid), {
        'username': username.trim(),
        'photoUrl': photoUrl ?? user.photoURL ?? '',
        'highScore': 0,
        'bestStreak': 0,
        'unlockedLevels': 1,
        'totalStars': 0,
        'stars': <int>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// For Google sign-in: creates a profile the first time only.
  static Future<void> ensureProfile(User user) async {
    final existing = await userDoc(user.uid).get();
    if (existing.exists) return;

    var base = (user.displayName ?? user.email?.split('@').first ?? 'player')
        .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
    if (base.length < 3) base = 'player';
    if (base.length > 12) base = base.substring(0, 12);

    var name = base;
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        await createProfile(user: user, username: name);
        return;
      } on UsernameTakenException {
        name = '$base${1000 + Random().nextInt(9000)}';
      }
    }
    throw Exception('Could not create a unique username.');
  }

  static Stream<PlayerProfile?> stream(String uid) {
    return userDoc(uid).snapshots().map((s) {
      final data = s.data();
      return data == null ? null : PlayerProfile.fromMap(uid, data);
    });
  }

  static Future<void> updatePhoto(String uid, String url) async {
    await userDoc(uid).set({'photoUrl': url}, SetOptions(merge: true));
    await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
  }

  /// Rank by high score among all players (1 = best).
  static Future<PlayerRank> rank(int highScore) async {
    final users = _db.collection('users');
    final better =
        await users.where('highScore', isGreaterThan: highScore).count().get();
    final all = await users.count().get();
    return PlayerRank((better.count ?? 0) + 1, all.count ?? 1);
  }
}

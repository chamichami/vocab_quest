import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_bar.dart';
import 'game_screen.dart';
import 'levels.dart';
import 'progress_store.dart';
import 'user_service.dart';
import 'widgets.dart';

/// Dashboard: progress overview + level select.
class HomeScreen extends StatefulWidget {
  final int? resumeLevel;

  const HomeScreen({super.key, this.resumeLevel});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Progress> _progress = ProgressStore.load();
  final User? _user = FirebaseAuth.instance.currentUser;

  void _resumeGame() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _play(int levelIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(startLevel: levelIndex)),
    );
    if (!mounted) return;
    setState(() {
      _progress = ProgressStore.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final resumeLevel = widget.resumeLevel ?? GameScreen.activeGameLevel;
    final onResumeGame = resumeLevel == null ? null : _resumeGame;
    return Scaffold(
      appBar: vqAppBar(context),
      body: FutureBuilder<Progress>(
        future: _progress,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load saved progress. Check your connection and Firestore setup.',
                      textAlign: TextAlign.center,
                    ),
                    if (onResumeGame != null) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: onResumeGame,
                        icon: const Icon(Icons.play_arrow),
                        label: Text('Resume Level ${(resumeLevel ?? 0) + 1}'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _progress = ProgressStore.load();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (user != null)
                StreamBuilder<PlayerProfile?>(
                  stream: UserService.stream(user.uid),
                  builder: (context, s) {
                    final profile = s.data;
                    return Row(
                      children: [
                        AvatarImage(
                          radius: 24,
                          url: profile?.photoUrl ?? user.photoURL,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Welcome, ${profile?.username ?? user.displayName ?? 'Player'}!',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              if (onResumeGame != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.pause_circle_outline),
                    title: const Text('Game paused'),
                    subtitle: Text(
                      'Level ${(resumeLevel ?? 0) + 1} is waiting for you.',
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: onResumeGame,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatCard(label: 'High score', value: '${p.highScore}'),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Best streak', value: '${p.bestStreak}'),
                  const SizedBox(width: 8),
                  _StatCard(
                    label: 'Stars',
                    value: '${p.totalStars}/${levels.length * 3}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Levels', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (var i = 0; i < levels.length; i++)
                _LevelCard(
                  index: i,
                  level: levels[i],
                  unlocked: i < p.unlockedLevels,
                  stars: p.stars[i],
                  onPlay: () => _play(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int index;
  final LevelData level;
  final bool unlocked;
  final int stars;
  final VoidCallback onPlay;

  const _LevelCard({
    required this.index,
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(unlocked ? level.icon : Icons.lock, size: 32),
        title: Text('Level ${index + 1}: ${level.name}'),
        subtitle: Row(
          children: List.generate(
            3,
            (s) => Icon(
              s < stars ? Icons.star : Icons.star_border,
              size: 18,
              color: Colors.amber.shade700,
            ),
          ),
        ),
        trailing: ElevatedButton(
          onPressed: unlocked ? onPlay : null,
          child: Text(unlocked ? 'Play' : 'Locked'),
        ),
      ),
    );
  }
}

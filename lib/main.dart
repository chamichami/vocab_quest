import 'package:flutter/material.dart';

import 'game_screen.dart';
import 'levels.dart';
import 'progress_store.dart';

void main() {
  runApp(const VocabQuestApp());
}

/// Colors taken from the wireframe.
class AppColors {
  static const background = Color(0xFFD8D5C2);
  static const topBar = Color(0xFFA0DDE3);
  static const tile = Color(0xFF03A4CC);
  static const control = Color(0xFFE5BFC6);
}

class VocabQuestApp extends StatelessWidget {
  const VocabQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.tile),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

/// Dashboard: overview of progress + level select.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Progress> _progress;

  @override
  void initState() {
    super.initState();
    _progress = ProgressStore.load();
  }

  Future<void> _play(int levelIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(startLevel: levelIndex)),
    );
    if (!mounted) return;
    setState(() => _progress = ProgressStore.load()); // refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Vocab Quest'),
      ),
      body: FutureBuilder<Progress>(
        future: _progress,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _StatCard(label: 'High score', value: '${p.highScore}'),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Best streak', value: '${p.bestStreak}'),
                  const SizedBox(width: 8),
                  _StatCard(
                      label: 'Stars',
                      value: '${p.totalStars}/${levels.length * 3}'),
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
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
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

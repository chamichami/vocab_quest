import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'confetti_game.dart';
import 'home_screen.dart';
import 'levels.dart';
import 'app_bar.dart';
import 'theme.dart';
import 'progress_store.dart';

/// Main transaction page: the word-unscramble game.
class GameScreen extends StatefulWidget {
  final int startLevel;
  const GameScreen({super.key, this.startLevel = 0});

  static int? get activeGameLevel => _GameScreenState.activeGameLevel;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static final List<_GameScreenState> _activeGames = [];

  static int? get activeGameLevel =>
      _activeGames.isEmpty ? null : _activeGames.last._levelIndex;

  static const int _basePoints = 100;
  static const int _streakBonus = 10;
  static const int _hintCost = 20;

  final Random _random = Random();

  late int _levelIndex;
  int _wordIndex = 0;

  // Current word state
  late List<String> _tiles; // scrambled letters
  late List<bool> _tileUsed; // which tiles are already placed
  late List<String?> _boxes; // letter in each box
  late List<int?> _boxTile; // which tile filled each box
  late List<bool> _boxHinted; // hinted boxes are locked

  // Scoring
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _hintsUsedInLevel = 0;
  bool _levelCompleted = false;

  LevelData get _level => levels[_levelIndex];
  String get _answer => _level.words[_wordIndex];

  @override
  void initState() {
    super.initState();
    _activeGames.add(this);
    _levelIndex = widget.startLevel;
    _loadLevel();
  }

  @override
  void dispose() {
    _activeGames.remove(this);
    super.dispose();
  }

  // ---------- Setup ----------

  void _loadLevel() {
    _wordIndex = 0;
    _hintsUsedInLevel = 0;
    _initWord();
  }

  void _initWord() {
    final word = _answer;
    _tiles = _scramble(word).split('');
    _tileUsed = List<bool>.filled(word.length, false);
    _boxes = List<String?>.filled(word.length, null);
    _boxTile = List<int?>.filled(word.length, null);
    _boxHinted = List<bool>.filled(word.length, false);
  }

  String _scramble(String word) {
    final letters = word.split('');
    for (var attempt = 0; attempt < 20; attempt++) {
      letters.shuffle(_random);
      if (letters.join() != word) break; // avoid showing the answer
    }
    return letters.join();
  }

  // ---------- Box / tile helpers ----------

  void _freeBox(int i) {
    final t = _boxTile[i];
    if (t != null) _tileUsed[t] = false;
    _boxes[i] = null;
    _boxTile[i] = null;
  }

  void _onTileTap(int tileIndex) {
    if (_tileUsed[tileIndex]) return;
    final empty = _boxes.indexWhere((b) => b == null);
    if (empty == -1) return; // all boxes full

    setState(() {
      _boxes[empty] = _tiles[tileIndex];
      _boxTile[empty] = tileIndex;
      _tileUsed[tileIndex] = true;
    });
  }

  void _onBackspace() {
    for (var i = _boxes.length - 1; i >= 0; i--) {
      if (_boxes[i] != null && !_boxHinted[i]) {
        setState(() => _freeBox(i));
        return;
      }
    }
  }

  void _onClear() {
    setState(() {
      for (var i = 0; i < _boxes.length; i++) {
        if (!_boxHinted[i]) _freeBox(i);
      }
    });
  }

  // ---------- Submit ----------

  void _onSubmit() {
    if (_boxes.any((b) => b == null)) {
      _showSnackBar('Fill all boxes before submitting.');
      return;
    }

    if (_boxes.join() == _answer) {
      final gained = _basePoints + _streak * _streakBonus;
      final finished = _wordIndex + 1 >= _level.words.length;
      setState(() {
        _score += gained;
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        if (!finished) {
          _wordIndex++;
          _initWord();
        } else {
          _levelCompleted = true;
        }
      });

      if (finished) {
        _completeLevel(); // keep _wordIndex valid while the dialog is shown
      } else {
        _showSnackBar('Correct! +$gained');
      }
    } else {
      setState(() {
        _streak = 0;
        for (var i = 0; i < _boxes.length; i++) {
          if (!_boxHinted[i]) _freeBox(i);
        }
      });
      _showSnackBar('Wrong word! Try again.');
    }
  }

  // ---------- Hint ----------

  void _useHint() {
    final answer = _answer;

    // First box that is empty or wrong.
    final target = List.generate(
      answer.length,
      (i) => i,
    ).firstWhere((i) => _boxes[i] != answer[i], orElse: () => -1);

    if (target == -1) {
      _showSnackBar('No hint needed.');
      return;
    }
    if (_score < _hintCost) {
      _showSnackBar('Not enough points for a hint.');
      return;
    }

    final letter = answer[target];

    setState(() {
      // Clear a wrong letter from the target box.
      if (_boxes[target] != null) _freeBox(target);

      // Find an unused tile with the needed letter.
      var tile = _findFreeTile(letter);
      if (tile == -1) {
        // The needed tile is sitting in another (wrong) box: take it back.
        for (var i = 0; i < _boxes.length; i++) {
          if (i != target && !_boxHinted[i] && _boxes[i] == letter) {
            _freeBox(i);
            break;
          }
        }
        tile = _findFreeTile(letter);
      }

      _boxes[target] = letter;
      _boxTile[target] = tile;
      _tileUsed[tile] = true;
      _boxHinted[target] = true;

      _score -= _hintCost;
      _hintsUsedInLevel++;
    });
  }

  int _findFreeTile(String letter) {
    for (var i = 0; i < _tiles.length; i++) {
      if (!_tileUsed[i] && _tiles[i] == letter) return i;
    }
    return -1;
  }

  // ---------- Level complete ----------

  int get _stars {
    if (_hintsUsedInLevel == 0) return 3;
    if (_hintsUsedInLevel <= 2) return 2;
    return 1;
  }

  Future<void> _completeLevel() async {
    final stars = _stars;
    String? saveError;
    try {
      await ProgressStore.recordLevel(
        levelIndex: _levelIndex,
        stars: stars,
        score: _score,
        bestStreak: _bestStreak,
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      saveError = 'Progress could not be saved right now. Check your connection and try again.';
    }
    if (!mounted) return;

    final isLast = _levelIndex + 1 >= levels.length;
    final pointsSpent = _hintsUsedInLevel * _hintCost;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(child: GameWidget(game: ConfettiGame())),
            ),
            Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLast ? 'Game Complete!' : 'Level Complete!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          3,
                          (s) => Icon(
                            s < stars ? Icons.star : Icons.star_border,
                            color: Colors.amber.shade700,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Score: $_score'),
                      Text('Best streak: $_bestStreak'),
                      Text('Hints used: $_hintsUsedInLevel'),
                      Text('Points spent on hints: $pointsSpent'),
                      if (saveError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          saveError,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop(); // close dialog
                              _startNextLevel(isLast: isLast);
                              _openDashboard();
                            },
                            child: const Text('Dashboard'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _startNextLevel(isLast: isLast);
                            },
                            child: Text(isLast ? 'Play Again' : 'Continue'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startNextLevel({required bool isLast}) {
    setState(() {
      _levelCompleted = false;
      if (isLast) {
        _levelIndex = 0;
        _score = 0;
        _streak = 0;
        _bestStreak = 0;
      } else {
        _levelIndex++;
      }
      _loadLevel();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  void _openDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          resumeLevel: _levelIndex,
        ),
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _levelCompleted,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_levelCompleted) _openDashboard();
      },
      child: Scaffold(
        appBar: vqAppBar(
          context,
          extraAction: IconButton(
            tooltip: 'Pause and open dashboard',
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: _openDashboard,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Level ${_levelIndex + 1}: ${_level.name}   |   '
                  'Score: $_score   |   Streak: $_streak',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                _buildImageCard(),
                const SizedBox(height: 12),
                Text('Word ${_wordIndex + 1} of ${_level.words.length}'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.topBar,
                  ),
                  onPressed: _useHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text('Hint (-$_hintCost pts)'),
                ),
                const SizedBox(height: 20),
                _buildBoxes(),
                const SizedBox(height: 20),
                _buildTiles(),
                const SizedBox(height: 32),
                _buildControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Container(
            color: Colors.white,
            child: Image.asset(
              _level.image,
              fit: BoxFit.cover,
              // Placeholder until the real image files are added.
              errorBuilder: (_, _, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_level.icon, size: 64, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'IMAGE',
                      style: TextStyle(fontSize: 20, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_boxes.length, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _boxHinted[i] ? Colors.amber.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade700, width: 2),
            ),
            child: Text(
              _boxes[i] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTiles() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(_tiles.length, (i) {
        return SizedBox(
          width: 48,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.tile,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _tileUsed[i] ? null : () => _onTileTap(i),
            child: Text(
              _tiles[i],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildControls() {
    ButtonStyle style() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.control,
      foregroundColor: Colors.black,
      minimumSize: const Size(90, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: style(),
          onPressed: _onBackspace,
          child: const Icon(Icons.backspace_outlined),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: style(),
          onPressed: _onClear,
          child: const Text('Clear'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: style(),
          onPressed: _onSubmit,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

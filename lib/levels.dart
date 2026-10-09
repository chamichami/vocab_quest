import 'package:flutter/material.dart';

/// One word plus the image that acts as its visual clue.
class WordClue {
  final String word;
  final String image; // asset path, e.g. assets/images/wave.png
  const WordClue(this.word, this.image);
}

class LevelData {
  final String name;
  final IconData icon;
  final List<WordClue> words;
  const LevelData(this.name, this.icon, this.words);
}

/// Add new levels here (or later load them from a JSON file).
const List<LevelData> levels = [
  LevelData('Ocean', Icons.waves, [
    WordClue('WAVE', 'assets/images/wave.png'),
    WordClue('FISH', 'assets/images/fish.png'),
    WordClue('BOAT', 'assets/images/boat.png'),
    WordClue('SAND', 'assets/images/sand.png'),
  ]),
  LevelData('Fire', Icons.local_fire_department, [
    WordClue('FIRE', 'assets/images/fire.png'),
    WordClue('HEAT', 'assets/images/heat.png'),
    WordClue('ASH', 'assets/images/ash.png'),
    WordClue('COAL', 'assets/images/coal.png'),
  ]),
  LevelData('Forest', Icons.park, [
    WordClue('TREE', 'assets/images/tree.png'),
    WordClue('LEAF', 'assets/images/leaf.png'),
    WordClue('ROOT', 'assets/images/root.png'),
    WordClue('SEED', 'assets/images/seed.png'),
  ]),
];

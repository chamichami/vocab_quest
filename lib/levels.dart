import 'package:flutter/material.dart';

/// One level = one theme = one image shared by all of its words.
class LevelData {
  final String name;
  final IconData icon;
  final String image; // asset path; replace the file, keep the name
  final List<String> words;
  const LevelData(this.name, this.icon, this.image, this.words);
}

/// Add new levels here (and drop the matching image into assets/images/).
const List<LevelData> levels = [
  LevelData('Ocean', Icons.waves, 'lib/assets/images/ocean.jpg',
      ['WAVE', 'FISH', 'BOAT', 'SAND']),
  LevelData('Fire', Icons.local_fire_department, 'lib/assets/images/fire.jpg',
      ['FIRE', 'HEAT', 'ASH', 'COAL']),
  LevelData('Forest', Icons.park, 'lib/assets/images/forest.jpg',
      ['TREE', 'LEAF', 'ROOT', 'SEED']),
];

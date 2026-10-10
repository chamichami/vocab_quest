import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class ConfettiGame extends FlameGame {
  final Random _random = Random();
  bool _spawned = false;

  @override
  Color backgroundColor() => const Color(0x00000000);

  void _spawnConfetti() {
    if (_spawned || size.x <= 0 || size.y <= 0) return;
    _spawned = true;

    final count = (size.x * size.y / 12).clamp(40, 160).toInt();
    for (var i = 0; i < count; i++) {
      add(
        ConfettiParticle(
          random: _random,
          startX: _random.nextDouble() * size.x,
          startY: -_random.nextDouble() * (size.y * 0.5),
          color: HSVColor.fromAHSV(
            1,
            _random.nextDouble() * 360,
            0.75,
            1,
          ).toColor(),
        ),
      );
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _spawnConfetti();
  }
}

class ConfettiParticle extends PositionComponent
    with HasGameReference<ConfettiGame> {
  final Color color;
  final double _vx;
  final double _vy;
  final double _rotSpeed;
  final Paint _paint;

  ConfettiParticle({
    required Random random,
    required double startX,
    required double startY,
    required this.color,
  }) : _vx = (random.nextDouble() - 0.5) * 200,
       _vy = 100 + random.nextDouble() * 150,
       _rotSpeed = (random.nextDouble() - 0.5) * 5,
       _paint = Paint()..color = color,
       super(
         position: Vector2(startX, startY),
         size: Vector2(8, 12),
         angle: random.nextDouble() * 2 * pi,
         anchor: Anchor.center,
       );

  @override
  void update(double dt) {
    super.update(dt);
    position.x += _vx * dt;
    position.y += _vy * dt;
    angle += _rotSpeed * dt;

    if (position.y > game.size.y + 50 ||
        position.x < -30 ||
        position.x > game.size.x + 30) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
  }
}

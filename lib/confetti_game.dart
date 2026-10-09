import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Confetti celebration shown behind the Level Complete dialog.
class ConfettiGame extends FlameGame {
  final Random _random = Random();
  bool _spawned = false;

  // Transparent so the dialog's barrier shows through.
  @override
  Color backgroundColor() => const Color(0x00000000);

  // Spawn once the real size is known (size can be zero inside onLoad).
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_spawned || size.x == 0) return;
    _spawned = true;

    for (var i = 0; i < 80; i++) {
      add(ConfettiParticle(
        random: _random,
        startX: _random.nextDouble() * size.x,
        color: HSVColor.fromAHSV(1, _random.nextDouble() * 360, 0.75, 1)
            .toColor(),
      ));
    }
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
    required this.color,
  })  : _vx = (random.nextDouble() - 0.5) * 200,
        _vy = 100 + random.nextDouble() * 150,
        _rotSpeed = (random.nextDouble() - 0.5) * 5,
        _paint = Paint()..color = color,
        super(
          position: Vector2(startX, -random.nextDouble() * 200),
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

    if (position.y > game.size.y + 50) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
  }
}

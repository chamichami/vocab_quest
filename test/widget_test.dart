import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_quest/app_config.dart';
import 'package:vocab_quest/game_screen.dart';
import 'package:vocab_quest/levels.dart';
import 'package:vocab_quest/settings_screen.dart';

void main() {
  test('Cloudinary is enabled when real settings are supplied', () {
    expect(AppConfig.cloudinaryConfigured, isTrue);
  });

  testWidgets('opens the selected level without revealing the answer', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen(startLevel: 1)));
    await tester.pump();

    expect(find.textContaining('Level 2: Fire'), findsOneWidget);
    expect(find.textContaining('Debug:'), findsNothing);
    expect(GameScreen.activeGameLevel, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(GameScreen.activeGameLevel, isNull);
  });

  testWidgets('settings has a profile-style close button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              child: const Text('Open Settings'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(find.text('MUSIC'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('EXIT APP'), findsOneWidget);

    await tester.tap(find.text('EXIT APP'));
    await tester.pumpAndSettle();
    expect(find.text('Exit Vocab Quest?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('shows a level-complete dialog after the final word', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump();

    for (final word in levels.first.words) {
      for (final letter in word.split('')) {
        final tile = find.byWidgetPredicate((widget) {
          return widget is ElevatedButton &&
              widget.onPressed != null &&
              widget.child is Text &&
              (widget.child as Text).data == letter;
        }).first;
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pump();
      }

      final submit = find.text('Submit');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Level Complete!'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Level 2: Fire'), findsOneWidget);
    expect(GameScreen.activeGameLevel, 1);
  });
}

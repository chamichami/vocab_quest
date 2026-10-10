import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'profile_screen.dart';
import 'settings_service.dart';
import 'theme.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exitApp(BuildContext context) async {
    if (kIsWeb) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit Vocab Quest'),
          content: const Text(
            'Browsers do not let websites close their own tabs. Close this tab to exit the game.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Vocab Quest?'),
        content: const Text('Are you sure you want to close the game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.barButton,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _SettingTile(
                          icon: settings.volume == 0
                              ? Icons.volume_off
                              : Icons.volume_up,
                          title: 'VOLUME  ${(settings.volume * 100).round()}%',
                          child: Slider(
                            value: settings.volume,
                            onChanged: (v) =>
                                settings.setVolume(v, save: false),
                            onChangeEnd: (v) => settings.setVolume(v),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SettingTile(
                          icon: Icons.music_note,
                          title: 'MUSIC',
                          child: Switch(
                            value: settings.musicOn,
                            onChanged: settings.setMusicOn,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PillButton(
                          label: 'PROFILE',
                          color: AppColors.barButton,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        PillButton(
                          label: 'HOME',
                          color: AppColors.control,
                          onPressed: () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                        ),
                        const SizedBox(height: 14),
                        PillButton(
                          label: 'EXIT APP',
                          color: AppColors.pink,
                          onPressed: () => _exitApp(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 70,
            color: const Color(0xFF7FE0FF),
            child: Icon(icon, color: AppColors.blue, size: 28),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 70),
              color: AppColors.barButton.withValues(alpha: 0.28),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(letterSpacing: 1.5)),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

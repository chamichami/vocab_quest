import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

/// Top bar from the wireframe: Settings (left), title, Profile (right).
PreferredSizeWidget vqAppBar(
  BuildContext context, {
  String title = 'VOCAB QUEST',
  Widget? extraAction,
}) {
  ButtonStyle style() => IconButton.styleFrom(
    backgroundColor: AppColors.barButton,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  return AppBar(
    backgroundColor: AppColors.topBar,
    centerTitle: true,
    title: Text(
      title,
      style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.w600),
    ),
    leading: Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconButton(
        style: style(),
        tooltip: 'Settings',
        icon: const Icon(Icons.tune),
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
    ),
    actions: [
      ?extraAction,
      IconButton(
        style: style(),
        tooltip: 'Profile',
        icon: const Icon(Icons.person),
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      const SizedBox(width: 8),
    ],
  );
}

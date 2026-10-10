import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'cloudinary_service.dart';
import 'theme.dart';
import 'user_service.dart';
import 'widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final User? _user = FirebaseAuth.instance.currentUser;
  late final Stream<PlayerProfile?> _profile = _user?.uid == null
      ? const Stream<PlayerProfile?>.empty()
      : UserService.stream(_user!.uid);

  bool _uploading = false;
  Uint8List? _preview;

  Future<void> _changePhoto() async {
    final user = _user;
    if (user == null) return;
    if (!CloudinaryService.isConfigured) {
      showMessage(context, CloudinaryService.configurationMessage);
      return;
    }

    final picked = await CloudinaryService.pickImage();
    if (picked == null || !mounted) return;

    setState(() {
      _preview = picked.bytes;
      _uploading = true;
    });
    try {
      final url = await CloudinaryService.uploadAvatar(picked);
      await UserService.updatePhoto(user.uid, url);
      if (mounted) showMessage(context, 'Profile picture updated.');
    } on CloudinaryException catch (e) {
      if (mounted) {
        setState(() => _preview = null);
        showMessage(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _preview = null);
        showMessage(context, 'Could not save your picture. Try again.');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _logOut() async {
    final navigator = Navigator.of(context);
    navigator.popUntil((r) => r.isFirst);
    await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: const Text(
          'Profile',
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
      body: StreamBuilder<PlayerProfile?>(
        stream: _profile,
        builder: (context, snap) {
          final p = snap.data;
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
                        AvatarImage(
                          radius: 60,
                          url: p?.photoUrl ?? _user?.photoURL,
                          previewBytes: _preview,
                          busy: _uploading,
                          showEditBadge: true,
                          onTap: _changePhoto,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap the picture to change it',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p?.username ?? _user?.displayName ?? 'Player',
                          style: const TextStyle(
                            fontSize: 26,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatTile(
                          icon: Icons.star,
                          iconColor: Colors.amber,
                          label: 'LEVEL ${p?.level ?? 1}',
                        ),
                        const SizedBox(height: 10),
                        _StatTile(
                          icon: Icons.local_fire_department,
                          iconColor: Colors.deepOrange,
                          label: 'BEST STREAK ${p?.bestStreak ?? 0}',
                        ),
                        const SizedBox(height: 10),
                        if (p != null)
                          _RankTile(
                            key: ValueKey(p.highScore),
                            highScore: p.highScore,
                          )
                        else
                          const _StatTile(
                            icon: Icons.emoji_events,
                            iconColor: Colors.orange,
                            label: 'RANK ...',
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _user?.email ?? '',
                          style: const TextStyle(letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        PillButton(
                          label: 'LOG OUT',
                          color: AppColors.control,
                          onPressed: _logOut,
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

class _RankTile extends StatefulWidget {
  final int highScore;
  const _RankTile({super.key, required this.highScore});

  @override
  State<_RankTile> createState() => _RankTileState();
}

class _RankTileState extends State<_RankTile> {
  late final Future<PlayerRank> _rank = UserService.rank(widget.highScore);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlayerRank>(
      future: _rank,
      builder: (context, snap) {
        final label = snap.hasData
            ? 'RANK #${snap.data!.rank} OF ${snap.data!.total}'
            : snap.hasError
            ? 'RANK UNAVAILABLE'
            : 'RANK ...';
        return _StatTile(
          icon: Icons.emoji_events,
          iconColor: Colors.orange,
          label: label,
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 54,
            color: const Color(0xFF7FE0FF),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          Expanded(
            child: Container(
              height: 54,
              color: AppColors.barButton,
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(fontSize: 18, letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

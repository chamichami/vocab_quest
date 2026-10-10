import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'theme.dart';

class AvatarImage extends StatelessWidget {
  final String? url;
  final Uint8List? previewBytes;
  final double radius;
  final VoidCallback? onTap;
  final bool busy;
  final bool showEditBadge;

  const AvatarImage({
    super.key,
    this.url,
    this.previewBytes,
    this.radius = 50,
    this.onTap,
    this.busy = false,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = previewBytes != null
        ? MemoryImage(previewBytes!)
        : url != null && url!.isNotEmpty
        ? NetworkImage(url!)
        : null;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.avatarBg,
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: image == null
              ? _avatarPlaceholder(radius)
              : Image(
                  image: image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _avatarPlaceholder(radius),
                ),
        ),
      ),
    );

    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          avatar,
          if (busy)
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black38,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (showEditBadge && !busy)
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: radius * 0.28,
                backgroundColor: AppColors.tile,
                child: Icon(
                  Icons.camera_alt,
                  size: radius * 0.34,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _avatarPlaceholder(double radius) =>
    Icon(Icons.pets, size: radius, color: AppColors.pink);

class LogoBox extends StatelessWidget {
  final double size;
  const LogoBox({super.key, this.size = 130});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'lib/assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: size * 0.45,
                  color: AppColors.blue,
                ),
                const SizedBox(height: 6),
                const Text(
                  'LOGO IMAGE',
                  style: TextStyle(fontSize: 12, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.action = TextInputAction.next,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: action,
        onSubmitted: onSubmitted,
        autocorrect: false,
        enableSuggestions: !obscure,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool busy;
  final double minWidth;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Colors.white,
    this.textColor = Colors.black,
    this.busy = false,
    this.minWidth = 180,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 0,
        minimumSize: Size(minWidth, 50),
        shape: const StadiumBorder(),
      ),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label, style: const TextStyle(letterSpacing: 1.5)),
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

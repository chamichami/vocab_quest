import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'cloudinary_service.dart';
import 'theme.dart';
import 'widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _uploading = false;
  Uint8List? _preview;
  String? _photoUrl;
  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (!CloudinaryService.isConfigured) {
      showMessage(context, CloudinaryService.configurationMessage);
      return;
    }
    final picked = await CloudinaryService.pickImage();
    if (picked == null || !mounted) return;

    setState(() {
      _preview = picked.bytes;
      _uploading = true;
      _photoUrl = null;
    });
    try {
      final url = await CloudinaryService.uploadAvatar(picked);
      if (mounted) setState(() => _photoUrl = url);
    } on CloudinaryException catch (e) {
      if (mounted) {
        setState(() => _preview = null);
        showMessage(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String? _validate() {
    if (!RegExp(r'^[A-Za-z0-9_]{3,16}$').hasMatch(_username.text.trim())) {
      return 'Username: 3-16 letters, numbers or underscores.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      return 'Enter a valid email address.';
    }
    if (_password.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (_uploading) return 'Wait for your picture to finish uploading.';
    return null;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) showMessage(context, 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _signUp() {
    final error = _validate();
    if (error != null) {
      showMessage(context, error);
      return;
    }
    _run(
      () => AuthService.signUp(
        username: _username.text,
        email: _email.text,
        password: _password.text,
        photoUrl: _photoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                children: [
                  const Text(
                    'SIGN UP',
                    style: TextStyle(fontSize: 24, letterSpacing: 3),
                  ),
                  const SizedBox(height: 20),
                  AvatarImage(
                    radius: 58,
                    previewBytes: _preview,
                    busy: _uploading,
                    showEditBadge: true,
                    onTap: _busy ? null : _pickPhoto,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap to add a profile picture',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  AuthField(
                    controller: _username,
                    hint: 'Username',
                    enabled: !_busy,
                  ),
                  AuthField(
                    controller: _email,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_busy,
                  ),
                  AuthField(
                    controller: _password,
                    hint: 'Password',
                    obscure: true,
                    action: TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _signUp(),
                    enabled: !_busy,
                  ),
                  const SizedBox(height: 14),
                  PillButton(
                    label: 'SIGN UP',
                    busy: _busy,
                    onPressed: _busy ? null : _signUp,
                  ),
                  const SizedBox(height: 18),
                  PillButton(
                    label: 'SIGN UP WITH GOOGLE',
                    color: AppColors.blue,
                    textColor: Colors.white,
                    minWidth: 240,
                    onPressed: _busy
                        ? null
                        : () => _run(AuthService.signInWithGoogle),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      GestureDetector(
                        onTap: _busy ? null : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

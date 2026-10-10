import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'signup_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) showMessage(context, 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _login() {
    if (_identifier.text.trim().isEmpty || _password.text.isEmpty) {
      showMessage(context, 'Enter your username and password.');
      return;
    }
    _run(() => AuthService.signIn(_identifier.text, _password.text));
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(
      text: _identifier.text.contains('@') ? _identifier.text.trim() : '',
    );
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Your account email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    try {
      await AuthService.sendPasswordReset(email);
      if (mounted) showMessage(context, 'Reset link sent. Check your email.');
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
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
                  const LogoBox(),
                  const SizedBox(height: 10),
                  const Text(
                    'VOCAB QUEST',
                    style: TextStyle(fontSize: 18, letterSpacing: 3),
                  ),
                  const SizedBox(height: 40),
                  AuthField(
                    controller: _identifier,
                    hint: 'Username',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_busy,
                  ),
                  AuthField(
                    controller: _password,
                    hint: 'Password',
                    obscure: true,
                    action: TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _login(),
                    enabled: !_busy,
                  ),
                  TextButton(
                    onPressed: _busy ? null : _forgotPassword,
                    child: const Text(
                      'Forgot Password',
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                  PillButton(
                    label: 'LOGIN',
                    busy: _busy,
                    onPressed: _busy ? null : _login,
                  ),
                  const SizedBox(height: 18),
                  PillButton(
                    label: 'LOG IN WITH GOOGLE',
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
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: _busy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              ),
                        child: const Text(
                          'Sign up',
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

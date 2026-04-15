import 'package:advmobdev_ta/app_state.dart';
import 'package:advmobdev_ta/screens/register_screen.dart';
import 'package:advmobdev_ta/widgets/auth_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    if (state.statusMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && state.statusMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.statusMessage!),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
          state.clearStatus();
        }
      });
    }

    return AuthShell(
      headline: 'Welcome back',
      tagline:
          'Sign in with your agent account. Tasks stay on your device and sync when you choose.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded, color: scheme.primary),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                filled: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(state),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded, color: scheme.primary),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                filled: true,
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Enter at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: state.loading ? null : () => _submit(state),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: state.loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'New here?',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                TextButton(
                  onPressed: state.loading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit(AppState state) {
    if (_formKey.currentState?.validate() ?? false) {
      state.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }
}

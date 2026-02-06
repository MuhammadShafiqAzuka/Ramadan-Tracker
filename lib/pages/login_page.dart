import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../utils/tw.dart';
import '../widgets/auth_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);

    return AuthCard(
      title: 'Login',
      subtitle: 'Sign in to your account',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            Tw.gap(Tw.s4),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),
            if (error != null) ...[
              Tw.gap(Tw.s3),
              Text(error!, style: Tw.error),
            ],
            Tw.gap(Tw.s6),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                setState(() {
                  error = null;
                  loading = true;
                });

                try {
                  if (!_formKey.currentState!.validate()) {
                    setState(() => loading = false);
                    return;
                  }

                  await auth.login(
                    email: _email.text.trim(),
                    password: _password.text,
                  );
                  // GoRouter will redirect automatically to /dashboard
                } catch (e) {
                  setState(() => error = e.toString());
                } finally {
                  setState(() => loading = false);
                }
              },
              child: loading
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Login'),
            ),
            Tw.gap(Tw.s4),
            TextButton(
              onPressed: () => context.go('/signup-solo'),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}

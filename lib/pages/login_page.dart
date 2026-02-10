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
      brand: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('Ramadan Hero', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
      title: 'Log masuk',
      subtitle: 'Log masuk ke akaun anda',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email diperlukan';
                if (!v.contains('@')) return 'Masukkan e-mel yang sah';
                return null;
              },
            ),
            Tw.gap(Tw.s4),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata Laluan'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password diperlukan';
                if (v.length < 6) return 'Kata laluan mestilah sekurang-kurangnya 6 aksara';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/forgot-password'),
                child: const Text('Terlupa kata laluan ?'),
              ),
            ),
            if (error != null) ...[
              Tw.gap(Tw.s3),
              Text(error!, style: Tw.error),
            ],
            Tw.gap(Tw.s6),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: loading ? 0.90 : 1.0,
              child: ElevatedButton(
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
                  } catch (e) {
                    setState(() => error = e.toString());
                  } finally {
                    if (mounted) setState(() => loading = false);
                  }
                },
                child: SizedBox(
                  height: 22, // keep consistent vertical rhythm
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loading) ...[
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(loading ? 'Sedang di process...' : 'Log masuk'),
                    ],
                  ),
                ),
              ),
            ),
            Tw.gap(Tw.s4),
            TextButton(
              onPressed: () => context.go('/signup-solo'),
              child: const Text('Daftar akaun'),
            ),
          ],
        ),
      ),
    );
  }
}

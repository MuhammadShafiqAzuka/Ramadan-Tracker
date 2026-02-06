import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../utils/tw.dart';
import '../widgets/auth_card.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool loading = false;
  String? error;
  String? success;

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);

    return AuthCard(
      title: 'Reset Password',
      subtitle: 'We’ll email you a reset link',
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
            if (error != null) ...[
              Tw.gap(Tw.s3),
              Text(error!, style: Tw.error),
            ],
            if (success != null) ...[
              Tw.gap(Tw.s3),
              Text(success!, style: const TextStyle(fontSize: 13)),
            ],
            Tw.gap(Tw.s6),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                setState(() {
                  error = null;
                  success = null;
                  loading = true;
                });

                try {
                  if (!_formKey.currentState!.validate()) {
                    setState(() => loading = false);
                    return;
                  }

                  await auth.sendResetEmail(email: _email.text.trim());
                  setState(() => success = 'Reset link sent. Check your email.');
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
                  : const Text('Send reset link'),
            ),
            Tw.gap(Tw.s4),
            TextButton(
              onPressed: () => context.go('/login-solo'),
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/plan_type.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../utils/tw.dart';
import '../widgets/auth_card.dart';

class SignupPage extends ConsumerStatefulWidget {
  final PlanType planType;
  const SignupPage({super.key, required this.planType});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);
    final profiles = ref.read(userProfileServiceProvider);

    return AuthCard(
      title: 'Sign Up (${widget.planType.title})',
      subtitle: 'Create a new ${widget.planType.title} account',
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
            Tw.gap(Tw.s4),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm password is required';
                if (v != _password.text) return 'Passwords do not match';
                return null;
              },
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

                  final cred = await auth.register(
                    email: _email.text.trim(),
                    password: _password.text,
                  );

                  final uid = cred.user?.uid;
                  final email = cred.user?.email;

                  debugPrint('REGISTER OK uid=$uid email=$email plan=${widget.planType.id}');

                  if (uid != null && email != null) {
                    await profiles.createUserProfile(
                      uid: uid,
                      email: email,
                      planType: widget.planType,
                    );
                    debugPrint('FIRESTORE WRITE OK users/$uid');
                  } else {
                    debugPrint('REGISTER returned null uid/email');
                  }
                } on FirebaseAuthException catch (e) {
                  setState(() => error = '${e.code}: ${e.message ?? ''}');
                } on FirebaseException catch (e) {
                  // 🔥 this will show Firestore permission / missing db / etc
                  debugPrint('FirebaseException plugin=${e.plugin} code=${e.code} message=${e.message}');
                  setState(() => error = '${e.code}: ${e.message ?? ''}');
                } catch (e, st) {
                  debugPrint('Unknown error type=${e.runtimeType} err=$e');
                  debugPrint('$st');
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
                  : const Text('Register'),
            ),
            Tw.gap(Tw.s4),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
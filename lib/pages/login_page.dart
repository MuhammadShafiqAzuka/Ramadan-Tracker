import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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

  final Uri signupUrlSolo = Uri.parse('https://toyyibpay.com/Ramadan-Hero-Solo');
  final Uri signupUrlFamily5 = Uri.parse('https://toyyibpay.com/Ramadan-Hero-Family5');
  final Uri signupUrlFamily9 = Uri.parse('https://toyyibpay.com/Ramadan-Hero-Family9');

  Future<void> _openSignup(Uri url) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _openSignupRoute(String route) async {
    context.go('/$route');
  }

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

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rocket_launch_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Daftar akaun', style: TextStyle(fontWeight: FontWeight.w900)),
                      const Spacer(),
                      Text(
                        'Pilih pelan',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Tw.gap(Tw.s3),

                  LayoutBuilder(
                    builder: (context, c) {
                      final isPhone = MediaQuery.of(context).size.width < 480 || c.maxWidth < 420;
                      final gap = isPhone ? 8.0 : 10.0;

                      Widget planButton({
                        required String title,
                        required String subtitle,
                        required IconData icon,
                        required VoidCallback onTap,
                      }) {
                        return FilledButton.tonal(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.open_in_new_rounded, size: 18, color: Theme.of(context).hintColor),
                            ],
                          ),
                        );
                      }

                      if (isPhone) {
                        // stacked on phone
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            planButton(
                              title: 'Solo',
                              subtitle: '1 pengguna',
                              icon: Icons.person_rounded,
                              onTap: () => _openSignupRoute("signup-solo"),
                            ),
                            SizedBox(height: gap),
                            planButton(
                              title: 'Family 5',
                              subtitle: 'Sehingga 5 ahli',
                              icon: Icons.groups_rounded,
                              onTap: () => _openSignupRoute('signup-five'),
                            ),
                            SizedBox(height: gap),
                            planButton(
                              title: 'Family 9',
                              subtitle: 'Sehingga 9 ahli',
                              icon: Icons.diversity_3_rounded,
                              onTap: () => _openSignupRoute('signup-nine'),
                            ),
                          ],
                        );
                      }

                      // 3 columns on larger screens
                      return Row(
                        children: [
                          Expanded(
                            child: planButton(
                              title: 'Solo',
                              subtitle: '1 pengguna',
                              icon: Icons.person_rounded,
                              onTap: () => _openSignupRoute("signup-solo"),
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: planButton(
                              title: 'Family 5',
                              subtitle: 'Sehingga 5 ahli',
                              icon: Icons.groups_rounded,
                              onTap: () => _openSignupRoute("signup-five"),
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: planButton(
                              title: 'Family 9',
                              subtitle: 'Sehingga 9 ahli',
                              icon: Icons.diversity_3_rounded,
                              onTap: () => _openSignupRoute("signup-nine"),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            Tw.gap(Tw.s6),

            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Powered by FNX Solution',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),

                  Image.asset(
                    'assets/fnx.png',
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

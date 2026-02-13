import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../utils/tw.dart';
import '../widgets/theme_toggle.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscurePassword = true;

  // (not used in UI right now, keeping as-is)
  final Uri signupUrlSolo = Uri.parse('https://toyyibpay.com/Ramadan-Hero-Solo');
  final Uri signupUrlFamily5 = Uri.parse('https://toyyibpay.com/Ramadan-Hero-Family5');
  final Uri signupUrlFamily9 = Uri.parse('https://toyyibpay.com/Ramadan-Hero-Family9');

  Future<void> _openSignup(Uri url) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) throw 'Could not launch $url';
  }

  Future<void> _openSignupRoute(String route) async {
    context.go('/$route');
  }

  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authServiceProvider).completeGoogleRedirectIfAny());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);

    return AuthCard(
      brand: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text(
            'Ramadan Hero',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
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
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Kata Laluan',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Tunjuk kata laluan' : 'Sembunyi kata laluan',
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
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
                  height: 22,
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

            // Tw.gap(Tw.s4),
            //
            // OutlinedButton.icon(
            //   icon: const Icon(Icons.login),
            //   label: const Text('Log masuk dengan Google'),
            //   onPressed: loading ? null : () async {
            //     setState(() { error = null; loading = true; });
            //     try {
            //       await auth.signInWithGoogleWeb();
            //       // redirect happens; no need to set loading=false
            //     } catch (e) {
            //       if (mounted) setState(() { error = e.toString(); loading = false; });
            //     }
            //   },
            // ),

            // ✅ FNX logo neatly inside card
            Tw.gap(Tw.s6),
            _PoweredByLogo(
              onTap: () async {
                final uri = Uri.parse('https://fnxsolution.com');
                final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!ok) debugPrint('Could not launch $uri');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Neat "Powered by" block inside the card
class _PoweredByLogo extends StatelessWidget {
  final VoidCallback onTap;
  const _PoweredByLogo({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border = isDark ? Tw.darkBorder : Tw.slate200;
    final textColor = isDark ? Tw.darkSubtext : Tw.slate700;

    return Column(
      children: [
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Image.asset(
                'assets/fnx.png',
                height: 50,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ✅ Clean AuthCard (no footer, no Stack)
class AuthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  /// Optional brand/logo widget (e.g. app icon)
  final Widget? brand;

  const AuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? Tw.darkBg : Tw.slate50;
    final cardBg = isDark ? Tw.darkCard : Tw.white;
    final border = isDark ? Tw.darkBorder : Tw.slate200;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: Tw.br(18),
                  border: Border.all(color: border),
                  boxShadow: isDark ? const [] : Tw.shadowMd,
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (brand != null)
                          SizedBox(
                            height: 34,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: brand,
                            ),
                          )
                        else
                          const SizedBox(height: 34),

                        const Spacer(),

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(isDark ? 0.12 : 0.06),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: const ThemeToggle(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Tw.title.copyWith(
                        fontSize: 22,
                        color: isDark ? Tw.darkText : Tw.slate900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Tw.subtitle.copyWith(
                        fontSize: 13,
                        color: isDark ? Tw.darkSubtext : Tw.slate700,
                      ),
                    ),

                    const SizedBox(height: 22),
                    Divider(color: border, height: 1),
                    const SizedBox(height: 22),

                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
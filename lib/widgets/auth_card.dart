import 'package:flutter/material.dart';
import '../utils/tw.dart';
import 'theme_toggle.dart';

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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                  // Top row: brand (left) + theme toggle (right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (brand != null)
                        SizedBox(
                          height: 34,
                          child: Align(alignment: Alignment.centerLeft, child: brand),
                        )
                      else
                        const SizedBox(height: 34),

                      const Spacer(),

                      // Breeze-like small icon control area
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                          color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06),
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
                      fontSize: 22, // Breeze feels slightly smaller than 26
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
    );
  }
}
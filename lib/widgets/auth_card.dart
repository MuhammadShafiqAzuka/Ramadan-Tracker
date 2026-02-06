import 'package:flutter/material.dart';
import '../utils/tw.dart';
import 'theme_toggle.dart';

class AuthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Tw.darkBg : Tw.slate50,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Tw.darkCard : Tw.white,
              borderRadius: Tw.br(Tw.rLg),
              border: Border.all(color: isDark ? Tw.darkBorder : Tw.slate200),
              boxShadow: isDark ? const [] : Tw.shadowMd,
            ),
            padding: Tw.p(Tw.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [ThemeToggle()],
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Tw.title.copyWith(color: isDark ? Tw.darkText : Tw.slate900),
                ),
                Tw.gap(Tw.s2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Tw.subtitle.copyWith(color: isDark ? Tw.darkSubtext : Tw.slate700),
                ),
                Tw.gap(Tw.s8),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

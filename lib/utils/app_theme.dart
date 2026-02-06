import 'package:flutter/material.dart';
import 'tw.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: Tw.slate50,
      colorScheme: base.colorScheme.copyWith(primary: Tw.indigo600),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tw.slate50,
        border: OutlineInputBorder(
          borderRadius: Tw.br(Tw.rMd),
          borderSide: const BorderSide(color: Tw.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Tw.br(Tw.rMd),
          borderSide: const BorderSide(color: Tw.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Tw.br(Tw.rMd),
          borderSide: const BorderSide(color: Tw.indigo600, width: 1.5),
        ),
        contentPadding: Tw.pxpy(Tw.s4, Tw.s3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Tw.indigo600),
          foregroundColor: const WidgetStatePropertyAll(Tw.white),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              inherit: false,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(Tw.indigo600),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              inherit: false,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Tw.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: Tw.darkBg,
      colorScheme: base.colorScheme.copyWith(primary: Tw.indigo600),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: Tw.br(Tw.rMd),
          borderSide: const BorderSide(color: Tw.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Tw.br(Tw.rMd),
          borderSide: const BorderSide(color: Tw.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Tw.br(Tw.rMd),
          borderSide: const BorderSide(color: Tw.indigo600, width: 1.5),
        ),
        contentPadding: Tw.pxpy(Tw.s4, Tw.s3),
      ),

      // ✅ ADD THESE TWO (same as light)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Tw.indigo600),
          foregroundColor: const WidgetStatePropertyAll(Tw.white),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              inherit: false,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(Tw.indigo600),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              inherit: false,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: Tw.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
      ),
    );
  }
}
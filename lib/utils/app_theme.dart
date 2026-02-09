import 'package:flutter/material.dart';
import 'tw.dart';

class AppTheme {
  // Breeze-like: neutral surfaces + indigo primary
  static const _seed = Tw.indigo600;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Tw.slate50,
      visualDensity: VisualDensity.standard,

      // Typography: keep it crisp (you can wire GoogleFonts later if you want)
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: Tw.slate900,
        displayColor: Tw.slate900,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Tw.slate50,
        foregroundColor: Tw.slate900,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: Tw.slate900,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Tw.slate200,
        thickness: 1,
        space: 16,
      ),

      cardTheme: CardThemeData(
        color: Tw.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Tw.br(Tw.rMd),
          side: const BorderSide(color: Tw.slate200),
        ),
      ),

      // Nice, modern surfaces in M3
      dialogTheme: DialogThemeData(
        backgroundColor: Tw.white,
        shape: RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Tw.slate50,
        selectedColor: scheme.primary.withOpacity(0.12),
        side: const BorderSide(color: Tw.slate200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),

      // Inputs (Breeze style)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tw.white,
        hintStyle: const TextStyle(color: Tw.slate700),
        labelStyle: const TextStyle(color: Tw.slate700),
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
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Tw.br(Tw.rMd),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: Tw.pxpy(Tw.s4, Tw.s3),
      ),

      // Buttons (Material 3 + Breeze-ish)
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.primary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),

      // Keep ElevatedButton too (in case you still use it)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.primary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          side: const WidgetStatePropertyAll(BorderSide(color: Tw.slate200)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),

      // Lists / tiles (web dashboard feels)
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Tw.darkBg,
      visualDensity: VisualDensity.standard,

      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Tw.white,
        displayColor: Tw.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Tw.darkBg,
        foregroundColor: Tw.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: Tw.white,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Tw.darkBorder,
        thickness: 1,
        space: 16,
      ),

      cardTheme: CardThemeData(
        color: Tw.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Tw.br(Tw.rMd),
          side: const BorderSide(color: Tw.darkBorder),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Tw.darkCard,
        shape: RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF111827),
        selectedColor: scheme.primary.withOpacity(0.18),
        side: const BorderSide(color: Tw.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        hintStyle: const TextStyle(color: Tw.darkSubtext),
        labelStyle: const TextStyle(color: Tw.darkSubtext),
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
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Tw.br(Tw.rMd),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: Tw.pxpy(Tw.s4, Tw.s3),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.primary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.primary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          side: const WidgetStatePropertyAll(BorderSide(color: Tw.darkBorder)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Tw.br(Tw.rMd)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
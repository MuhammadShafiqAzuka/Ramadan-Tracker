import 'package:flutter/material.dart';

class Tw {
  // Light palette
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate700 = Color(0xFF334155);
  static const slate900 = Color(0xFF0F172A);

  static const indigo600 = Color(0xFF10B981);

  static const red600 = Color(0xFFDC2626);

  static const white = Colors.white;

  // Dark palette
  static const darkBg = Color(0xFF0B1220);
  static const darkCard = Color(0xFF0F172A);
  static const darkBorder = Color(0xFF1F2937);
  static const darkText = Color(0xFFE5E7EB);
  static const darkSubtext = Color(0xFF9CA3AF);

  // Spacing
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 22.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 42.0;

  static EdgeInsets p(double v) => EdgeInsets.all(v);
  static EdgeInsets pxpy(double x, double y) =>
      EdgeInsets.symmetric(horizontal: x, vertical: y);

  // Radius
  static const rMd = 12.0;
  static const rLg = 16.0;
  static BorderRadius br(double r) => BorderRadius.circular(r);

  // Shadow
  static List<BoxShadow> shadowMd = const [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  // Typography
  static const title = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    height: 1.4,
  );

  static const error = TextStyle(
    fontSize: 13,
    color: red600,
  );

  // Helpers
  static SizedBox gap(double v) => SizedBox(height: v);
}
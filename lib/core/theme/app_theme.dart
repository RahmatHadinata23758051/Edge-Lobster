import 'package:flutter/material.dart';

/// Design tokens — clean, restrained, professional.
/// Green used ONLY as accent (active states, normal badges, primary CTA).
/// Everything else is white/gray.
class AppTheme {
  AppTheme._();

  // ─── Primary Accent (used sparingly) ───
  static const Color accent = Color(0xFF16A34A);
  static const Color accentLight = Color(0xFFDCFCE7);

  // ─── Surfaces ───
  static const Color bg = Color(0xFFFAFAFA);       // page background
  static const Color card = Color(0xFFFFFFFF);      // card fill
  static const Color cardHover = Color(0xFFF8FAFC); // subtle hover
  static const Color terminalBg = Color(0xFF0F172A);// console only

  // ─── Borders ───
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF16A34A);

  // ─── Text ───
  static const Color t1 = Color(0xFF111827); // primary
  static const Color t2 = Color(0xFF4B5563); // secondary
  static const Color t3 = Color(0xFF9CA3AF); // muted

  // ─── Status ───
  static const Color ok = Color(0xFF16A34A);
  static const Color warn = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color off = Color(0xFFD1D5DB);

  // ─── Helpers ───
  static BoxDecoration get cardBox => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: border),
  );

  static ThemeData get themeData => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ),
    fontFamily: 'Segoe UI',
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

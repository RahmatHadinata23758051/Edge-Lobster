import 'package:flutter/material.dart';

/// Centralized design tokens for the Lobsense Edge Gateway.
/// Exact premium UI/UX color palette matching the requested screenshot.
class AppTheme {
  AppTheme._();

  // ─── Core Brand Colors ───
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color primaryGreenLight = Color(0xFFDCFCE7);
  static const Color deepGreen = Color(0xFF0F3E32); // Selected sidebar menu bg
  static const Color accentGreen = Color(0xFF22C55E); // Green dots / badges

  // ─── Surfaces ───
  static const Color bg = Color(0xFFF8FAFC);         // Clean body background
  static const Color sidebarBg = Color(0xFFFFFFFF);  // Pure white sidebar
  static const Color card = Color(0xFFFFFFFF);       // Clean card background
  static const Color terminalBg = Color(0xFF0D1117); // Dark black JSON console

  // ─── Borders ───
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // ─── Typography Colors ───
  static const Color t1 = Color(0xFF0F172A); // Active/title dark slate
  static const Color t2 = Color(0xFF475569); // Secondary body
  static const Color t3 = Color(0xFF94A3B8); // Muted labels/timestamps

  // ─── Status Accents ───
  static const Color ok = Color(0xFF22C55E);
  static const Color warn = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color off = Color(0xFFCBD5E1);

  static ThemeData get themeData => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      surface: card,
    ),
    fontFamily: 'Segoe UI',
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF2858C9);
  static const _lightBackground = Color(0xFFF3F5F7);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceSoft = Color(0xFFF7F9FB);
  static const _lightInk = Color(0xFF1C2736);
  static const _lightMuted = Color(0xFF607080);
  static const _lightLine = Color(0xFFDFE5EB);

  static const _darkBackground = Color(0xFF101722);
  static const _darkSurface = Color(0xFF172131);
  static const _darkSurfaceSoft = Color(0xFF202D3F);
  static const _darkInk = Color(0xFFF2F5FA);
  static const _darkMuted = Color(0xFFACB8C7);
  static const _darkLine = Color(0xFF334255);

  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final generated = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;
    final scheme = generated.copyWith(
      primary: dark ? const Color(0xFF9BB7FF) : _seed,
      onPrimary: dark ? const Color(0xFF14213D) : Colors.white,
      secondary: dark ? const Color(0xFF8ED4BE) : const Color(0xFF267D66),
      onSecondary: dark ? const Color(0xFF10251F) : Colors.white,
      surface: dark ? _darkSurface : _lightSurface,
      onSurface: dark ? _darkInk : _lightInk,
      surfaceContainerHighest: dark ? _darkSurfaceSoft : _lightSurfaceSoft,
      outline: dark ? _darkLine : _lightLine,
      outlineVariant: dark ? _darkLine : _lightLine,
      onSurfaceVariant: dark ? _darkMuted : _lightMuted,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? _darkBackground : _lightBackground,
      dividerColor: scheme.outlineVariant,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? _darkBackground : _lightBackground,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? _darkSurfaceSoft : _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 17),
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? _darkSurface : _lightSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: dark ? .22 : .12),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? _darkSurface : _lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? _darkSurfaceSoft : _lightInk,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

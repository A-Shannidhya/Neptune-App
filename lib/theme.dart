import 'package:flutter/material.dart';

/// Centralized blue-centric theme for Neptune Bank.
/// Provides both light and dark variants with carefully curated
/// accessible contrast values.
class NeptuneTheme {
  NeptuneTheme._();

  // Light color scheme (Blue palette)
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1565C0), // Strong Neptune Blue
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF90CAF9),
    onPrimaryContainer: Color(0xFF002F6C),
    secondary: Color(0xFF1976D2),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFBBDEFB),
    onSecondaryContainer: Color(0xFF0D47A1),
    tertiary: Color(0xFF0288D1),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFB3E5FC),
    onTertiaryContainer: Color(0xFF01579B),
    error: Color(0xFFD32F2F),
    onError: Colors.white,
    errorContainer: Color(0xFFFFCDD2),
    onErrorContainer: Color(0xFF8C0B13),
    background: Color(0xFFF5FAFF),
    onBackground: Color(0xFF0A2540),
    surface: Colors.white,
    onSurface: Color(0xFF13324A),
    surfaceVariant: Color(0xFFE1ECF5),
    onSurfaceVariant: Color(0xFF3F5B75),
    outline: Color(0xFF6D88A3),
    outlineVariant: Color(0xFFC2D6E5),
    shadow: Colors.black,
    scrim: Colors.black54,
    inverseSurface: Color(0xFF13324A),
    onInverseSurface: Color(0xFFE2F3FF),
    inversePrimary: Color(0xFF90CAF9),
  );

  // Dark color scheme derived from light for consistency.
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF90CAF9),
    onPrimary: Color(0xFF00325B),
    primaryContainer: Color(0xFF0D47A1),
    onPrimaryContainer: Color(0xFFD3E9FF),
    secondary: Color(0xFF82B1FF),
    onSecondary: Color(0xFF002F6C),
    secondaryContainer: Color(0xFF1565C0),
    onSecondaryContainer: Color(0xFFE1F0FF),
    tertiary: Color(0xFF4FC3F7),
    onTertiary: Color(0xFF003545),
    tertiaryContainer: Color(0xFF01579B),
    onTertiaryContainer: Color(0xFFCAF2FF),
    error: Color(0xFFEF9A9A),
    onError: Color(0xFF561114),
    errorContainer: Color(0xFF8C0B13),
    onErrorContainer: Color(0xFFFFDAD5),
    background: Color(0xFF0F1C26),
    onBackground: Color(0xFFCEE7FF),
    surface: Color(0xFF122330),
    onSurface: Color(0xFFCCE5F9),
    surfaceVariant: Color(0xFF3F5B75),
    onSurfaceVariant: Color(0xFFB5C9D9),
    outline: Color(0xFF7F96AA),
    outlineVariant: Color(0xFF2D4459),
    shadow: Colors.black,
    scrim: Colors.black87,
    inverseSurface: Color(0xFFE2F3FF),
    onInverseSurface: Color(0xFF152E42),
    inversePrimary: Color(0xFF1565C0),
  );

  static ThemeData light() => _base(lightColorScheme);
  static ThemeData dark() => _base(darkColorScheme);

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = Typography.englishLike2021.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Prefer surface over deprecated background in scaffold.
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(letterSpacing: 0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        shape: const StadiumBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Use surface with low alpha instead of deprecated surfaceVariant field usage.
        fillColor: scheme.surface.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.45)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.primary.withOpacity(0.15),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        tileColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline.withOpacity(0.4);
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withOpacity(0.25),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withOpacity(0.15),
      ),
    );
  }
}

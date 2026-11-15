import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
}

class AppTheme {
  static const _light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFDC2626),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFEE2E2),
    onPrimaryContainer: Color(0xFF7F1D1D),
    secondary: Color(0xFF64748B),
    onSecondary: Colors.white,
    error: Color(0xFFB91C1C),
    onError: Colors.white,
    surface: Color(0xFFF8FAFC),
    onSurface: Color(0xFF0F172A),
    onSurfaceVariant: Color(0xFF64748B),
    outline: Color(0xFF94A3B8),
    outlineVariant: Color(0xFFE2E8F0),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainer: Color(0xFFF1F5F9),
    surfaceContainerHigh: Color(0xFFF1F5F9),
    surfaceContainerHighest: Color(0xFFE9EEF5),
  );

  static const _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFDC2626),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF4C1D1D),
    onPrimaryContainer: Color(0xFFFEE2E2),
    secondary: Color(0xFF94A3B8),
    onSecondary: Colors.black,
    error: Color(0xFFF87171),
    onError: Colors.black,
    surface: Color(0xFF161616),
    onSurface: Color(0xFFF8FAFC),
    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0xFF64748B),
    outlineVariant: Color(0xFF2E2E2E),
    surfaceContainerLowest: Color(0xFF1E1E1E),
    surfaceContainerLow: Color(0xFF1B1B1B),
    surfaceContainer: Color(0xFF202020),
    surfaceContainerHigh: Color(0xFF262626),
    surfaceContainerHighest: Color(0xFF2D2D2D),
  );

  static ThemeData light() => _build(_light);
  static ThemeData dark() => _build(_dark);

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.primary : scheme.outline.withValues(alpha: 0.5),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? scheme.primary : null),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}

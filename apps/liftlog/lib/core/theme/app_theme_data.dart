import 'package:flutter/material.dart';

class AppThemeData {
  static ThemeData get light {
    const ColorScheme scheme = ColorScheme.light(
      primary: Color(0xFF0A5BFF),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCE6FF),
      onPrimaryContainer: Color(0xFF001A52),
      secondary: Color(0xFFFF6A00),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFE3D1),
      onSecondaryContainer: Color(0xFF4F1E00),
      tertiary: Color(0xFF00A86B),
      onTertiary: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF131A24),
      error: Color(0xFFB3261E),
      onError: Colors.white,
    );

    return _buildTheme(
      scheme: scheme,
      scaffoldColor: const Color(0xFFF3F8F6),
      appBarColor: const Color(0xFFF3F8F6),
      cardColor: Colors.white,
    );
  }

  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme.dark(
      primary: Color(0xFF9DB5FF),
      onPrimary: Color(0xFF002A86),
      primaryContainer: Color(0xFF103FAF),
      onPrimaryContainer: Color(0xFFE0E8FF),
      secondary: Color(0xFFFFA66F),
      onSecondary: Color(0xFF4B2100),
      secondaryContainer: Color(0xFF6B330A),
      onSecondaryContainer: Color(0xFFFFE3D1),
      tertiary: Color(0xFF69E3B2),
      onTertiary: Color(0xFF003824),
      surface: Color(0xFF0F1420),
      onSurface: Color(0xFFE7EDF9),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
    );

    return _buildTheme(
      scheme: scheme,
      scaffoldColor: const Color(0xFF0A1211),
      appBarColor: const Color(0xFF0A1211),
      cardColor: const Color(0xFF0E1F1C),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color scaffoldColor,
    required Color appBarColor,
    required Color cardColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldColor,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final Color color = states.contains(WidgetState.selected)
              ? scheme.onSecondaryContainer
              : scheme.onSurfaceVariant;
          return IconThemeData(color: color);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final Color color = states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant;
          return TextStyle(
            color: color,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selectedColor: scheme.secondaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(height: 1.3),
        bodyMedium: TextStyle(height: 1.3),
      ),
    );
  }
}

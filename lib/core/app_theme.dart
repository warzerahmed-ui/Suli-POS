import 'package:flutter/material.dart';

/// ڕەنگەکانی بنەڕەتی سیستەم.
/// English: brand palette shared by every screen.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF14795F);
  static const Color primaryDark = Color(0xFF083F32);
  static const Color secondary = Color(0xFFE39B2D);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);
  static const Color surfaceLight = Color(0xFFF4F7F6);
  static const Color surfaceDark = Color(0xFF101C19);
}

/// ڕەنگەکانی دۆخ کە لەگەڵ دۆخی تاریک/ڕووناک دەگونجێن.
/// English: semantic colours, brightened automatically in dark mode.
class StatusColors {
  const StatusColors._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color success(BuildContext context) =>
      _isDark(context) ? const Color(0xFF66BB6A) : AppColors.success;

  static Color warning(BuildContext context) =>
      _isDark(context) ? const Color(0xFFFFB74D) : AppColors.warning;

  static Color danger(BuildContext context) =>
      _isDark(context) ? const Color(0xFFEF5350) : AppColors.danger;

  static Color info(BuildContext context) =>
      _isDark(context) ? const Color(0xFF64B5F6) : AppColors.info;
}

/// ڕووکاری ڕووناک و تاریکی سیستەم.
/// English: light + dark Material 3 themes.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFF4DB6A0) : AppColors.primary,
          secondary: AppColors.secondary,
          error: isDark ? const Color(0xFFEF5350) : AppColors.danger,
          surface: isDark ? const Color(0xFF16221F) : Colors.white,
        );

    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return _components(
      base: ThemeData(colorScheme: scheme, useMaterial3: true),
      scheme: scheme,
      isDark: isDark,
      border: border,
    );
  }

  static ThemeData _components({
    required ThemeData base,
    required ColorScheme scheme,
    required bool isDark,
    required OutlineInputBorder border,
  }) {
    return base.copyWith(
      scaffoldBackgroundColor: isDark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? scheme.surface : Colors.white,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? scheme.surface : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        isDense: true,
        fillColor: isDark ? const Color(0xFF1B2926) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? scheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? scheme.surface : Colors.white,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? scheme.surface : Colors.white,
        indicatorColor: scheme.primary.withValues(alpha: 0.15),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: isDark ? scheme.surface : Colors.white,
      ),
    );
  }
}

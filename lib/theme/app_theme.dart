import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1565C0); // deep blue
  static const Color primaryDark = Color(0xFF0B3C78); // near-navy
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color accent = Color(0xFF29B6F6); // light sky blue accent
  static const Color background = Color(0xFFF2F7FD); // near-white blue tint
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF0F2A47);
  static const Color textSecondary = Color(0xFF4A6B8A);
  static const Color safetyRed = Color(0xFFD32F2F); // for safety tip accents

  /// Header gradient used on the gallery app bar and detail hero overlay.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, accent],
  );
}

class CategoryStyle {
  final IconData icon;

  const CategoryStyle(this.icon);

  static const Map<String, CategoryStyle> _styles = {
    'Glassware': CategoryStyle(Icons.science_outlined),
    'Heating': CategoryStyle(Icons.local_fire_department_outlined),
    'Measuring': CategoryStyle(Icons.straighten_outlined),
    'Filtration': CategoryStyle(Icons.filter_alt_outlined),
    'Cleaning': CategoryStyle(Icons.cleaning_services_outlined),
    'Mixing': CategoryStyle(Icons.blender_outlined),
    'Preparation': CategoryStyle(Icons.construction_outlined),
    'Storage': CategoryStyle(Icons.inventory_2_outlined),
    'Safety Gears': CategoryStyle(Icons.shield_outlined),
  };

  static const CategoryStyle _fallback = CategoryStyle(Icons.category_outlined);

  static IconData iconFor(String category) =>
      (_styles[category] ?? _fallback).icon;
}

/// Color tokens for the Laboratory Safety & Hazard module.
///
/// Previously lived in its own theme/safety_colors.dart with a fully
/// separate palette. Now consolidated here — `red` and `blue` are no
/// longer duplicate hex values; they delegate to the closest existing
/// AppColors token (AppColors.safetyRed / AppColors.primaryDark) so
/// there's one source of truth for those two, while the rest of the
/// safety palette (ink/paper/yellow/orange/green/purple/black) stays
/// distinct since nothing in AppColors is close enough to reuse.
class SafetyColors {
  SafetyColors._();

  static const ink = Color(0xFF10151A);
  static const paper = Color(0xFFE7ECEE);
  static const paperSoft = Color(0xFFF2F5F6);
  static const paperLine = Color(0xFFC7D1D5);

  static const yellow = Color(0xFFF4B400);
  static const orange = Color(0xFFE2572B);
  static const green = Color(0xFF3C7A5C);
  static const purple = Color(0xFF5B4E9C);
  static const black = Color(0xFF1B1D22);

  // Reused from AppColors instead of duplicated — close enough in hue
  // and the same semantic role (danger red / primary-info blue).
  static Color get red => AppColors.safetyRed;
  static Color get blue => AppColors.primaryDark;

  /// Convenience map so data files can just reference a category tag.
  /// No longer `const` since `red`/`blue` are now getters, not literals.
  static final Map<String, Color> byCategory = {
    'do': green,
    'dont': red,
    'flammable': orange,
    'corrosive': blue,
    'toxic': black,
    'oxidizer': yellow,
    'explosive': black,
    'health': purple,
    'gas': blue,
    'eco': green,
    'prohibition': red,
    'warning': yellow,
    'mandatory': blue,
    'emergency': green,
  };
}

/// Type SCALE for the Laboratory Safety & Hazard module — hero/section/
/// tile/code sizing stays distinct on purpose, since these labels still
/// need to read as a clear hierarchy within the safety screens. The
/// FONT does not: this used to pull in Oswald/Inter/IBM Plex Mono via
/// google_fonts, which made the module look like a different app.
/// These are now plain const TextStyles with no fontFamily set, so each
/// one inherits Roboto from the app-wide Theme/DefaultTextStyle, same
/// as every other screen. No longer requires the google_fonts package.
class SafetyTextStyles {
  SafetyTextStyles._();

  static const TextStyle heroTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: Colors.white,
    height: 1.05,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: SafetyColors.ink,
  );

  static const TextStyle tileTitle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: SafetyColors.ink,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: Color(0xFF232A30),
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.5,
    color: Color(0xFF5B6A72),
    height: 1.4,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: Color(0xFF8B98A0),
  );

  static const TextStyle code = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: Color(0xFF8B98A0),
  );
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 3,
        shadowColor: AppColors.primaryDark.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

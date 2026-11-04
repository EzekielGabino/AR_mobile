import 'package:flutter/material.dart';

class AppColors {
  // Brand blues from ColorHunt, with a lighter page canvas for readability.
  // #091540 · #1B2CC1 · #7692FF · #ABD2FA
  static const Color primary = Color(0xFF1B2CC1); // vivid indigo
  static const Color primaryDark = Color(0xFF091540); // navy (app bars / brand)
  static const Color primaryLight = Color(0xFF7692FF); // periwinkle
  static const Color primaryGray = Color(0xFF5C6578);
  static const Color accent = Color(0xFF3D6FD9); // stronger accent on light UI
  static const Color accentSoft = Color(0xFFABD2FA); // soft sky
  static const Color background = Color(0xFFE8F1FA); // light blue-grey canvas
  static const Color cardBackground = Color(0xFFFFFFFF); // white cards
  static const Color textPrimary = Color(0xFF0A2F45); // dark navy text
  static const Color textSecondary = Color(0xFF3D5A73); // muted blue-grey
  static const Color safetyRed = Color(0xFFD32F2F); // hazard only

  /// Header gradient used on the gallery app bar and detail hero overlay.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );

  /// Accent strip / highlight gradient.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryLight, accentSoft],
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
  static const gray = Color.fromRGBO(182, 179, 215, 0.729);

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

  static const TextStyle sectionTitleDark = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: SafetyColors.ink,
  );

  static const TextStyle sectionTitleLight = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: SafetyColors.paperLine,
  );

  static const TextStyle tileTitleDark = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: SafetyColors.ink,
    height: 1.2,
  );

  static const TextStyle tileTitleLight = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: SafetyColors.paperLine,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: Color(0xFF232A30),
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.5,
    color: SafetyColors.gray,
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
    final scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.accentSoft,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.primaryDark,
      secondaryContainer: AppColors.accentSoft,
      onSecondaryContainer: AppColors.primaryDark,
      surface: AppColors.cardBackground,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: Color(0xFFD6E6F7),
      error: AppColors.safetyRed,
      onError: Colors.white,
      outline: AppColors.primaryLight.withValues(alpha: 0.55),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xB3FFFFFF),
        indicatorColor: AppColors.accentSoft,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
        // Remove Material 3 horizontal line under tabs
        dividerColor: Colors.transparent,
        dividerHeight: 0,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.35),
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryLight.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryLight.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.primaryLight.withValues(alpha: 0.45),
        thickness: 1,
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
        bodyLarge: const TextStyle(color: AppColors.textPrimary),
        labelLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

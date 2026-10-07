import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppRadius {
  static const card = 12.0;
  static const control = 10.0;
  static const pill = 20.0;
}

enum AppSurface { grouped, card, floating }

class AppGrid {
  static const featureAspectRatio = 1.9;
}

class AppShadow {
  static const floating = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

class AppColors {
  static const ashGrey = Color(0xFFCAD2C5);
  static const background = Color(0xFFF4F6F4);
  static const mutedTeal = Color(0xFF84A98C);
  static const deepTeal = Color(0xFF52796F);
  static const darkSlate = Color(0xFF354F52);
  static const charcoal = Color(0xFF2F3E46);
  static const stroke = Color(0xFFD1DCD6);
  static const textSecondary = Color(0xFF4F6566);
  static const surface = Colors.white;

  static const positiveBg = Color(0xFFE8F5E9);
  static const positiveFg = Color(0xFF2E7D32);
  static const dangerBg = Color(0xFFFDECEC);
  static const danger = Color(0xFFD32F2F);
}

class AppTheme {
  static ThemeData get light => _build();

  static ThemeData get dark => _build();

  static ThemeData _build() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.deepTeal,
          brightness: Brightness.light,
          secondary: AppColors.mutedTeal,
        ).copyWith(
          primary: AppColors.deepTeal,
          onPrimary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.charcoal,
          onSurfaceVariant: AppColors.textSecondary,
          outlineVariant: AppColors.stroke,
          error: AppColors.danger,
          errorContainer: AppColors.dangerBg,
          onErrorContainer: AppColors.danger,
        );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.stroke),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.deepTeal,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.stroke),
          foregroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.deepTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.deepTeal,
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
        color: AppColors.stroke,
      ),
    );

    return base.copyWith(textTheme: _textTheme(base.textTheme));
  }

  static TextTheme _textTheme(TextTheme base) {
    final montserrat = GoogleFonts.montserratTextTheme(base);
    return montserrat.copyWith(
      displaySmall: montserrat.displaySmall?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.charcoal,
      ),
      headlineSmall: montserrat.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
      titleLarge: montserrat.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
      titleMedium: montserrat.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
      titleSmall: montserrat.titleSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
      bodyLarge: montserrat.bodyLarge?.copyWith(
        fontSize: 15,
        color: AppColors.charcoal,
      ),
      bodyMedium: montserrat.bodyMedium?.copyWith(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      bodySmall: montserrat.bodySmall?.copyWith(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
      labelLarge: montserrat.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
      ),
      labelMedium: montserrat.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

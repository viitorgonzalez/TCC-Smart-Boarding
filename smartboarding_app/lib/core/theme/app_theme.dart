import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppRadius {
  static const card = 12.0;
  static const control = 10.0;
}

class AppTheme {
  // Paleta fechada na reforma 2026-08-14 (docs/spec.md §4.5).
  static const _ashGrey = Color(0xFFCAD2C5); // fundo light
  static const _mutedTeal = Color(0xFF84A98C); // verde geral
  static const _deepTeal = Color(0xFF52796F); // verde geral / seed
  static const _darkSlate = Color(0xFF354F52); // tom escuro de apoio
  static const _charcoalBlue = Color(0xFF2F3E46); // fundo dark

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    // surfaceContainerHighest só é sobrescrito no dark: _darkSlate é
    // visivelmente distinto de _charcoalBlue (fundo). No light, deixar o
    // Material derivar do seed em vez de igualar a _ashGrey (fundo) — senão
    // o fillColor de inputDecorationTheme (abaixo) some contra o fundo.
    final scheme = ColorScheme.fromSeed(
      seedColor: _deepTeal,
      brightness: brightness,
      secondary: _mutedTeal,
    ).copyWith(
      surface: isDark ? _charcoalBlue : _ashGrey,
      surfaceContainerHighest: isDark ? _darkSlate : null,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),
      dividerTheme: const DividerThemeData(space: 1),
    );
    // Montserrat (docs/spec.md §4.5) por cima do TextTheme já derivado do
    // colorScheme acima — preserva as cores de texto por brightness.
    return base.copyWith(
      textTheme: GoogleFonts.montserratTextTheme(base.textTheme),
    );
  }
}

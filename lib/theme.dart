import 'package:flutter/material.dart';

// ── Design tokens (AGENTS.md palette) ────────────────────────────────────────

const kBoard = Color(0xFF1B2B26);
const kBoardDeep = Color(0xFF132019);
const kChalk = Color(0xFFF1F3EC);
const kPaper = Color(0xFFECEEEA);
const kCard = Color(0xFFF7F8F4);
const kInk = Color(0xFF1A231F);
const kInkSoft = Color(0xFF4E5A53);
const kRule = Color(0xFFCBD2CB);
const kBrass = Color(0xFFC2911E);
const kSignal = Color(0xFF2F6E4E);
const kAlert = Color(0xFFA93325);

/// Builds the app-wide [ThemeData] from the AGENTS.md design tokens.
/// Uses system default sans-serif — no custom font download needed on stage.
ThemeData kabadiTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: kBrass,
      onPrimary: kChalk,
      primaryContainer: kBoard,
      onPrimaryContainer: kChalk,
      secondary: kSignal,
      onSecondary: kChalk,
      secondaryContainer: kCard,
      onSecondaryContainer: kInk,
      tertiary: kInkSoft,
      onTertiary: kChalk,
      tertiaryContainer: kRule,
      onTertiaryContainer: kInk,
      error: kAlert,
      onError: kChalk,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF93000A),
      surface: kPaper,
      onSurface: kInk,
      surfaceContainerHighest: kCard,
      onSurfaceVariant: kInkSoft,
      outline: kRule,
      outlineVariant: kRule,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: kInk,
      onInverseSurface: kChalk,
      inversePrimary: kBrass,
    ),
    scaffoldBackgroundColor: kPaper,
    // Primary action buttons: full-width, 64dp tall, brass background.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBrass,
        foregroundColor: kChalk,
        minimumSize: const Size(double.infinity, 64),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    // Text button style for secondary actions.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kBrass,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kRule),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBoard,
      foregroundColor: kChalk,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kChalk,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: const DividerThemeData(color: kRule, thickness: 1),
    textTheme: const TextTheme(
      // Large price / weight numerals: 36–48sp bold
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: kInk,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: kInk,
      ),
      // Screen headings
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: kInk,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: kInk,
      ),
      // Body — minimum 18sp per AGENTS.md
      bodyLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: kInk,
      ),
      bodyMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: kInk,
      ),
      // Labels on buttons, chips, badges
      labelLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kInk,
      ),
      labelSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: kInkSoft,
      ),
    ),
  );
}

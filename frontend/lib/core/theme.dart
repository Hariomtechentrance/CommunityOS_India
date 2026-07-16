import 'package:flutter/material.dart';

/// Brand colors from the NIKAT logo (two figures forming a heart - orange
/// and navy - shaking hands).
const nikatOrange = Color(0xFFE8720C);
const nikatNavy = Color(0xFF154C79);
const nikatNavyDark = Color(0xFF0D3454);
const nikatScaffoldBg = Color(0xFFF5F7FA);

/// Hero/banner gradient used on marketing-style surfaces (landing page,
/// login screen) - keeps those "first impression" screens visually distinct
/// from the flatter, content-dense app screens.
const nikatHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [nikatNavyDark, nikatNavy],
);

final ColorScheme _nikatColorScheme = ColorScheme.fromSeed(
  seedColor: nikatNavy,
  brightness: Brightness.light,
).copyWith(
  primary: nikatNavy,
  onPrimary: Colors.white,
  secondary: nikatOrange,
  onSecondary: Colors.white,
  tertiary: nikatOrange,
  surface: Colors.white,
);

final nikatTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _nikatColorScheme,
  scaffoldBackgroundColor: nikatScaffoldBg,
  splashFactory: InkRipple.splashFactory,

  appBarTheme: const AppBarTheme(
    backgroundColor: nikatScaffoldBg,
    foregroundColor: nikatNavy,
    elevation: 0,
    scrolledUnderElevation: 1,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: nikatNavy,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    iconTheme: IconThemeData(color: nikatNavy),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: nikatOrange,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: nikatNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: nikatNavy,
      side: const BorderSide(color: nikatNavy, width: 1.4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: nikatNavy,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),

  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(foregroundColor: nikatNavy),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: nikatOrange,
    foregroundColor: Colors.white,
    elevation: 3,
  ),

  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    shadowColor: nikatNavy.withValues(alpha: 0.12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: nikatNavy.withValues(alpha: 0.07)),
    ),
    margin: EdgeInsets.zero,
  ),

  chipTheme: ChipThemeData(
    backgroundColor: nikatNavy.withValues(alpha: 0.06),
    labelStyle: const TextStyle(color: nikatNavy, fontWeight: FontWeight.w600, fontSize: 12),
    side: BorderSide.none,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: nikatNavy.withValues(alpha: 0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: nikatNavy.withValues(alpha: 0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: nikatNavy, width: 2),
    ),
  ),

  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? nikatNavy : Colors.white,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : nikatNavy,
      ),
      side: WidgetStateProperty.all(BorderSide(color: nikatNavy.withValues(alpha: 0.3))),
    ),
  ),

  dividerTheme: DividerThemeData(color: nikatNavy.withValues(alpha: 0.08), space: 1),

  progressIndicatorTheme: const ProgressIndicatorThemeData(color: nikatOrange),
);

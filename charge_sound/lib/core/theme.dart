import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m3e_design/m3e_design.dart';

const seedColor = Color(0xFF22C55E);

TextTheme _buildTextTheme(TextTheme base) {
  final nunitoStyles = GoogleFonts.nunitoTextTheme(base);
  final dmSansStyles = GoogleFonts.dmSansTextTheme(base);

  return base.copyWith(
    displayLarge: nunitoStyles.displayLarge?.copyWith(fontWeight: FontWeight.w800),
    displayMedium: nunitoStyles.displayMedium?.copyWith(fontWeight: FontWeight.w800),
    displaySmall: nunitoStyles.displaySmall?.copyWith(fontWeight: FontWeight.w800),
    headlineLarge: nunitoStyles.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
    headlineMedium: nunitoStyles.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
    headlineSmall: nunitoStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    titleLarge: nunitoStyles.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: dmSansStyles.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: dmSansStyles.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: dmSansStyles.bodyLarge,
    bodyMedium: dmSansStyles.bodyMedium,
    bodySmall: dmSansStyles.bodySmall,
    labelLarge: dmSansStyles.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: dmSansStyles.labelMedium?.copyWith(fontWeight: FontWeight.w500),
    labelSmall: dmSansStyles.labelSmall?.copyWith(fontWeight: FontWeight.w500),
  );
}

ThemeData buildLightTheme(ColorScheme? dynamicScheme) {
  final colorScheme = dynamicScheme ??
      ColorScheme.fromSeed(seedColor: seedColor);
  final base = colorScheme.toM3EThemeData();
  return base.copyWith(
    textTheme: _buildTextTheme(base.textTheme),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 2,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorShape: const StadiumBorder(),
      indicatorColor: colorScheme.secondaryContainer,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
  );
}

ThemeData buildDarkTheme(ColorScheme? dynamicScheme) {
  final colorScheme = dynamicScheme ??
      ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark);
  final base = colorScheme.toM3EThemeData();
  return base.copyWith(
    textTheme: _buildTextTheme(base.textTheme),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorShape: const StadiumBorder(),
      indicatorColor: colorScheme.secondaryContainer,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
  );
}

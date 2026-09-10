import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgColor = Color(0xFF0A0A0A);
  static const Color primaryColor = Color(0xFFC4FFAE);
  static const Color secondaryColor = Color(0xFF15161A);
  static const Color thirdColor = Color(0xFF1C1C1E);
  static const Color btnGreen = Color(0xFFC4FFAE);
  static const Color btnRed = Color(0xFFFF0000);
  static const Color redTitle = Color(0xFFFF3B3B);
  static const Color ondaColor = Color(0xFF212226);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      canvasColor: bgColor,
      cardColor: thirdColor,

      colorScheme: const ColorScheme.dark(
        surface: bgColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: thirdColor,
        error: btnRed,
        onSurface: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: redTitle,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: ondaColor,
        thumbColor: primaryColor,
        overlayColor: Color(0x29C4FFAE),
        trackHeight: 4.0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnGreen,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

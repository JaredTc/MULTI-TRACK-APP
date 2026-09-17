import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'MultiTracks';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'A multi-track audio player for Flutter.';

  static const String appAuthor = 'Your Name';
  static const String titleDefault = '';

  static const List<Color> trackColors = [
    Color.fromARGB(125, 139, 0, 0),
    Color.fromARGB(127, 46, 139, 86),
    Color.fromARGB(118, 76, 0, 130),
    Color.fromARGB(113, 210, 105, 30),
    Color.fromARGB(120, 0, 136, 255),
    Color.fromARGB(110, 218, 165, 32),
  ];
  static final List<String> keyNotes = [
    'C / DO',
    'C# / DO#',
    'D / RE',
    'Eb / MIb',
    'E / MI',
    'F / FA',
    'F# / FA#',
    'G / SOL',
    'Ab / LAb',
    'A / LA',
    'Bb / SIb',
    'B / SI',
  ];
}

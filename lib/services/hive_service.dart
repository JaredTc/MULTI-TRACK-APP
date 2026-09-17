// services/hive_service.dart

import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _sessionsBoxName = 'sessions_box';
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_sessionsBoxName);
  }

  static Future<void> saveSession(Map<String, dynamic> sessionData) async {
    final box = Hive.box<Map>(_sessionsBoxName);
    final String id = sessionData['id'];
    await box.put(id, sessionData);
  }

  static List<Map<String, dynamic>> getAllSessions() {
    final box = Hive.box<Map>(_sessionsBoxName);
    return box.values.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Map<String, dynamic>? getSession(String id) {
    final box = Hive.box<Map>(_sessionsBoxName);
    final sessionData = box.get(id);
    return sessionData != null ? Map<String, dynamic>.from(sessionData) : null;
  }

  static Future<void> deleteSession(String id) async {
    final box = Hive.box<Map>(_sessionsBoxName);
    await box.delete(id);
  }
}

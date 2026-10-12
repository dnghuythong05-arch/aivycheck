import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceStore {
  static const storageKey = 'aivycheck_demo_v2';
  static const legacyKey = 'aivycheck_demo_v1';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get preferences =>
      _preferences ??= SharedPreferencesAsync();

  Future<Map<String, dynamic>?> read() async {
    final current = await preferences.getString(storageKey);
    final text = current ?? await preferences.getString(legacyKey);

    if (text == null) return null;

    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  Future<void> write(Map<String, dynamic> data) async {
    await preferences.setString(storageKey, jsonEncode(data));
  }
}

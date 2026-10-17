import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_dom.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  static final instance = ThemeController(SharedPreferencesAsync());

  static const storageKey = 'aivycheck_theme_mode_v1';

  final SharedPreferencesAsync preferences;
  final ValueNotifier<bool> saving = ValueNotifier(false);

  ThemeController(this.preferences) : super(ThemeMode.light);

  bool get isDark => value == ThemeMode.dark;

  Future<void> load() async {
    try {
      final saved = await preferences.getString(storageKey);

      value = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      value = ThemeMode.light;
    }

    applyBrowserTheme(isDark);
  }

  Future<void> toggle() async {
    if (saving.value) return;

    saving.value = true;

    try {
      final next = isDark ? ThemeMode.light : ThemeMode.dark;

      await preferences.setString(
        storageKey,
        next == ThemeMode.dark ? 'dark' : 'light',
      );

      value = next;
      applyBrowserTheme(isDark);
    } finally {
      saving.value = false;
    }
  }

  @override
  void dispose() {
    saving.dispose();
    super.dispose();
  }
}

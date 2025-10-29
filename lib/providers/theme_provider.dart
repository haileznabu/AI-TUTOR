import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? true;
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('Error loading theme: $e');
      state = ThemeMode.dark;
    }
  }

  Future<void> toggleTheme() async {
    try {
      final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      state = newMode;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', newMode == ThemeMode.dark);
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

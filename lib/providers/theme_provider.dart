import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  SharedPreferences? _prefsCache;
  bool _isLoading = false;

  Future<SharedPreferences> _getPrefs() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  Future<void> _loadTheme() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final prefs = await _getPrefs();
      final isDark = prefs.getBool('isDarkMode') ?? true;
      if (mounted) {
        state = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
      if (mounted) {
        state = ThemeMode.dark;
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> toggleTheme() async {
    try {
      final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

      if (mounted) {
        state = newMode;
      }

      final prefs = await _getPrefs();
      await prefs.setBool('isDarkMode', newMode == ThemeMode.dark);
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _load();
  }

  void _load() {
    final box = Hive.box<String>(AppConstants.settingsBox);
    final val = box.get(AppConstants.themeKey);
    if (val == 'dark') {
      state = ThemeMode.dark;
    } else if (val == 'light') {
      state = ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    final box = Hive.box<String>(AppConstants.settingsBox);
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await box.put(AppConstants.themeKey, 'light');
    } else {
      state = ThemeMode.dark;
      await box.put(AppConstants.themeKey, 'dark');
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

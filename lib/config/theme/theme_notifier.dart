import 'package:flutter/material.dart';
import '../data/local/app_data.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier()
      : super(
    (AppData().getIsDarkTheme() ?? false)
        ? ThemeMode.dark
        : ThemeMode.light,
  );

  void toggleTheme(bool isDark) {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
    AppData().setDarkTheme(isDark);
  }
}
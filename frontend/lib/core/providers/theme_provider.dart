import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkModeInherited extends InheritedWidget {
  final bool isDarkMode;

  const DarkModeInherited({
    super.key,
    required this.isDarkMode,
    required super.child,
  });

  static DarkModeInherited? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DarkModeInherited>();
  }

  static DarkModeInherited of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No DarkModeInherited found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(DarkModeInherited oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}

extension DarkModeExtension on BuildContext {
  bool get isDarkMode =>
      DarkModeInherited.maybeOf(this)?.isDarkMode ??
      Theme.of(this).brightness == Brightness.dark;
}

const String _themeModeKey = 'theme_mode';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  if (themeMode == ThemeMode.system) {
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }
  return themeMode == ThemeMode.dark;
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeModeKey);
      if (savedTheme != null) {
        state = _themeModeFromString(savedTheme);
      }
    } catch (e) {
      state = ThemeMode.system;
    }
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeModeToString(state));
    } catch (e) {
      // Silently fail
    }
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.light;
    }
    _saveTheme();
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _saveTheme();
  }

  bool get isDarkMode {
    if (state == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return state == ThemeMode.dark;
  }
}

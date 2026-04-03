import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModeKey = 'theme_mode';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModeKey);
    if (saved != null) {
      state = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.dark);
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  void toggle() => setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  bool get isDark => state == ThemeMode.dark;
}

class BdaiTheme {
  static const Color accent = Color(0xFF00C896);
  static const Color accentDark = Color(0xFF009970);
  static const Color userBubble = Color(0xFF1F6FEB);

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'HindSiliguri',
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: const Color(0xFF161B22),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF8B949E)),
          titleTextStyle: TextStyle(
            fontFamily: 'HindSiliguri',
            color: Color(0xFFE6EDF3),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardColor: const Color(0xFF161B22),
        dividerColor: const Color(0xFF30363D),
      );

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'HindSiliguri',
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF555555)),
          titleTextStyle: TextStyle(
            fontFamily: 'HindSiliguri',
            color: Color(0xFF1A1A1A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE0E0E0),
      );
}

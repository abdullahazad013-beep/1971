import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bdai/core/app_strings.dart';

const String _langKey = 'app_language';

final languageProvider =
    StateNotifierProvider<LanguageNotifier, String>((ref) => LanguageNotifier());

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('bn') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_langKey) ?? 'bn';
  }

  Future<void> setLanguage(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
  }

  void toggle() => setLanguage(state == 'bn' ? 'en' : 'bn');
}

/// Helper: get string by key for current language
String s(WidgetRef ref, String key) {
  final lang = ref.watch(languageProvider);
  return (lang == 'bn' ? AppStrings.bn[key] : AppStrings.en[key]) ??
      AppStrings.en[key] ??
      key;
}

/// Non-widget version
String sLang(String lang, String key) {
  return (lang == 'bn' ? AppStrings.bn[key] : AppStrings.en[key]) ??
      AppStrings.en[key] ??
      key;
}

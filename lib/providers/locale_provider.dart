import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_providers.dart';

const String _kLocalePrefKey = 'selected_locale';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final savedCode = prefs.getString(_kLocalePrefKey);
      if (savedCode == 'hi' || savedCode == 'en') {
        return Locale(savedCode!);
      }
    } catch (_) {
      // Fallback to default
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state == newLocale) return;
    state = newLocale;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_kLocalePrefKey, newLocale.languageCode);
    } catch (_) {}
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

import 'package:flutter/widgets.dart';

Locale resolveAppLocale(List<Locale>? preferredLocales) {
  for (final locale in preferredLocales ?? const <Locale>[]) {
    if (locale.languageCode == 'en') return const Locale('en');
    if (locale.languageCode == 'pt' && locale.countryCode == 'BR') {
      return const Locale('pt', 'BR');
    }
  }
  return const Locale('pt', 'BR');
}

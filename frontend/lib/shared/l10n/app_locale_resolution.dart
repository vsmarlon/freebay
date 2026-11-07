import 'package:flutter/widgets.dart';

Locale resolveAppLocale(
  List<Locale>? preferredLocales, {
  String preference = 'system',
}) {
  if (preference == 'en') return const Locale('en');
  if (preference == 'pt_BR') return const Locale('pt', 'BR');
  for (final locale in preferredLocales ?? const <Locale>[]) {
    if (locale.languageCode == 'en') return const Locale('en');
    if (locale.languageCode == 'pt') return const Locale('pt', 'BR');
  }
  return const Locale('pt', 'BR');
}

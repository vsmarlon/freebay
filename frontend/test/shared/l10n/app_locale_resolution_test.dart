import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/l10n/app_locale_resolution.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  test(
    'base Portuguese uses translated messages rather than English',
    () async {
      final strings = await AppLocalizations.delegate.load(const Locale('pt'));
      expect(strings.authLogin, 'Entrar');
      expect(strings.commonCancel, 'Cancelar');
    },
  );

  group('resolveAppLocale', () {
    test('selects English for English device locales', () {
      expect(resolveAppLocale(const [Locale('en', 'US')]), const Locale('en'));
    });

    test('selects Brazilian Portuguese for pt-BR', () {
      expect(
        resolveAppLocale(const [Locale('pt', 'BR')]),
        const Locale('pt', 'BR'),
      );
    });

    test('falls back to pt-BR when no supported language is requested', () {
      expect(
        resolveAppLocale(const [Locale('fr', 'FR')]),
        const Locale('pt', 'BR'),
      );
    });

    test('continues through device preferences to a supported locale', () {
      expect(
        resolveAppLocale(const [Locale('fr', 'FR'), Locale('en', 'GB')]),
        const Locale('en'),
      );
    });
  });
}

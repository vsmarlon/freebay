import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/shared/services/biometric_key_service.dart';
import 'package:freebay/shared/services/storage_service.dart';

part 'app_locale_preference_provider.g.dart';

const _localePreferences = {'system', 'pt_BR', 'en'};

@Riverpod(keepAlive: true)
class AppLocalePreference extends _$AppLocalePreference {
  @override
  String build() {
    final stored = StorageService.getLocalePreferenceSync();
    final normalized = _localePreferences.contains(stored) ? stored : 'system';
    BiometricKeyService.setLocalePreference(normalized);
    return normalized;
  }

  Future<void> setPreference(String preference) async {
    final normalized = _localePreferences.contains(preference)
        ? preference
        : 'system';
    await StorageService.setLocalePreference(normalized);
    BiometricKeyService.setLocalePreference(normalized);
    state = normalized;
  }
}

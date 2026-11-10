// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_locale_preference_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppLocalePreference)
final appLocalePreferenceProvider = AppLocalePreferenceProvider._();

final class AppLocalePreferenceProvider
    extends $NotifierProvider<AppLocalePreference, String> {
  AppLocalePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocalePreferenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocalePreferenceHash();

  @$internal
  @override
  AppLocalePreference create() => AppLocalePreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$appLocalePreferenceHash() =>
    r'0e83643c60157dc42dddc9e6f996454d77c46a10';

abstract class _$AppLocalePreference extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

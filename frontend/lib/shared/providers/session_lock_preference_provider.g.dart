// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_lock_preference_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SessionLockPreference)
final sessionLockPreferenceProvider = SessionLockPreferenceProvider._();

final class SessionLockPreferenceProvider
    extends $NotifierProvider<SessionLockPreference, int> {
  SessionLockPreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionLockPreferenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionLockPreferenceHash();

  @$internal
  @override
  SessionLockPreference create() => SessionLockPreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$sessionLockPreferenceHash() =>
    r'da3a1e2d2694d8110dd07547d44f2e03240c5b88';

abstract class _$SessionLockPreference extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

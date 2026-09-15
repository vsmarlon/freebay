// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saves_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Saves)
final savesProvider = SavesProvider._();

final class SavesProvider extends $NotifierProvider<Saves, SavesState> {
  SavesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savesHash();

  @$internal
  @override
  Saves create() => Saves();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavesState>(value),
    );
  }
}

String _$savesHash() => r'5ac59a56d24c4caf4a2772988507d16c00a9a48b';

abstract class _$Saves extends $Notifier<SavesState> {
  SavesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SavesState, SavesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SavesState, SavesState>,
              SavesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

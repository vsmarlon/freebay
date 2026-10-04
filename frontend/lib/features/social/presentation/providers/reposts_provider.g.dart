// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reposts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Reposts)
final repostsProvider = RepostsProvider._();

final class RepostsProvider extends $NotifierProvider<Reposts, RepostsState> {
  RepostsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'repostsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$repostsHash();

  @$internal
  @override
  Reposts create() => Reposts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RepostsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RepostsState>(value),
    );
  }
}

String _$repostsHash() => r'3f81c354dc1ec7e8db2d01f19b2a2fddd9d8489d';

abstract class _$Reposts extends $Notifier<RepostsState> {
  RepostsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RepostsState, RepostsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RepostsState, RepostsState>,
              RepostsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

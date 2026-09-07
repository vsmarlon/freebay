// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'likes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Likes)
final likesProvider = LikesProvider._();

final class LikesProvider extends $NotifierProvider<Likes, LikesState> {
  LikesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'likesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$likesHash();

  @$internal
  @override
  Likes create() => Likes();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LikesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LikesState>(value),
    );
  }
}

String _$likesHash() => r'18d51c6c0c6cd36ac08f5863846fceb3b2b4747c';

abstract class _$Likes extends $Notifier<LikesState> {
  LikesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LikesState, LikesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LikesState, LikesState>,
              LikesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_likes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommentLikes)
final commentLikesProvider = CommentLikesProvider._();

final class CommentLikesProvider
    extends $NotifierProvider<CommentLikes, CommentLikesState> {
  CommentLikesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commentLikesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commentLikesHash();

  @$internal
  @override
  CommentLikes create() => CommentLikes();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommentLikesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommentLikesState>(value),
    );
  }
}

String _$commentLikesHash() => r'af2f7e025a43f67ee75981128f0ce6d96f6936da';

abstract class _$CommentLikes extends $Notifier<CommentLikesState> {
  CommentLikesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CommentLikesState, CommentLikesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CommentLikesState, CommentLikesState>,
              CommentLikesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PostDetails)
final postDetailsProvider = PostDetailsFamily._();

final class PostDetailsProvider
    extends $NotifierProvider<PostDetails, PostDetailsState> {
  PostDetailsProvider._({
    required PostDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'postDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postDetailsHash();

  @override
  String toString() {
    return r'postDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PostDetails create() => PostDetails();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostDetailsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostDetailsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postDetailsHash() => r'db967966b71c6bcce1d93e626a0bd52a4e693ac4';

final class PostDetailsFamily extends $Family
    with
        $ClassFamilyOverride<
          PostDetails,
          PostDetailsState,
          PostDetailsState,
          PostDetailsState,
          String
        > {
  PostDetailsFamily._()
    : super(
        retry: null,
        name: r'postDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostDetailsProvider call(String postId) =>
      PostDetailsProvider._(argument: postId, from: this);

  @override
  String toString() => r'postDetailsProvider';
}

abstract class _$PostDetails extends $Notifier<PostDetailsState> {
  late final _$args = ref.$arg as String;
  String get postId => _$args;

  PostDetailsState build(String postId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PostDetailsState, PostDetailsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PostDetailsState, PostDetailsState>,
              PostDetailsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

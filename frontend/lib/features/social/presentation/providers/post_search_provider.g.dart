// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PostSearch)
final postSearchProvider = PostSearchProvider._();

final class PostSearchProvider
    extends $NotifierProvider<PostSearch, PostSearchState> {
  PostSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postSearchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postSearchHash();

  @$internal
  @override
  PostSearch create() => PostSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostSearchState>(value),
    );
  }
}

String _$postSearchHash() => r'9fe6e46ac163919f4e1bea7b9a497b14cadb5a7a';

abstract class _$PostSearch extends $Notifier<PostSearchState> {
  PostSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PostSearchState, PostSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PostSearchState, PostSearchState>,
              PostSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

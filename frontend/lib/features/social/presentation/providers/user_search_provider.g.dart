// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserSearch)
final userSearchProvider = UserSearchProvider._();

final class UserSearchProvider
    extends $NotifierProvider<UserSearch, UserSearchState> {
  UserSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userSearchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userSearchHash();

  @$internal
  @override
  UserSearch create() => UserSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserSearchState>(value),
    );
  }
}

String _$userSearchHash() => r'c078858af904123bb9f76648f38298e913973063';

abstract class _$UserSearch extends $Notifier<UserSearchState> {
  UserSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UserSearchState, UserSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserSearchState, UserSearchState>,
              UserSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Kept alive for the entire app session — never disposed between tab switches.
/// Only invalidated explicitly after a follow/unfollow action via [ref.invalidate].

@ProviderFor(Suggestions)
final suggestionsProvider = SuggestionsProvider._();

/// Kept alive for the entire app session — never disposed between tab switches.
/// Only invalidated explicitly after a follow/unfollow action via [ref.invalidate].
final class SuggestionsProvider
    extends $NotifierProvider<Suggestions, SuggestionsState> {
  /// Kept alive for the entire app session — never disposed between tab switches.
  /// Only invalidated explicitly after a follow/unfollow action via [ref.invalidate].
  SuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'suggestionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$suggestionsHash();

  @$internal
  @override
  Suggestions create() => Suggestions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SuggestionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SuggestionsState>(value),
    );
  }
}

String _$suggestionsHash() => r'6e21c93d5be26a902a75c4d2ab17c5d963244e91';

/// Kept alive for the entire app session — never disposed between tab switches.
/// Only invalidated explicitly after a follow/unfollow action via [ref.invalidate].

abstract class _$Suggestions extends $Notifier<SuggestionsState> {
  SuggestionsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SuggestionsState, SuggestionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SuggestionsState, SuggestionsState>,
              SuggestionsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

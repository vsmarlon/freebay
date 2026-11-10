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

String _$userSearchHash() => r'ab77517978655329294d679e1944ccfff9ff85ad';

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

String _$suggestionsHash() => r'485670282e596cc54e458eb894707300cdc97cdf';

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

@ProviderFor(quoteMentionCandidates)
final quoteMentionCandidatesProvider = QuoteMentionCandidatesFamily._();

final class QuoteMentionCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserSearchEntity>>,
          List<UserSearchEntity>,
          FutureOr<List<UserSearchEntity>>
        >
    with
        $FutureModifier<List<UserSearchEntity>>,
        $FutureProvider<List<UserSearchEntity>> {
  QuoteMentionCandidatesProvider._({
    required QuoteMentionCandidatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'quoteMentionCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quoteMentionCandidatesHash();

  @override
  String toString() {
    return r'quoteMentionCandidatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<UserSearchEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserSearchEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return quoteMentionCandidates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is QuoteMentionCandidatesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quoteMentionCandidatesHash() =>
    r'05f40b9dafa2b0c45ac9c5fe995c95d35135b639';

final class QuoteMentionCandidatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<UserSearchEntity>>, String> {
  QuoteMentionCandidatesFamily._()
    : super(
        retry: null,
        name: r'quoteMentionCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  QuoteMentionCandidatesProvider call(String query) =>
      QuoteMentionCandidatesProvider._(argument: query, from: this);

  @override
  String toString() => r'quoteMentionCandidatesProvider';
}

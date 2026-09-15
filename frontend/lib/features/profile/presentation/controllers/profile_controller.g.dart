// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserPosts)
final userPostsProvider = UserPostsFamily._();

final class UserPostsProvider
    extends $NotifierProvider<UserPosts, UserPostsState> {
  UserPostsProvider._({
    required UserPostsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userPostsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userPostsHash();

  @override
  String toString() {
    return r'userPostsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserPosts create() => UserPosts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserPostsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserPostsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserPostsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userPostsHash() => r'64b1e8bc41445491d8d191c553aadaf971d3ec60';

final class UserPostsFamily extends $Family
    with
        $ClassFamilyOverride<
          UserPosts,
          UserPostsState,
          UserPostsState,
          UserPostsState,
          String
        > {
  UserPostsFamily._()
    : super(
        retry: null,
        name: r'userPostsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserPostsProvider call(String userId) =>
      UserPostsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userPostsProvider';
}

abstract class _$UserPosts extends $Notifier<UserPostsState> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  UserPostsState build(String userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UserPostsState, UserPostsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserPostsState, UserPostsState>,
              UserPostsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

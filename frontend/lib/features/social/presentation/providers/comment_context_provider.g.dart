// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_context_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommentContextController)
final commentContextControllerProvider = CommentContextControllerFamily._();

final class CommentContextControllerProvider
    extends
        $AsyncNotifierProvider<CommentContextController, CommentContextPages> {
  CommentContextControllerProvider._({
    required CommentContextControllerFamily super.from,
    required (String, {String replySort}) super.argument,
  }) : super(
         retry: null,
         name: r'commentContextControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentContextControllerHash();

  @override
  String toString() {
    return r'commentContextControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CommentContextController create() => CommentContextController();

  @override
  bool operator ==(Object other) {
    return other is CommentContextControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentContextControllerHash() =>
    r'2e87c383c55075a16087fc90a38fb88e1a417eb6';

final class CommentContextControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CommentContextController,
          AsyncValue<CommentContextPages>,
          CommentContextPages,
          FutureOr<CommentContextPages>,
          (String, {String replySort})
        > {
  CommentContextControllerFamily._()
    : super(
        retry: null,
        name: r'commentContextControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CommentContextControllerProvider call(
    String commentId, {
    String replySort = 'recent',
  }) => CommentContextControllerProvider._(
    argument: (commentId, replySort: replySort),
    from: this,
  );

  @override
  String toString() => r'commentContextControllerProvider';
}

abstract class _$CommentContextController
    extends $AsyncNotifier<CommentContextPages> {
  late final _$args = ref.$arg as (String, {String replySort});
  String get commentId => _$args.$1;
  String get replySort => _$args.replySort;

  FutureOr<CommentContextPages> build(
    String commentId, {
    String replySort = 'recent',
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CommentContextPages>, CommentContextPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CommentContextPages>, CommentContextPages>,
              AsyncValue<CommentContextPages>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, replySort: _$args.replySort),
    );
  }
}

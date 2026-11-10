import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/social/data/entities/comment_context.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';
import 'package:freebay/shared/services/notification_socket_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comment_context_provider.g.dart';

class CommentContextPages {
  const CommentContextPages({
    required this.value,
    this.loadingAncestors = false,
    this.loadingReplies = false,
    this.ancestorError,
    this.replyError,
  });

  final CommentContext value;
  final bool loadingAncestors;
  final bool loadingReplies;
  final String? ancestorError;
  final String? replyError;

  CommentContextPages copyWith({
    CommentContext? value,
    bool? loadingAncestors,
    bool? loadingReplies,
    String? ancestorError,
    String? replyError,
    bool clearAncestorError = false,
    bool clearReplyError = false,
  }) => CommentContextPages(
    value: value ?? this.value,
    loadingAncestors: loadingAncestors ?? this.loadingAncestors,
    loadingReplies: loadingReplies ?? this.loadingReplies,
    ancestorError: clearAncestorError
        ? null
        : ancestorError ?? this.ancestorError,
    replyError: clearReplyError ? null : replyError ?? this.replyError,
  );
}

@riverpod
class CommentContextController extends _$CommentContextController {
  int _generation = 0;
  bool _ancestorRequestActive = false;
  bool _replyRequestActive = false;

  @override
  Future<CommentContextPages> build(
    String commentId, {
    String replySort = 'recent',
  }) async {
    final viewerId = ref.watch(
      authControllerProvider.select((session) => session.value?.id),
    );
    ++_generation;
    _ancestorRequestActive = false;
    _replyRequestActive = false;
    final events = ref.read(notificationSocketServiceProvider).events.listen((
      event,
    ) {
      if (event is NotificationSocketSuspended ||
          event is PrivateContentInvalidated ||
          event is NotificationSocketReconnected) {
        ++_generation;
        state = const AsyncLoading();
        ref.invalidateSelf();
      }
    });
    ref.onDispose(() {
      ++_generation;
      events.cancel();
    });

    final attempt = AuthSessionCoordinator.currentAuthenticationAttempt;
    final result = await ref
        .read(socialRepositoryProvider)
        .getCommentContext(commentId, replySort: replySort);
    return result.fold((failure) => throw Exception(failure.message), (
      context,
    ) {
      if (context.focus.id != commentId) {
        throw const FormatException('Context response focus mismatch');
      }
      if (!AuthSessionCoordinator.isCurrentAttempt(attempt) ||
          ref.read(authControllerProvider).value?.id != viewerId) {
        ref.invalidateSelf();
      }
      return CommentContextPages(value: context);
    });
  }

  Future<void> loadAncestors() async {
    final current = state.asData?.value;
    final cursor = current?.value.nextAncestorCursor;
    if (current == null || cursor == null || _ancestorRequestActive) return;
    _ancestorRequestActive = true;
    final generation = _generation;
    final attempt = AuthSessionCoordinator.currentAuthenticationAttempt;
    final viewerId = ref.read(authControllerProvider).value?.id;
    state = AsyncData(
      current.copyWith(loadingAncestors: true, clearAncestorError: true),
    );
    final result = await ref
        .read(socialRepositoryProvider)
        .getCommentContext(
          commentId,
          ancestorCursor: cursor,
          replySort: replySort,
        );
    if (!_isCurrent(generation, attempt, viewerId)) return;
    _ancestorRequestActive = false;
    result.fold(
      (failure) {
        final latest = state.asData?.value;
        if (latest != null) {
          state = AsyncData(
            latest.copyWith(
              loadingAncestors: false,
              ancestorError: failure.message,
            ),
          );
        }
      },
      (older) {
        final latest = state.asData?.value;
        if (latest == null) return;
        if (older.focus.id != commentId) {
          state = AsyncData(
            latest.copyWith(
              loadingAncestors: false,
              ancestorError: 'Context response focus mismatch',
            ),
          );
          return;
        }
        final known = latest.value.ancestors.map((item) => item.id).toSet();
        final prepend = <CommentEntity>[];
        for (final item in older.ancestors) {
          if (known.add(item.id)) prepend.add(item);
        }
        final merged = CommentContext(
          ancestors: [...prepend, ...latest.value.ancestors],
          focus: latest.value.focus,
          replies: latest.value.replies,
          nextReplyCursor: latest.value.nextReplyCursor,
          nextAncestorCursor: older.nextAncestorCursor,
        );
        state = AsyncData(
          latest.copyWith(value: merged, loadingAncestors: false),
        );
      },
    );
  }

  Future<void> loadReplies() async {
    final current = state.asData?.value;
    final cursor = current?.value.nextReplyCursor;
    if (current == null || cursor == null || _replyRequestActive) return;
    _replyRequestActive = true;
    final generation = _generation;
    final attempt = AuthSessionCoordinator.currentAuthenticationAttempt;
    final viewerId = ref.read(authControllerProvider).value?.id;
    state = AsyncData(
      current.copyWith(loadingReplies: true, clearReplyError: true),
    );
    final result = await ref
        .read(socialRepositoryProvider)
        .getCommentContext(
          commentId,
          replyCursor: cursor,
          replySort: replySort,
        );
    if (!_isCurrent(generation, attempt, viewerId)) return;
    _replyRequestActive = false;
    result.fold(
      (failure) {
        final latest = state.asData?.value;
        if (latest != null) {
          state = AsyncData(
            latest.copyWith(loadingReplies: false, replyError: failure.message),
          );
        }
      },
      (next) {
        final latest = state.asData?.value;
        if (latest == null) return;
        if (next.focus.id != commentId) {
          state = AsyncData(
            latest.copyWith(
              loadingReplies: false,
              replyError: 'Context response focus mismatch',
            ),
          );
          return;
        }
        final known = latest.value.replies.map((item) => item.id).toSet();
        final append = <CommentEntity>[];
        for (final item in next.replies) {
          if (known.add(item.id)) append.add(item);
        }
        final merged = CommentContext(
          ancestors: latest.value.ancestors,
          focus: latest.value.focus,
          replies: [...latest.value.replies, ...append],
          nextReplyCursor: next.nextReplyCursor,
          nextAncestorCursor: latest.value.nextAncestorCursor,
        );
        state = AsyncData(
          latest.copyWith(value: merged, loadingReplies: false),
        );
      },
    );
  }

  void refresh() {
    ++_generation;
    _ancestorRequestActive = false;
    _replyRequestActive = false;
    ref.invalidateSelf();
  }

  bool _isCurrent(int generation, int attempt, String? viewerId) =>
      ref.mounted &&
      generation == _generation &&
      AuthSessionCoordinator.isCurrentAttempt(attempt) &&
      ref.read(authControllerProvider).value?.id == viewerId;
}

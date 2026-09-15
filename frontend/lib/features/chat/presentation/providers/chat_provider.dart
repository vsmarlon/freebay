import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/last_message_info.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/domain/usecases/report_chat_usecase.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/utils/date_utils.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final reportChatUsecaseProvider = Provider<ReportChatUsecase>((ref) {
  return ReportChatUsecase();
});

final chatsProvider = FutureProvider<CursorPage<ChatEntity>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getChats();

  return result.fold((failure) => throw failure, (page) => page);
});

class ArchivedChatListController
    extends Notifier<AsyncValue<List<ChatEntity>>> {
  String? _cursor;

  @override
  AsyncValue<List<ChatEntity>> build() {
    _loadFirstPage();
    return const AsyncValue.loading();
  }

  Future<void> _loadFirstPage() async {
    final repository = ref.read(chatRepositoryProvider);
    final result = await repository.getArchivedChats();
    if (!ref.mounted) return;
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (page) {
        _cursor = page.nextCursor;
        ref.read(archivedChatListHasMoreProvider.notifier).state = page.hasMore;
        state = AsyncValue.data(page.items);
      },
    );
  }

  Future<void> fetchMore() async {
    if (ref.read(archivedChatListLoadingMoreProvider)) return;
    if (!ref.read(archivedChatListHasMoreProvider)) return;
    final cursor = _cursor;
    final items = state.value;
    if (cursor == null || items == null) return;

    ref.read(archivedChatListLoadingMoreProvider.notifier).state = true;
    try {
      final repository = ref.read(chatRepositoryProvider);
      final result = await repository.getArchivedChats(cursor: cursor);
      if (!ref.mounted) return;
      result.fold((_) {}, (page) {
        _cursor = page.nextCursor;
        ref.read(archivedChatListHasMoreProvider.notifier).state = page.hasMore;
        final known = {for (final c in items) c.id: true};
        state = AsyncValue.data([
          ...items,
          ...page.items.where((c) => !known.containsKey(c.id)),
        ]);
      });
    } finally {
      if (ref.mounted) {
        ref.read(archivedChatListLoadingMoreProvider.notifier).state = false;
      }
    }
  }
}

final archivedChatListProvider =
    NotifierProvider<ArchivedChatListController, AsyncValue<List<ChatEntity>>>(
      ArchivedChatListController.new,
    );

class ArchivedChatListHasMoreNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
  void set(bool value) => state = value;
}

final archivedChatListHasMoreProvider =
    NotifierProvider<ArchivedChatListHasMoreNotifier, bool>(
      ArchivedChatListHasMoreNotifier.new,
    );

class ArchivedChatListLoadingMoreNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
  void set(bool value) => state = value;
}

final archivedChatListLoadingMoreProvider =
    NotifierProvider<ArchivedChatListLoadingMoreNotifier, bool>(
      ArchivedChatListLoadingMoreNotifier.new,
    );

class ChatListQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
  void set(String value) => state = value;
}

final chatListQueryProvider = NotifierProvider<ChatListQueryNotifier, String>(
  ChatListQueryNotifier.new,
);

class ChatListHasMoreNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
  void set(bool value) => state = value;
}

final chatListHasMoreProvider = NotifierProvider<ChatListHasMoreNotifier, bool>(
  ChatListHasMoreNotifier.new,
);

class ChatListLoadingMoreNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
  void set(bool value) => state = value;
}

final chatListLoadingMoreProvider =
    NotifierProvider<ChatListLoadingMoreNotifier, bool>(
      ChatListLoadingMoreNotifier.new,
    );

class ChatListController extends Notifier<AsyncValue<List<ChatEntity>>> {
  StreamSubscription<Map<String, dynamic>>? _subscription;
  String? _cursor;

  @override
  AsyncValue<List<ChatEntity>> build() {
    final query = ref.watch(chatListQueryProvider);

    _subscription?.cancel();
    final socketService = ref.read(chatSocketServiceProvider);
    _subscription = socketService.messageStream.listen(_onSocketMessage);
    ref.onDispose(() {
      _subscription?.cancel();
    });

    _loadFirstPage(query);
    return const AsyncValue.loading();
  }

  String? _queryOrNull(String query) => query.isEmpty ? null : query;

  Future<void> _loadFirstPage(String query) async {
    final repository = ref.read(chatRepositoryProvider);
    final result = await repository.getChats(query: _queryOrNull(query));
    if (!ref.mounted) return;
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (page) {
        _cursor = page.nextCursor;
        ref.read(chatListHasMoreProvider.notifier).state = page.hasMore;
        state = AsyncValue.data(page.items);
      },
    );
  }

  Future<void> fetchMore() async {
    if (ref.read(chatListLoadingMoreProvider)) return;
    if (!ref.read(chatListHasMoreProvider)) return;
    final cursor = _cursor;
    final items = state.value;
    if (cursor == null || items == null) return;

    ref.read(chatListLoadingMoreProvider.notifier).state = true;
    try {
      final repository = ref.read(chatRepositoryProvider);
      final result = await repository.getChats(
        query: _queryOrNull(ref.read(chatListQueryProvider)),
        cursor: cursor,
      );
      if (!ref.mounted) return;
      result.fold((_) {}, (page) {
        _cursor = page.nextCursor;
        ref.read(chatListHasMoreProvider.notifier).state = page.hasMore;
        final known = {for (final c in items) c.id: true};
        state = AsyncValue.data([
          ...items,
          ...page.items.where((c) => !known.containsKey(c.id)),
        ]);
      });
    } finally {
      if (ref.mounted) {
        ref.read(chatListLoadingMoreProvider.notifier).state = false;
      }
    }
  }

  Future<void> refreshRecent() => _mergeFirstPage();

  Future<void> _mergeFirstPage() async {
    final repository = ref.read(chatRepositoryProvider);
    final result = await repository.getChats(
      query: _queryOrNull(ref.read(chatListQueryProvider)),
    );
    if (!ref.mounted) return;
    result.fold((_) {}, (page) {
      final current = state.value ?? [];
      final freshIds = {for (final c in page.items) c.id: true};
      final merged = [
        ...page.items,
        ...current.where((c) => !freshIds.containsKey(c.id)),
      ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _cursor = page.nextCursor;
      ref.read(chatListHasMoreProvider.notifier).state = page.hasMore;
      state = AsyncValue.data(merged);
    });
  }

  void _onSocketMessage(Map<String, dynamic> msg) {
    final currentList = state.value;
    if (currentList == null) return;

    final conversationId = msg['conversationId'] as String?;
    if (conversationId == null) return;

    if (!currentList.any((chat) => chat.id == conversationId)) {
      _mergeFirstPage();
      return;
    }

    final content = msg['content'] as String? ?? '';
    final createdAtStr = msg['createdAt'] as String?;
    final createdAt = createdAtStr != null
        ? parseServerDateTime(createdAtStr)
        : DateTime.now();
    final senderId = msg['senderId'] as String? ?? '';

    final authState = ref.read(authControllerProvider);
    final currentUserId = authState.value?.id;
    final isFromMe = senderId == currentUserId;

    final updatedList = currentList.map((chat) {
      if (chat.id != conversationId) return chat;
      return chat.copyWith(
        lastMessageInfo: LastMessageInfo(
          content: content,
          createdAt: createdAt,
        ),
        unreadCount: isFromMe ? 0 : chat.unreadCount + 1,
      );
    }).toList();

    updatedList.sort((a, b) {
      final aTime = a.lastMessageInfo?.createdAt ?? a.createdAt;
      final bTime = b.lastMessageInfo?.createdAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    state = AsyncValue.data(updatedList);
  }
}

final liveChatListProvider =
    NotifierProvider<ChatListController, AsyncValue<List<ChatEntity>>>(
      ChatListController.new,
    );

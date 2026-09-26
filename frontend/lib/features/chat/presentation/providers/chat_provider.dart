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

List<ChatEntity> _sortedChats(Iterable<ChatEntity> chats) {
  final byId = <String, ChatEntity>{};
  for (final chat in chats) {
    final existing = byId[chat.id];
    if (existing == null || chat.timestamp.isAfter(existing.timestamp)) {
      byId[chat.id] = chat;
    }
  }
  final result = byId.values.toList()
    ..sort((a, b) {
      final timestamp = b.timestamp.compareTo(a.timestamp);
      return timestamp == 0 ? a.id.compareTo(b.id) : timestamp;
    });
  return result;
}

class ChatListState {
  final List<ChatEntity> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;
  final Object? error;

  const ChatListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextCursor,
    this.error,
  });
}

typedef ArchivedChatListState = ChatListState;

final reportChatUsecaseProvider = Provider<ReportChatUsecase>((ref) {
  return ReportChatUsecase();
});

final chatsProvider = FutureProvider<CursorPage<ChatEntity>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getChats();

  return result.fold((failure) => throw failure, (page) => page);
});

class ArchivedChatListController extends Notifier<ArchivedChatListState> {
  int _generation = 0;
  String? _userId;

  @override
  ArchivedChatListState build() {
    final userId = ref.watch(authControllerProvider.select((s) => s.value?.id));
    final generation = ++_generation;
    _userId = userId;
    _loadFirstPage(generation, userId);
    return const ArchivedChatListState(isLoading: true);
  }

  bool _isCurrent(int generation, String? userId) =>
      ref.mounted && generation == _generation && userId == _userId;

  Future<void> _loadFirstPage(int generation, String? userId) async {
    final repository = ref.read(chatRepositoryProvider);
    final result = await repository.getArchivedChats();
    if (!_isCurrent(generation, userId)) return;
    result.fold((failure) => state = ArchivedChatListState(error: failure), (
      page,
    ) {
      state = ArchivedChatListState(
        items: _sortedChats(page.items),
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      );
    });
  }

  Future<void> fetchMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final cursor = state.nextCursor;
    if (cursor == null) return;
    final generation = _generation;
    final userId = _userId;
    state = ArchivedChatListState(
      items: state.items,
      isLoadingMore: true,
      hasMore: state.hasMore,
      nextCursor: cursor,
    );
    final result = await ref
        .read(chatRepositoryProvider)
        .getArchivedChats(cursor: cursor);
    if (!_isCurrent(generation, userId)) return;
    result.fold(
      (failure) => state = ArchivedChatListState(
        items: state.items,
        hasMore: state.hasMore,
        nextCursor: state.nextCursor,
        error: failure,
      ),
      (page) => state = ArchivedChatListState(
        items: _sortedChats([...state.items, ...page.items]),
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }
}

final archivedChatListProvider =
    NotifierProvider<ArchivedChatListController, ArchivedChatListState>(
      ArchivedChatListController.new,
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

class ChatListController extends Notifier<ChatListState> {
  StreamSubscription<Map<String, dynamic>>? _subscription;
  int _generation = 0;
  String? _userId;
  String _query = '';
  bool _hasRetainedTail = false;
  Future<void>? _refreshFuture;
  int? _refreshGeneration;

  @override
  ChatListState build() {
    final userId = ref.watch(authControllerProvider.select((s) => s.value?.id));
    final query = ref.watch(chatListQueryProvider);
    final generation = ++_generation;
    _userId = userId;
    _query = query;
    _hasRetainedTail = false;

    _subscription?.cancel();
    final socketService = ref.read(chatSocketServiceProvider);
    _subscription = socketService.messageStream.listen(_onSocketMessage);
    ref.onDispose(() {
      _subscription?.cancel();
    });

    _loadFirstPage(generation, userId, query);
    return const ChatListState(isLoading: true);
  }

  String? _queryOrNull(String query) => query.isEmpty ? null : query;

  bool _isCurrent(int generation, String? userId, String query) =>
      ref.mounted &&
      generation == _generation &&
      userId == _userId &&
      query == _query;

  Future<void> _loadFirstPage(
    int generation,
    String? userId,
    String query,
  ) async {
    final repository = ref.read(chatRepositoryProvider);
    final result = await repository.getChats(query: _queryOrNull(query));
    if (!_isCurrent(generation, userId, query)) return;
    result.fold((failure) => state = ChatListState(error: failure), (page) {
      state = ChatListState(
        items: _sortedChats(page.items),
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      );
    });
  }

  Future<void> fetchMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final cursor = state.nextCursor;
    if (cursor == null) return;
    final generation = _generation;
    final userId = _userId;
    final query = _query;
    state = ChatListState(
      items: state.items,
      isLoadingMore: true,
      hasMore: state.hasMore,
      nextCursor: cursor,
    );
    final result = await ref
        .read(chatRepositoryProvider)
        .getChats(query: _queryOrNull(query), cursor: cursor);
    if (!_isCurrent(generation, userId, query)) return;
    result.fold(
      (failure) => state = ChatListState(
        items: state.items,
        hasMore: state.hasMore,
        nextCursor: state.nextCursor,
        error: failure,
      ),
      (page) {
        _hasRetainedTail = true;
        state = ChatListState(
          items: _sortedChats([...state.items, ...page.items]),
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        );
      },
    );
  }

  Future<void> refreshRecent() {
    final existing = _refreshFuture;
    if (existing != null && _refreshGeneration == _generation) {
      return existing;
    }
    late Future<void> future;
    final generation = _generation;
    _refreshGeneration = generation;
    future = _mergeFirstPage().whenComplete(() {
      if (identical(_refreshFuture, future)) _refreshFuture = null;
    });
    _refreshFuture = future;
    return future;
  }

  Future<void> _mergeFirstPage() async {
    final generation = _generation;
    final userId = _userId;
    final query = _query;
    final repository = ref.read(chatRepositoryProvider);
    final result = await repository.getChats(query: _queryOrNull(query));
    if (!_isCurrent(generation, userId, query)) return;
    result.fold(
      (failure) => state = ChatListState(
        items: state.items,
        hasMore: state.hasMore,
        nextCursor: state.nextCursor,
        error: failure,
      ),
      (page) {
        final current = state.items;
        state = ChatListState(
          items: _sortedChats([...page.items, ...current]),
          hasMore: _hasRetainedTail ? state.hasMore : page.hasMore,
          nextCursor: _hasRetainedTail ? state.nextCursor : page.nextCursor,
        );
      },
    );
  }

  void _onSocketMessage(Map<String, dynamic> msg) {
    final currentList = state.items;

    final conversationId = msg['conversationId'] as String?;
    if (conversationId == null) return;

    if (!currentList.any((chat) => chat.id == conversationId)) {
      unawaited(refreshRecent());
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

    state = ChatListState(
      items: _sortedChats(updatedList),
      hasMore: state.hasMore,
      nextCursor: state.nextCursor,
    );
  }
}

final liveChatListProvider =
    NotifierProvider<ChatListController, ChatListState>(ChatListController.new);

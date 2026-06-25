import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:freebay/features/chat/domain/usecases/archive_chat_usecase.dart';
import 'package:freebay/features/chat/domain/usecases/delete_chat_usecase.dart';
import 'package:freebay/features/chat/domain/usecases/block_user_usecase.dart';
import 'package:freebay/features/chat/domain/usecases/report_chat_usecase.dart';
import 'package:freebay/features/chat/domain/usecases/set_chat_theme_usecase.dart';
import 'package:freebay/features/chat/domain/usecases/set_chat_background_usecase.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/features/profile/data/services/block_service.dart';

final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  return ChatRepository();
});

final blockServiceProvider = Provider<BlockService>((ref) {
  return BlockService();
});

final archiveChatUsecaseProvider = Provider<ArchiveChatUsecase>((ref) {
  return ArchiveChatUsecase(ref.watch(chatRepositoryProvider));
});

final deleteChatUsecaseProvider = Provider<DeleteChatUsecase>((ref) {
  return DeleteChatUsecase(ref.watch(chatRepositoryProvider));
});

final blockUserUsecaseProvider = Provider<BlockUserUsecase>((ref) {
  return BlockUserUsecase(ref.watch(blockServiceProvider));
});

final reportChatUsecaseProvider = Provider<ReportChatUsecase>((ref) {
  return ReportChatUsecase();
});

final setChatThemeUsecaseProvider = Provider<SetChatThemeUsecase>((ref) {
  return SetChatThemeUsecase(ref.watch(chatRepositoryProvider));
});

final setChatBackgroundUsecaseProvider =
    Provider<SetChatBackgroundUsecase>((ref) {
  return SetChatBackgroundUsecase(ref.watch(chatRepositoryProvider));
});

final chatsProvider = FutureProvider.autoDispose<List<ChatEntity>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getChats();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (chats) => chats,
  );
});

final archivedChatsProvider =
    FutureProvider.autoDispose<List<ChatEntity>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getArchivedChats();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (chats) => chats,
  );
});

final searchedChatsProvider = FutureProvider.autoDispose
    .family<List<ChatEntity>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getChats(query: query);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (chats) => chats,
  );
});

class ChatListController extends StateNotifier<AsyncValue<List<ChatEntity>>> {
  ChatListController(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  void _init() {
    _ref.listen(chatsProvider, (_, next) {
      state = next;
    });

    final socketService = _ref.read(chatSocketServiceProvider);
    _subscription = socketService.messageStream.listen(_onSocketMessage);
  }

  void _onSocketMessage(Map<String, dynamic> msg) {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    final conversationId = msg['conversationId'] as String?;
    if (conversationId == null) return;

    final content = msg['content'] as String? ?? '';
    final createdAtStr = msg['createdAt'] as String?;
    final createdAt =
        createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
    final senderId = msg['senderId'] as String? ?? '';

    final authState = _ref.read(authControllerProvider);
    final currentUserId = authState.valueOrNull?.id;
    final isFromMe = senderId == currentUserId;

    final updatedList = currentList.map((chat) {
      if (chat.id != conversationId) return chat;
      return chat.copyWith(
        lastMessage: content,
        timestamp: createdAt,
        unread: !isFromMe,
      );
    }).toList();

    updatedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = AsyncValue.data(updatedList);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final liveChatListProvider =
    StateNotifierProvider<ChatListController, AsyncValue<List<ChatEntity>>>(
        (ref) {
  return ChatListController(ref);
});

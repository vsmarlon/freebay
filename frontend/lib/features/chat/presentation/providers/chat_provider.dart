import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/domain/repositories/i_chat_repository.dart';

final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  return ChatRepository();
});

final chatsProvider = FutureProvider.autoDispose<List<ChatEntity>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getChats();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (chats) => chats,
  );
});

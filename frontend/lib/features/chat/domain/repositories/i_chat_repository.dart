import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract class IChatRepository {
  Future<Either<Failure, List<ChatEntity>>> getChats({String? query});
  Future<Either<Failure, List<ChatEntity>>> getArchivedChats();
  Future<
    Either<
      Failure,
      ({
        List<MessageEntity> messages,
        bool hasMore,
        String? nextCursor,
        String threadType,
        String? otherUserId,
        ConversationPreference? preference,
      })
    >
  >
  getConversation(String conversationId, {String? cursor, int? limit});

  Future<Either<Failure, MessageEntity>> sendMessage(
    String chatId,
    String message, {
    String? replyToId,
    bool viewOnce = false,
    String? clientMessageId,
  });
  Future<Either<Failure, MessageEntity>> sendRichMessage({
    required String conversationId,
    String? content,
    String type,
    String? attachmentUrl,
    String? replyToId,
    Map<String, dynamic>? metadata,
    bool viewOnce = false,
  });
  Future<Either<Failure, void>> deleteMessage(
    String conversationId,
    String messageId,
  );
  Future<Either<Failure, List<MessageReactionEntity>>> reactToMessage(
    String conversationId,
    String messageId,
    String emoji,
  );
  Future<Either<Failure, void>> markAsRead(String chatId);
  Future<Either<Failure, void>> archiveChat(
    String id,
    ChatThreadType type,
    bool archived,
  );
  Future<Either<Failure, void>> deleteChat(String id, ChatThreadType type);
  Future<Either<Failure, ConversationPreference>> setTheme(
    String id,
    ChatThreadType type,
    String theme,
  );
  Future<Either<Failure, ConversationPreference>> setBackground(
    String id,
    ChatThreadType type,
    String base64DataUri,
  );

  /// Fetch paginated media messages of [type] from a conversation.
  Future<Either<Failure, ({List<MessageEntity> messages, String? nextCursor})>>
  getConversationMedia(
    String conversationId, {
    String type = 'IMAGE',
    int limit = 50,
    String? cursor,
  });

  /// Forward one or more messages to target conversations.
  Future<Either<Failure, List<MessageEntity>>> forwardMessages({
    required List<String> messageIds,
    required List<String> targetConversationIds,
    String? sourceConversationId,
  });
}

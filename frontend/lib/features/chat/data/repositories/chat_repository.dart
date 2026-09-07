import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';
import 'package:freebay/features/chat/domain/repositories/i_chat_repository.dart';

class ChatRepository extends BaseHttpRepository implements IChatRepository {
  ChatRepository({super.client});

  @override
  Future<Either<Failure, List<ChatEntity>>> getChats({String? query}) =>
      safeGetList<ChatEntity>(
        query != null && query.isNotEmpty
            ? '/chat/conversations?q=${Uri.encodeQueryComponent(query)}'
            : '/chat/conversations',
        listKey: 'data.conversations',
        fromJson: ChatEntity.fromJson,
      );

  @override
  Future<Either<Failure, List<ChatEntity>>> getArchivedChats() =>
      safeGetList<ChatEntity>(
        '/chat/archived',
        listKey: 'data.conversations',
        fromJson: ChatEntity.fromJson,
      );

  @override
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
  getConversation(String conversationId, {String? cursor, int? limit}) =>
      safeCall(
        () => client.get(
          '/chat/conversations/$conversationId',
          queryParameters: {'cursor': ?cursor, 'limit': ?limit},
        ),
        onSuccess: (response) {
          final data = response.data['data'] as Map<String, dynamic>? ?? {};
          final rawMessages = (data['messages'] as List<dynamic>?) ?? [];
          final messages = rawMessages
              .map((m) => MessageEntity.fromJson(m as Map<String, dynamic>))
              .toList();
          final threadType = (data['threadType'] as String?) ?? 'DIRECT';
          final otherUserId = data['otherUserId'] as String?;
          final rawPref = data['preference'] as Map<String, dynamic>?;
          final preference = rawPref != null
              ? ConversationPreference.fromJson(rawPref)
              : null;

          return Right((
            messages: messages,
            hasMore: data['hasMore'] == true,
            nextCursor: data['nextCursor'] as String?,
            threadType: threadType,
            otherUserId: otherUserId,
            preference: preference,
          ));
        },
      );

  @override
  Future<Either<Failure, MessageEntity>> sendMessage(
    String chatId,
    String message, {
    String? replyToId,
    bool viewOnce = false,
    String? clientMessageId,
  }) => safePost<MessageEntity>(
    '/chat/conversations/$chatId/messages',
    data: {
      'content': message,
      'replyToId': ?replyToId,
      'clientMessageId': ?clientMessageId,
      if (viewOnce) 'viewOnce': true,
    },
    extractKey: 'data',
    fromJson: MessageEntity.fromJson,
  );

  @override
  Future<Either<Failure, void>> markAsRead(String chatId) =>
      safeVoid(() => client.patch('/chat/conversations/$chatId/read'));

  @override
  Future<Either<Failure, void>> archiveChat(
    String id,
    ChatThreadType type,
    bool archived,
  ) => safeVoid(
    () => client.patch(
      '/chat/conversations/$id/archive',
      data: {'archived': archived},
    ),
  );

  @override
  Future<Either<Failure, void>> deleteChat(String id, ChatThreadType type) =>
      safeVoid(() => client.patch('/chat/conversations/$id/delete'));

  @override
  Future<Either<Failure, ConversationPreference>> setTheme(
    String id,
    ChatThreadType type,
    String theme,
  ) => safePatch<ConversationPreference>(
    '/chat/conversations/$id/theme',
    data: {'theme': theme},
    extractKey: 'data.preference',
    fromJson: ConversationPreference.fromJson,
  );

  @override
  Future<Either<Failure, ConversationPreference>> setBackground(
    String id,
    ChatThreadType type,
    String base64DataUri,
  ) => safePatch<ConversationPreference>(
    '/chat/conversations/$id/background',
    data: {'backgroundUrl': base64DataUri},
    extractKey: 'data.preference',
    fromJson: ConversationPreference.fromJson,
  );

  @override
  Future<Either<Failure, MessageEntity>> sendRichMessage({
    required String conversationId,
    String? content,
    String type = 'TEXT',
    String? attachmentUrl,
    String? replyToId,
    Map<String, dynamic>? metadata,
    bool viewOnce = false,
  }) => safePost<MessageEntity>(
    '/chat/conversations/$conversationId/messages',
    data: {
      'type': type,
      'content': ?content,
      'attachmentUrl': ?attachmentUrl,
      'replyToId': ?replyToId,
      'metadata': ?metadata,
      if (viewOnce) 'viewOnce': true,
    },
    extractKey: 'data',
    fromJson: MessageEntity.fromJson,
  );

  @override
  Future<Either<Failure, void>> deleteMessage(
    String conversationId,
    String messageId,
  ) => safeVoid(
    () => client.patch(
      '/chat/conversations/$conversationId/messages/$messageId/delete',
    ),
  );

  @override
  Future<Either<Failure, List<MessageReactionEntity>>> reactToMessage(
    String conversationId,
    String messageId,
    String emoji,
  ) => safePost<List<MessageReactionEntity>>(
    '/chat/conversations/$conversationId/messages/$messageId/react',
    data: {'emoji': emoji},
    extractKey: 'data.reactions',
    customMapper: (list) =>
        (list as List?)
            ?.whereType<Map>()
            .map(
              (e) =>
                  MessageReactionEntity.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList() ??
        [],
  );

  @override
  Future<Either<Failure, ({List<MessageEntity> messages, String? nextCursor})>>
  getConversationMedia(
    String conversationId, {
    String type = 'IMAGE',
    int limit = 50,
    String? cursor,
  }) => safeGet<({List<MessageEntity> messages, String? nextCursor})>(
    '/chat/conversations/$conversationId/messages',
    queryParameters: {'type': type, 'limit': limit, 'cursor': ?cursor},
    extractKey: 'data',
    customMapper: (raw) {
      final data = raw as Map<String, dynamic>? ?? {};
      final rawMessages = (data['messages'] as List?) ?? [];
      final messages = rawMessages
          .whereType<Map>()
          .map((m) => MessageEntity.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      return (messages: messages, nextCursor: data['nextCursor'] as String?);
    },
  );

  @override
  Future<Either<Failure, List<MessageEntity>>> forwardMessages({
    required List<String> messageIds,
    required List<String> targetConversationIds,
    String? sourceConversationId,
  }) => safePost<List<MessageEntity>>(
    '/chat/messages/forward',
    data: {
      'messageIds': messageIds,
      'targetConversationIds': targetConversationIds,
      'sourceConversationId': ?sourceConversationId,
    },
    extractKey: 'data.messages',
    customMapper: (list) =>
        (list as List?)
            ?.whereType<Map>()
            .map((e) => MessageEntity.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [],
  );
}

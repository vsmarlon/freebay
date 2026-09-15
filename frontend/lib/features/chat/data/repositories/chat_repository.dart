import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';
import 'package:freebay/features/profile/data/entities/block_responses.dart';

class ChatRepository extends BaseHttpRepository {
  ChatRepository({super.client});

  Future<Either<Failure, CursorPage<ChatEntity>>> getChats({
    String? query,
    String? cursor,
    int? limit,
  }) => safePage<ChatEntity>(
    '/chat/conversations',
    ChatEntity.fromJson,
    cursor: cursor,
    limit: limit,
    queryParameters: {'q': ?query?.isNotEmpty == true ? query : null},
  );

  Future<Either<Failure, CursorPage<ChatEntity>>> getArchivedChats({
    String? cursor,
    int limit = 50,
  }) => safePage<ChatEntity>(
    '/chat/archived',
    ChatEntity.fromJson,
    cursor: cursor,
    limit: limit,
  );

  Future<Either<Failure, String>> startDirectConversation(
    String targetUserId, {
    String? productId,
  }) => safePost<String>(
    '/chat/conversations',
    data: {'targetUserId': targetUserId, 'productId': ?productId},
    extractKey: 'data.conversationId',
    customMapper: (id) => id as String,
  );

  Future<
    Either<
      Failure,
      ({
        List<MessageEntity> messages,
        bool hasMore,
        String? nextCursor,
        String threadType,
        String otherUserId,
        String otherUserName,
        String? otherUserAvatarUrl,
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
          final data = response.data['data'];
          if (data is! Map<String, dynamic>) {
            return const Left(ServerFailure('Resposta inválida do servidor.'));
          }
          final rawOtherUser = data['otherUser'];
          if (rawOtherUser is! Map) {
            return const Left(ServerFailure('Resposta inválida do servidor.'));
          }
          final otherUser = Map<String, dynamic>.from(rawOtherUser);
          final otherUserId = otherUser['id'];
          if (otherUserId is! String) {
            return const Left(ServerFailure('Resposta inválida do servidor.'));
          }
          final displayName = otherUser['displayName'];
          final otherUserName =
              displayName is String && displayName.trim().isNotEmpty
              ? displayName
              : 'Usuário';
          final rawMessages = (data['messages'] as List?) ?? const [];
          final messages = rawMessages
              .whereType<Map>()
              .map((m) => MessageEntity.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          final threadType = data['threadType'];
          if (threadType is! String) {
            return const Left(ServerFailure('Resposta inválida do servidor.'));
          }
          final rawPref = data['preference'];
          final preference = rawPref is Map
              ? ConversationPreference.fromJson(
                  Map<String, dynamic>.from(rawPref),
                )
              : null;

          return Right((
            messages: messages,
            hasMore: data['hasMore'] == true,
            nextCursor: data['nextCursor'] as String?,
            threadType: threadType,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserAvatarUrl: otherUser['avatarUrl'] as String?,
            preference: preference,
          ));
        },
      );

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

  Future<Either<Failure, void>> markAsRead(String chatId) =>
      safeVoid(() => client.patch('/chat/conversations/$chatId/read'));

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

  Future<Either<Failure, void>> deleteChat(String id, ChatThreadType type) =>
      safeVoid(() => client.patch('/chat/conversations/$id/delete'));

  Future<Either<Failure, BlockResponse>> blockUser(String userId) =>
      safePost<BlockResponse>(
        '/users/$userId/block',
        extractKey: 'data',
        fromJson: BlockResponse.fromJson,
      );

  Future<Either<Failure, ConversationPreference>> setTheme(
    String id,
    ChatThreadType type,
    String theme,
  ) => safePatch<ConversationPreference>(
    '/chat/conversations/$id/theme',
    data: {'theme': theme},
    extractKey: 'data',
    fromJson: ConversationPreference.fromJson,
  );

  Future<Either<Failure, ConversationPreference>> setBackground(
    String id,
    ChatThreadType type,
    String base64DataUri,
  ) => safePatch<ConversationPreference>(
    '/chat/conversations/$id/background',
    data: {'backgroundUrl': base64DataUri},
    extractKey: 'data',
    fromJson: ConversationPreference.fromJson,
  );

  Future<Either<Failure, MessageEntity>> sendRichMessage({
    required String conversationId,
    String? clientMessageId,
    String? content,
    String type = 'TEXT',
    String? attachmentUrl,
    String? replyToId,
    Map<String, dynamic>? metadata,
    bool viewOnce = false,
    int? durationMs,
  }) => safePost<MessageEntity>(
    '/chat/conversations/$conversationId/messages',
    data: {
      'type': type,
      'clientMessageId': ?clientMessageId,
      'content': ?content,
      'attachmentUrl': ?attachmentUrl,
      'replyToId': ?replyToId,
      'metadata': ?metadata,
      'durationMs': ?durationMs,
      if (viewOnce) 'viewOnce': true,
    },
    extractKey: 'data',
    fromJson: MessageEntity.fromJson,
  );

  Future<Either<Failure, void>> deleteMessage(
    String conversationId,
    String messageId,
  ) => safeVoid(
    () => client.patch(
      '/chat/conversations/$conversationId/messages/$messageId/delete',
    ),
  );

  Future<Either<Failure, bool>> toggleStar(
    String conversationId,
    String messageId,
  ) => safePost<bool>(
    '/chat/conversations/$conversationId/messages/$messageId/star',
    extractKey: 'data.starred',
    customMapper: (starred) => starred == true,
  );

  Future<Either<Failure, List<MessageEntity>>> getStarredMessages(
    String conversationId,
  ) => safeGetList<MessageEntity>(
    '/chat/conversations/$conversationId/starred',
    fromJson: MessageEntity.fromJson,
  );

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

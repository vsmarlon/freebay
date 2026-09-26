import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_media_filter.dart';
import 'package:freebay/features/profile/data/entities/block_responses.dart';

const _archivedChatsPageLimit = 50;
const _conversationMediaPageLimit = 50;

class ChatRepository {
  final Dio client;

  ChatRepository({Dio? client}) : client = client ?? HttpClient.instance;

  Future<Either<Failure, CursorPage<ChatEntity>>> getChats({
    String? query,
    String? cursor,
    int? limit,
  }) => requestEither<CursorPage<ChatEntity>>(
    () => client.get(
      '/chat/conversations',
      queryParameters: {
        'q': ?query?.isNotEmpty == true ? query : null,
        'cursor': ?cursor,
        'limit': ?limit,
      },
    ),
    decoder: (response) => Right(
      parseCursorPage<ChatEntity>(response.data['data'], ChatEntity.fromJson),
    ),
  );

  Future<Either<Failure, CursorPage<ChatEntity>>> getArchivedChats({
    String? cursor,
    int limit = _archivedChatsPageLimit,
  }) => requestEither<CursorPage<ChatEntity>>(
    () => client.get(
      '/chat/archived',
      queryParameters: {'cursor': ?cursor, 'limit': limit},
    ),
    decoder: (response) => Right(
      parseCursorPage<ChatEntity>(response.data['data'], ChatEntity.fromJson),
    ),
  );

  Future<Either<Failure, String>> startDirectConversation(
    String targetUserId, {
    String? productId,
  }) => requestEither(
    () => client.post(
      '/chat/conversations',
      data: {'targetUserId': targetUserId, 'productId': ?productId},
    ),
    decoder: (response) =>
        Right(response.data['data']['conversationId'] as String),
  );

  Future<
    Either<
      Failure,
      ({
        List<MessageEntity> messages,
        bool hasMore,
        String? nextCursor,
        ChatThreadType threadType,
        String otherUserId,
        String otherUserName,
        String? otherUserAvatarUrl,
        ConversationPreference? preference,
      })
    >
  >
  getConversation(String conversationId, {String? cursor, int? limit}) =>
      requestEither(
        () => client.get(
          '/chat/conversations/$conversationId',
          queryParameters: {'cursor': ?cursor, 'limit': ?limit},
        ),
        decoder: (response) {
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
          final threadType = ChatThreadType.fromWire(data['threadType']);
          if (threadType == null) {
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
  }) => requestEither(
    () => client.post(
      '/chat/conversations/$chatId/messages',
      data: {
        'content': message,
        'replyToId': ?replyToId,
        'clientMessageId': ?clientMessageId,
        if (viewOnce) 'viewOnce': true,
      },
    ),
    decoder: (response) => Right(MessageEntity.fromJson(response.data['data'])),
  );

  Future<Either<Failure, void>> markAsRead(String chatId) =>
      requestEither<void>(
        () => client.patch('/chat/conversations/$chatId/read'),
        decoder: (_) => const Right(null),
      );

  Future<Either<Failure, void>> archiveChat(
    String id,
    ChatThreadType type,
    bool archived,
  ) => requestEither<void>(
    () => client.patch(
      '/chat/conversations/$id/archive',
      data: {'archived': archived},
    ),
    decoder: (_) => const Right(null),
  );

  Future<Either<Failure, void>> deleteChat(String id, ChatThreadType type) =>
      requestEither<void>(
        () => client.patch('/chat/conversations/$id/delete'),
        decoder: (_) => const Right(null),
      );

  Future<Either<Failure, BlockResponse>> blockUser(String userId) =>
      requestEither(
        () => client.post('/users/$userId/block'),
        decoder: (response) =>
            Right(BlockResponse.fromJson(response.data['data'])),
      );

  Future<Either<Failure, ConversationPreference>> setTheme(
    String id,
    ChatThreadType type,
    String theme,
  ) => requestEither(
    () => client.patch('/chat/conversations/$id/theme', data: {'theme': theme}),
    decoder: (response) =>
        Right(ConversationPreference.fromJson(response.data['data'])),
  );

  Future<Either<Failure, ConversationPreference>> setBackground(
    String id,
    ChatThreadType type,
    String base64DataUri,
  ) => requestEither(
    () => client.patch(
      '/chat/conversations/$id/background',
      data: {'backgroundUrl': base64DataUri},
    ),
    decoder: (response) =>
        Right(ConversationPreference.fromJson(response.data['data'])),
  );

  Future<Either<Failure, MessageEntity>> sendRichMessage({
    required String conversationId,
    String? clientMessageId,
    String? content,
    MessageType type = MessageType.text,
    String? attachmentUrl,
    String? replyToId,
    Map<String, dynamic>? metadata,
    bool viewOnce = false,
    int? durationMs,
  }) => requestEither(
    () => client.post(
      '/chat/conversations/$conversationId/messages',
      data: {
        'type': type.wireValue,
        'clientMessageId': ?clientMessageId,
        'content': ?content,
        'attachmentUrl': ?attachmentUrl,
        'replyToId': ?replyToId,
        'metadata': ?metadata,
        'durationMs': ?durationMs,
        if (viewOnce) 'viewOnce': true,
      },
    ),
    decoder: (response) => Right(MessageEntity.fromJson(response.data['data'])),
  );

  Future<Either<Failure, void>> deleteMessage(
    String conversationId,
    String messageId,
  ) => requestEither<void>(
    () => client.patch(
      '/chat/conversations/$conversationId/messages/$messageId/delete',
    ),
    decoder: (_) => const Right(null),
  );

  Future<Either<Failure, bool>> toggleStar(
    String conversationId,
    String messageId,
  ) => requestEither(
    () => client.post(
      '/chat/conversations/$conversationId/messages/$messageId/star',
    ),
    decoder: (response) => Right(response.data['data']['starred'] == true),
  );

  Future<Either<Failure, List<MessageEntity>>> getStarredMessages(
    String conversationId,
  ) => requestEither(
    () => client.get('/chat/conversations/$conversationId/starred'),
    decoder: (response) {
      final raw = response.data['data'];
      return Right(
        raw is List
            ? raw
                  .whereType<Map>()
                  .map(
                    (item) =>
                        MessageEntity.fromJson(Map<String, dynamic>.from(item)),
                  )
                  .toList()
            : <MessageEntity>[],
      );
    },
  );

  Future<Either<Failure, List<MessageReactionEntity>>> reactToMessage(
    String conversationId,
    String messageId,
    String emoji,
  ) => requestEither(
    () => client.post(
      '/chat/conversations/$conversationId/messages/$messageId/react',
      data: {'emoji': emoji},
    ),
    decoder: (response) {
      final raw = response.data['data']['reactions'];
      return Right(
        raw is List
            ? raw
                  .whereType<Map>()
                  .map(
                    (e) => MessageReactionEntity.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList()
            : <MessageReactionEntity>[],
      );
    },
  );

  Future<Either<Failure, ({List<MessageEntity> messages, String? nextCursor})>>
  getConversationMedia(
    String conversationId, {
    ConversationMediaFilter type = ConversationMediaFilter.image,
    int limit = _conversationMediaPageLimit,
    String? cursor,
  }) => requestEither<({List<MessageEntity> messages, String? nextCursor})>(
    () => client.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {
        'type': type.wireValue,
        'limit': limit,
        'cursor': ?cursor,
      },
    ),
    decoder: (response) {
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final rawMessages = (data['messages'] as List?) ?? [];
      final messages = rawMessages
          .whereType<Map>()
          .map((m) => MessageEntity.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      return Right((
        messages: messages,
        nextCursor: data['nextCursor'] as String?,
      ));
    },
  );

  Future<Either<Failure, List<MessageEntity>>> forwardMessages({
    required List<String> messageIds,
    required List<String> targetConversationIds,
    String? sourceConversationId,
  }) => requestEither(
    () => client.post(
      '/chat/messages/forward',
      data: {
        'messageIds': messageIds,
        'targetConversationIds': targetConversationIds,
        'sourceConversationId': ?sourceConversationId,
      },
    ),
    decoder: (response) {
      final raw = response.data['data']['messages'];
      return Right(
        raw is List
            ? raw
                  .whereType<Map>()
                  .map(
                    (e) => MessageEntity.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
            : <MessageEntity>[],
      );
    },
  );
}

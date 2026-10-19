import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/features/chat/presentation/providers/conversation_messages_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/chat_socket_service.dart';

class _FakeSocket implements ChatSocketClient {
  final callbacks = <String, void Function(dynamic)>{};
  bool connectedValue = false;

  @override
  bool get connected => connectedValue;

  @override
  void connect() {
    connectedValue = true;
  }

  @override
  void dispose() {
    connectedValue = false;
  }

  @override
  void emit(String event, [dynamic data]) {}

  @override
  void onConnect(void Function(dynamic) callback) {
    callbacks['connect'] = callback;
  }

  @override
  void onConnectError(void Function(dynamic) callback) {
    callbacks['connect_error'] = callback;
  }

  @override
  void onDisconnect(void Function(dynamic) callback) {
    callbacks['disconnect'] = callback;
  }

  @override
  void on(String event, void Function(dynamic) callback) {
    callbacks[event] = callback;
  }
}

class _AuthController extends AuthController {
  @override
  AsyncValue<UserEntity?> build() =>
      const AsyncValue.data(UserEntity(id: 'reader-1'));
}

class _ChatRepository extends ChatRepository {
  _ChatRepository() : super(client: Dio());

  int transcriptReads = 0;
  bool includeViewOnce = false;
  bool failFirstViewOnceOpen = false;
  final openingKeys = <String>[];
  final closedOpeningKeys = <String>[];

  @override
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
  getConversation(String conversationId, {String? cursor, int? limit}) async {
    transcriptReads++;
    return Right((
      messages: [
        MessageEntity(
          id: 'message-1',
          conversationId: conversationId,
          senderId: 'sender-1',
          content: 'canonical-$transcriptReads',
          createdAt: DateTime.utc(2026),
        ),
        if (includeViewOnce)
          MessageEntity(
            id: 'view-once-1',
            conversationId: conversationId,
            senderId: 'sender-1',
            type: MessageType.image,
            attachmentUrl: '/media/locked',
            viewOnce: true,
            createdAt: DateTime.utc(2026),
          ),
      ],
      hasMore: false,
      nextCursor: null,
      threadType: ChatThreadType.direct,
      otherUserId: 'sender-1',
      otherUserName: 'Sender',
      otherUserAvatarUrl: null,
      preference: null,
    ));
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getStarredMessages(
    String conversationId,
  ) async => const Right([]);

  @override
  Future<Either<Failure, ({String mediaUrl, DateTime readAt})>> openViewOnce(
    String conversationId,
    String messageId,
    String openingKey,
  ) async {
    openingKeys.add(openingKey);
    if (failFirstViewOnceOpen && openingKeys.length == 1) {
      return const Left(ServerFailure());
    }
    return Right((mediaUrl: '/media/opened', readAt: DateTime.utc(2026, 1, 2)));
  }

  @override
  Future<Either<Failure, void>> closeViewOnce(
    String conversationId,
    String messageId,
    String openingKey,
  ) async {
    closedOpeningKeys.add(openingKey);
    return const Right(null);
  }
}

void main() {
  test(
    'view-once retry reuses its key and unmount closes the opened session',
    () async {
      final socket = _FakeSocket();
      final service = ChatSocketService(
        tokenReader: () async => 'token',
        socketFactory: (_, _) => socket,
        connectivityStream: () =>
            const Stream<List<ConnectivityResult>>.empty(),
      );
      final repository = _ChatRepository()
        ..includeViewOnce = true
        ..failFirstViewOnceOpen = true;
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repository),
          chatSocketServiceProvider.overrideWithValue(service),
          authControllerProvider.overrideWith(_AuthController.new),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(service.dispose);
      await service.connect();
      final subscription = container.listen(
        conversationMessagesProvider('conversation-1'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      Future<void> flush() async {
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      await flush();
      final notifier = container.read(
        conversationMessagesProvider('conversation-1').notifier,
      );
      expect((await notifier.revealViewOnce('view-once-1')).isLeft, isTrue);
      final openingKey = notifier.viewOnceOpeningKey('view-once-1');
      expect(openingKey, isNotNull);
      expect((await notifier.revealViewOnce('view-once-1')).isRight, isTrue);
      expect(repository.openingKeys, [openingKey, openingKey]);
      expect(
        container
            .read(conversationMessagesProvider('conversation-1'))
            .messages
            .singleWhere((message) => message.id == 'view-once-1')
            .attachmentUrl,
        '/media/opened',
      );
      socket.callbacks['messages_read']?.call({
        'conversationId': 'conversation-1',
        'readerId': 'sender-1',
      });
      await flush();
      expect(repository.transcriptReads, 2);
      expect(repository.closedOpeningKeys, isEmpty);
      expect(
        container
            .read(conversationMessagesProvider('conversation-1'))
            .messages
            .singleWhere((message) => message.id == 'view-once-1')
            .attachmentUrl,
        '/media/opened',
      );

      subscription.close();
      await flush();
      expect(repository.closedOpeningKeys, [openingKey]);
    },
  );

  test(
    'other-reader and reconnect events refetch canonical transcript',
    () async {
      final socket = _FakeSocket();
      final service = ChatSocketService(
        tokenReader: () async => 'token',
        socketFactory: (_, _) => socket,
        connectivityStream: () =>
            const Stream<List<ConnectivityResult>>.empty(),
      );
      final repository = _ChatRepository();
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repository),
          chatSocketServiceProvider.overrideWithValue(service),
          authControllerProvider.overrideWith(_AuthController.new),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(service.dispose);
      await service.connect();
      final subscription = container.listen(
        conversationMessagesProvider('conversation-1'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      Future<void> flush() async {
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      await flush();
      expect(repository.transcriptReads, 1);

      socket.callbacks['messages_read']?.call({
        'conversationId': 'conversation-1',
        'readerId': 'sender-1',
      });
      await flush();
      expect(repository.transcriptReads, 2);
      expect(
        container
            .read(conversationMessagesProvider('conversation-1'))
            .messages
            .single
            .content,
        'canonical-2',
      );

      socket.callbacks['connect']?.call(null);
      await flush();
      expect(repository.transcriptReads, 3);
      expect(
        container
            .read(conversationMessagesProvider('conversation-1'))
            .messages
            .single
            .content,
        'canonical-3',
      );

      socket.callbacks['messages_read']?.call({
        'conversationId': 'another-conversation',
        'readerId': 'sender-1',
      });
      await flush();
      expect(repository.transcriptReads, 3);

      socket.callbacks['messages_read']?.call({
        'conversationId': 'conversation-1',
        'readerId': 'reader-1',
      });
      await flush();
      expect(repository.transcriptReads, 3);
    },
  );
}

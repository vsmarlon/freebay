import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/conversation_messages_provider.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_header.dart';
import 'package:freebay/features/chat/presentation/widgets/message_bubble.dart';
import 'package:freebay/features/chat/presentation/widgets/reply_preview_banner.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _ChatRepository extends ChatRepository {
  _ChatRepository({this.messages});

  final List<MessageEntity>? messages;
  var conversationCalls = 0;
  final conversationCallsById = <String, int>{};

  @override
  Future<Either<Failure, CursorPage<ChatEntity>>> getChats({
    String? query,
    String? cursor,
    int? limit,
  }) async {
    return const Right(CursorPage.empty());
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getStarredMessages(
    String conversationId,
  ) async {
    return const Right([]);
  }

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
    conversationCalls++;
    conversationCallsById[conversationId] =
        (conversationCallsById[conversationId] ?? 0) + 1;
    return Right((
      messages:
          messages ??
          [
            MessageEntity(
              id: 'm-$conversationId',
              conversationId: conversationId,
              senderId: 'user-2',
              content: 'Oi $conversationId',
              createdAt: DateTime(2026),
            ),
          ],
      hasMore: false,
      nextCursor: null,
      threadType: ChatThreadType.direct,
      otherUserId: 'user-2',
      otherUserName: 'Vendedor $conversationId',
      otherUserAvatarUrl: null,
      preference: null,
    ));
  }
}

List<MessageEntity> _longConversationMessages() {
  final target = MessageEntity(
    id: 'target',
    conversationId: 'conv-1',
    senderId: 'user-2',
    content: 'old quote target',
    createdAt: DateTime(2026),
  );
  return [
    target,
    for (var i = 1; i < 40; i++)
      MessageEntity(
        id: 'message-$i',
        conversationId: 'conv-1',
        senderId: 'user-2',
        content: 'message $i ${'variable height ' * (i % 4 + 1)}',
        createdAt: DateTime(2026, 1, 1, 0, i),
      ),
    MessageEntity(
      id: 'reply',
      conversationId: 'conv-1',
      senderId: 'user-2',
      content: 'reply trigger',
      replyToId: target.id,
      replyTo: target,
      createdAt: DateTime(2026, 1, 1, 1),
    ),
  ];
}

void main() {
  test(
    'releases conversation transcript when its last listener leaves',
    () async {
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(_ChatRepository()),
        ],
      );
      addTearDown(container.dispose);
      final provider = conversationMessagesProvider('conv-unused');
      final subscription = container.listen(provider, (_, _) {});
      expect(container.exists(provider), isTrue);

      subscription.close();
      await container.pump();

      expect(container.exists(provider), isFalse);
    },
  );

  testWidgets('opens a conversation without throwing', (tester) async {
    final repository = _ChatRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'user-1')),
          ),
          chatRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatConversationPage(chatId: 'conv-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ChatConversationPage), findsOneWidget);
    expect(find.text('Vendedor conv-1'), findsOneWidget);
    expect(find.text('Conversa'), findsNothing);
    expect(repository.conversationCalls, 1);
  });

  testWidgets('reply tap reveals and highlights an offscreen quoted message', (
    tester,
  ) async {
    final messages = _longConversationMessages();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'user-1')),
          ),
          chatRepositoryProvider.overrideWithValue(
            _ChatRepository(messages: messages),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatConversationPage(chatId: 'conv-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final highlightedTarget = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.color == AppColors.primaryContainer.withValues(alpha: 0.18),
    );
    expect(highlightedTarget, findsNothing);
    await tester.tap(find.byType(ReplyPreviewBanner));
    await tester.pumpAndSettle();

    expect(highlightedTarget, findsOneWidget);
    expect(
      tester
          .getRect(highlightedTarget)
          .overlaps(tester.getRect(find.byType(ListView))),
      isTrue,
    );
    expect(
      find.descendant(
        of: highlightedTarget,
        matching: find.text('old quote target', findRichText: true),
      ),
      findsOneWidget,
    );
  });

  testWidgets('quote traversal cancels on conversation switch and disposal', (
    tester,
  ) async {
    final repository = _ChatRepository(messages: _longConversationMessages());
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => TestAuthController(testUser(id: 'user-1')),
        ),
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    Future<void> showConversation(String chatId) => tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatConversationPage(chatId: chatId),
        ),
      ),
    );

    await showConversation('conv-1');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ReplyPreviewBanner));
    await showConversation('conv-2');
    await tester.pumpAndSettle();
    expect(find.text('Vendedor conv-2'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(ReplyPreviewBanner));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('retained conversation rebinds state and refreshes its theme', (
    tester,
  ) async {
    final repository = _ChatRepository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => TestAuthController(testUser(id: 'user-1')),
        ),
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatConversationPage(chatId: 'conv-1'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Vendedor conv-1'), findsOneWidget);
    expect(repository.conversationCallsById['conv-1'], 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatConversationPage(chatId: 'conv-2'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Vendedor conv-2'), findsOneWidget);
    expect(find.text('Oi conv-1'), findsNothing);
    expect(repository.conversationCallsById['conv-2'], 1);

    container
        .read(conversationMessagesProvider('conv-1').notifier)
        .addOptimistic(
          MessageEntity(
            id: 'stale',
            conversationId: 'conv-1',
            senderId: 'user-2',
            content: 'stale old conversation',
            createdAt: DateTime(2026),
          ),
        );
    await tester.pump();
    expect(find.text('stale old conversation'), findsNothing);

    final currentNotifier = container.read(
      conversationMessagesProvider('conv-2').notifier,
    );
    currentNotifier.addOptimistic(
      MessageEntity(
        id: 'current',
        conversationId: 'conv-2',
        senderId: 'user-2',
        content: 'current conversation message',
        createdAt: DateTime(2026),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      container
          .read(conversationMessagesProvider('conv-2'))
          .messages
          .any((message) => message.id == 'current'),
      isTrue,
    );
    expect(find.byType(MessageBubble), findsNWidgets(2));

    currentNotifier.setPreference(
      const ConversationPreference(theme: 'CRIMSON'),
    );
    await tester.pumpAndSettle();
    final header = tester.widget<ChatHeader>(find.byType(ChatHeader));
    expect(header.accentColor, const Color(0xFFDC2626));
  });
}

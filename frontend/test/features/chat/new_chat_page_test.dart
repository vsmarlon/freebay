import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/presentation/pages/new_chat_page.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/profile/data/entities/block_responses.dart';
import 'package:freebay/features/profile/presentation/pages/blocked_users_page.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import '../../support/auth_test_doubles.dart';

class _ChatRepository extends ChatRepository {
  int starts = 0;
  int sends = 0;
  bool failNextSend = false;
  Completer<void>? startGate;
  final List<String?> clientMessageIds = [];
  final List<String> messages = [];

  @override
  Future<Either<Failure, String>> startDirectConversation(
    String targetUserId, {
    String? productId,
  }) async {
    starts++;
    if (startGate != null) await startGate!.future;
    return const Right('conversation-1');
  }

  @override
  Future<Either<Failure, CursorPage<ChatEntity>>> getChats({
    String? query,
    String? cursor,
    int? limit,
  }) async {
    return const Right(CursorPage.empty());
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage(
    String chatId,
    String message, {
    String? replyToId,
    bool viewOnce = false,
    String? clientMessageId,
  }) async {
    sends++;
    messages.add(message);
    clientMessageIds.add(clientMessageId);
    if (failNextSend) {
      failNextSend = false;
      return const Left(ServerFailure('send failed'));
    }
    return Right(
      MessageEntity(
        id: 'message-1',
        conversationId: chatId,
        senderId: 'buyer-1',
        content: message,
        clientMessageId: clientMessageId,
        createdAt: DateTime(2026),
      ),
    );
  }
}

class _UserSearch extends UserSearch {
  @override
  UserSearchState build() => const UserSearchState();
}

class _Suggestions extends Suggestions {
  @override
  SuggestionsState build() => const SuggestionsState();
}

Widget _app(NewChatPage page, _ChatRepository repository) {
  final router = GoRouter(
    initialLocation: AppRoutes.chatNew,
    routes: [
      GoRoute(path: AppRoutes.chatNew, builder: (context, state) => page),
      GoRoute(path: '/chat/:id', builder: (context, state) => const SizedBox()),
    ],
  );
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => TestAuthController(null)),
      chatRepositoryProvider.overrideWithValue(repository),
      blockedUsersProvider.overrideWith(
        (ref) async => const BlockListResponse(limit: 0, offset: 0),
      ),
      userSearchProvider.overrideWith(_UserSearch.new),
      suggestionsProvider.overrideWith(_Suggestions.new),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows the exact editable product draft', (tester) async {
    await tester.pumpWidget(
      _app(
        const NewChatPage(targetUserId: 'seller-1', productId: 'product-1'),
        _ChatRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Oi, ainda está disponível?',
    );
  });

  testWidgets('sends edited text explicitly once with one client id', (
    tester,
  ) async {
    final repository = _ChatRepository();
    await tester.pumpWidget(
      _app(
        const NewChatPage(targetUserId: 'seller-1', productId: 'product-1'),
        repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Ainda tem?');
    await tester.tap(find.text('ENVIAR MENSAGEM'));
    await tester.pumpAndSettle();

    expect(repository.starts, 1);
    expect(repository.sends, 1);
    expect(repository.messages, ['Ainda tem?']);
    expect(repository.clientMessageIds.single, isNotNull);
  });

  testWidgets('back does not start or send a product conversation', (
    tester,
  ) async {
    final repository = _ChatRepository();
    await tester.pumpWidget(
      _app(
        const NewChatPage(targetUserId: 'seller-1', productId: 'product-1'),
        repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(repository.starts, 0);
    expect(repository.sends, 0);
  });

  testWidgets('duplicate product send taps are guarded', (tester) async {
    final repository = _ChatRepository()..startGate = Completer<void>();
    await tester.pumpWidget(
      _app(
        const NewChatPage(targetUserId: 'seller-1', productId: 'product-1'),
        repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ENVIAR MENSAGEM'));
    await tester.tap(find.text('ENVIAR MENSAGEM'));

    expect(repository.starts, 1);
    repository.startGate!.complete();
    await tester.pumpAndSettle();
    expect(repository.sends, 1);
  });

  testWidgets('failed send can retry with the same client id', (tester) async {
    final repository = _ChatRepository()..failNextSend = true;
    await tester.pumpWidget(
      _app(
        const NewChatPage(targetUserId: 'seller-1', productId: 'product-1'),
        repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ENVIAR MENSAGEM'));
    await tester.pumpAndSettle();
    final firstId = repository.clientMessageIds.single;

    await tester.tap(find.text('ENVIAR MENSAGEM'));
    await tester.pumpAndSettle();

    expect(repository.sends, 2);
    expect(repository.clientMessageIds, [firstId, firstId]);
  });

  testWidgets('whitespace-only product draft disables sending', (tester) async {
    await tester.pumpWidget(
      _app(
        const NewChatPage(targetUserId: 'seller-1', productId: 'product-1'),
        _ChatRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.pump();

    expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
  });

  testWidgets('changed draft after failed send gets a new client id', (
    tester,
  ) async {
    final repository = _ChatRepository()..failNextSend = true;
    await tester.pumpWidget(
      _app(
        const NewChatPage(targetUserId: 'seller-1', productId: 'product-1'),
        repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ENVIAR MENSAGEM'));
    await tester.pumpAndSettle();
    final firstId = repository.clientMessageIds.single;

    await tester.enterText(find.byType(TextFormField), 'Mensagem alterada');
    await tester.tap(find.text('ENVIAR MENSAGEM'));
    await tester.pumpAndSettle();

    expect(repository.clientMessageIds, hasLength(2));
    expect(repository.clientMessageIds[1], isNot(firstId));
  });

  testWidgets('generic new-chat route still renders the picker', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const NewChatPage(), _ChatRepository()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(NewChatPage), findsOneWidget);
  });
}

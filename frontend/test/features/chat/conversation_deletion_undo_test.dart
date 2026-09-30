import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/presentation/pages/chat_list_page.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _ChatRepository extends ChatRepository {
  final deleted = <String>[];

  @override
  Future<Either<Failure, CursorPage<ChatEntity>>> getChats({
    String? query,
    String? cursor,
    int? limit,
  }) async => Right(
    CursorPage(
      items: [
        ChatEntity(
          id: 'chat-1',
          threadType: ChatThreadType.direct,
          otherUser: testUser(id: 'other', displayName: 'Maria'),
          createdAt: DateTime(2026),
        ),
      ],
      hasMore: false,
    ),
  );

  @override
  Future<Either<Failure, void>> deleteChat(
    String id,
    ChatThreadType type,
  ) async {
    deleted.add(id);
    return const Right(null);
  }
}

void main() {
  testWidgets('deleting a conversation can be undone before its request', (
    tester,
  ) async {
    final repository = _ChatRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'owner')),
          ),
          chatRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ChatListPage()),
      ),
    );
    await tester.pump();
    await tester.longPress(find.text('Maria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(repository.deleted, isEmpty);
    await tester.tap(find.text('DESFAZER'));
    await tester.pump(const Duration(seconds: 5));
    expect(repository.deleted, isEmpty);
  });
}

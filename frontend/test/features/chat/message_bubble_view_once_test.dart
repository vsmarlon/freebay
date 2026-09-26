import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/widgets/message_bubble.dart';

MessageEntity _message({
  bool viewOnce = false,
  DateTime? readAt,
  String? content,
  Map<String, dynamic>? metadata,
  MessageEntity? replyTo,
}) {
  return MessageEntity(
    id: 'message-1',
    conversationId: 'conversation-1',
    senderId: 'user-1',
    content: content,
    metadata: metadata,
    replyTo: replyTo,
    viewOnce: viewOnce,
    readAt: readAt,
    createdAt: DateTime(2026),
  );
}

Widget _app(MessageEntity message) {
  return MaterialApp(
    home: Scaffold(
      body: MessageBubble(message: message, isMe: false, isDark: false),
    ),
  );
}

void main() {
  testWidgets('locked view-once messages hide their content', (tester) async {
    await tester.pumpWidget(_app(_message(viewOnce: true, content: 'segredo')));

    expect(find.text('Mensagem de\nvisualização única'), findsOneWidget);
    expect(find.text('segredo'), findsNothing);
    expect(find.text('Mensagem já visualizada'), findsNothing);
  });

  testWidgets('revealed view-once messages keep headers and viewed footer', (
    tester,
  ) async {
    final reply = _message(content: 'mensagem original');
    await tester.pumpWidget(
      _app(
        _message(
          viewOnce: true,
          readAt: DateTime(2026, 1, 2),
          content: 'mensagem revelada',
          metadata: {'isForwarded': true},
          replyTo: reply,
        ),
      ),
    );

    expect(find.text('Encaminhada'), findsOneWidget);
    expect(find.text('mensagem original'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText() == 'mensagem revelada',
      ),
      findsOneWidget,
    );
    expect(find.text('Mensagem já visualizada'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_media_gallery_viewer.dart';
import 'package:freebay/features/chat/presentation/widgets/image_message_bubble.dart';
import 'package:freebay/features/chat/presentation/widgets/message_bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';

MessageEntity _message({
  bool viewOnce = false,
  String senderId = 'user-2',
  DateTime? readAt,
  String? content,
  Map<String, dynamic>? metadata,
  MessageEntity? replyTo,
  MessageType type = MessageType.text,
  String? attachmentUrl,
}) {
  return MessageEntity(
    id: 'message-1',
    conversationId: 'conversation-1',
    senderId: senderId,
    content: content,
    type: type,
    attachmentUrl: attachmentUrl,
    metadata: metadata,
    replyTo: replyTo,
    viewOnce: viewOnce,
    readAt: readAt,
    createdAt: DateTime(2026),
  );
}

Widget _app(
  MessageEntity message, {
  String? viewOnceOpeningKey,
  bool isMe = false,
  VoidCallback? onViewOnceReveal,
  VoidCallback? onViewOnceClose,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MessageBubble(
        message: message,
        isMe: isMe,
        isDark: false,
        viewOnceOpeningKey: viewOnceOpeningKey,
        onViewOnceReveal: onViewOnceReveal,
        onViewOnceClose: onViewOnceClose,
      ),
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

  testWidgets('sender cannot open view-once content', (tester) async {
    var opens = 0;
    await tester.pumpWidget(
      _app(
        _message(viewOnce: true, senderId: 'user-1', content: 'segredo'),
        isMe: true,
        onViewOnceReveal: () => opens++,
      ),
    );

    await tester.tap(find.text('Mensagem de\nvisualização única'));
    expect(opens, 0);
    expect(find.text('segredo'), findsNothing);
  });

  testWidgets('revealed media closes when the bubble unmounts', (tester) async {
    var closes = 0;
    await tester.pumpWidget(
      _app(
        _message(viewOnce: true, readAt: DateTime(2026), content: 'opened'),
        viewOnceOpeningKey: 'opening-key',
        onViewOnceClose: () => closes++,
      ),
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == 'opened',
      ),
      findsOneWidget,
    );
    expect(closes, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(closes, 1);
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
        viewOnceOpeningKey: 'opening-key',
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

  testWidgets('unknown wire messages render safely without recursion', (
    tester,
  ) async {
    final message = MessageEntity.fromJson({
      'id': 'unknown-message',
      'conversationId': 'conversation-1',
      'senderId': 'user-1',
      'type': 'UNRECOGNIZED_FUTURE_TYPE',
      'createdAt': DateTime(2026).toIso8601String(),
      'content': 'Unsupported attachment',
    });
    await tester.pumpWidget(_app(message));
    await tester.pump();

    expect(find.text('Unsupported attachment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('private chat images bypass CachedNetworkImage disk cache', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ImageMessageBubble(
            imageUrl: '/media/private-image',
            isMe: false,
          ),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  test('consumed view-once media is not offered by the gallery', () {
    final media = _message(
      type: MessageType.image,
      attachmentUrl: '/media/view-once',
      viewOnce: true,
      readAt: DateTime(2026, 1, 2),
    );

    expect(ChatMediaGalleryViewer.extractMedia([media]), isEmpty);
  });
}

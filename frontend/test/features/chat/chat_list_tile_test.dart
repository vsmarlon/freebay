import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/last_message_info.dart';
import 'package:freebay/features/chat/data/entities/order_info.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_list_tile.dart';

ChatEntity _chat({
  required String id,
  required String name,
  required String productTitle,
  required String preview,
  required ChatThreadType threadType,
}) => ChatEntity(
  id: id,
  threadType: threadType,
  otherUser: UserEntity(id: '$id-user', displayName: name),
  lastMessageInfo: LastMessageInfo(content: preview, createdAt: DateTime(2020)),
  createdAt: DateTime(2020),
  orderInfo: threadType == ChatThreadType.order
      ? OrderInfo(status: 'PAID', productTitle: productTitle)
      : null,
  product: threadType == ChatThreadType.direct
      ? ChatProductInfo(id: '$id-product', title: productTitle)
      : null,
  unreadCount: 7,
);

void main() {
  testWidgets('renders context, preview, timestamp, and unread count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: SizedBox(
          width: 320,
          height: 640,
          child: Scaffold(
            body: ListView(
              children: [
                SizedBox(
                  height: 160,
                  child: ChatListTile(
                    chat: _chat(
                      id: 'direct',
                      name: 'Alice',
                      productTitle: 'Produto direto',
                      preview: 'Mensagem direta',
                      threadType: ChatThreadType.direct,
                    ),
                    isDark: false,
                    canSwipe: false,
                    onTap: () {},
                    onLongPress: () {},
                    onArchive: () async {},
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: ChatListTile(
                    chat: _chat(
                      id: 'order',
                      name: 'Bob',
                      productTitle: 'Produto pedido',
                      preview: 'Mensagem do pedido',
                      threadType: ChatThreadType.order,
                    ),
                    isDark: true,
                    canSwipe: false,
                    onTap: () {},
                    onLongPress: () {},
                    onArchive: () async {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Mensagem direta'), findsOneWidget);
    expect(find.text('Mensagem do pedido'), findsOneWidget);
    expect(find.text('Produto direto'), findsOneWidget);
    expect(find.text('Produto pedido'), findsOneWidget);
    expect(find.text('7'), findsNWidgets(2));
    expect(find.text('1/1'), findsNWidgets(2));
  });
}

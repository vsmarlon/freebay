import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/features/chat/presentation/pages/new_chat_page.dart';
import 'package:freebay/features/chat/presentation/pages/archived_chats_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:freebay/features/chat/presentation/pages/conversation_details_page.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';

final List<RouteBase> chatRoutes = [
  appCupertinoRoute(AppRoutes.chatNew, (context, state) => const NewChatPage()),
  appCupertinoRoute(
    AppRoutes.chatArchived,
    (context, state) => const ArchivedChatsPage(),
  ),
  appCupertinoRoute(AppRoutes.chatConversation, (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return ChatConversationPage(
      chatId: state.pathParameters['chatId']!,
      orderName: extra?['orderName'] ?? 'Conversa',
      orderAvatarUrl: extra?['orderAvatarUrl'],
      chatType: extra?['chatType'] ?? 'order',
    );
  }),
  appCupertinoRoute(AppRoutes.chatDetails, (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return ConversationDetailsPage(
      chatId: state.pathParameters['chatId']!,
      name: extra?['name'] ?? 'Conversa',
      avatarUrl: extra?['avatarUrl'],
      messages:
          (extra?['messages'] as List<dynamic>?)?.cast<MessageEntity>() ?? [],
    );
  }),
];

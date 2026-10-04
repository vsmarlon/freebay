import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/features/chat/presentation/pages/new_chat_page.dart';
import 'package:freebay/features/chat/presentation/pages/archived_chats_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:freebay/features/chat/presentation/pages/conversation_details_page.dart';
import 'package:freebay/features/media_editor/media_editor.dart';
import 'dart:typed_data';

final List<RouteBase> chatRoutes = [
  appCupertinoRoute(AppRoutes.imageEditor, (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return ImageEditorPage(
      initialImageBytes: extra['imageBytes'] as Uint8List,
      purpose: extra['purpose'] as ImageEditorPurpose,
      onComplete:
          extra['onComplete'] as Future<bool> Function(ImageEditorResult),
    );
  }),
  appCupertinoRoute(
    AppRoutes.chatNew,
    (context, state) => NewChatPage(
      targetUserId: state.uri.queryParameters['targetUserId'],
      productId: state.uri.queryParameters['productId'],
    ),
  ),
  appCupertinoRoute(
    AppRoutes.chatArchived,
    (context, state) => const ArchivedChatsPage(),
  ),
  appCupertinoRoute(
    AppRoutes.chatConversation,
    (context, state) =>
        ChatConversationPage(chatId: state.pathParameters['chatId']!),
  ),
  appCupertinoRoute(
    AppRoutes.chatDetails,
    (context, state) =>
        ConversationDetailsPage(chatId: state.pathParameters['chatId']!),
  ),
];

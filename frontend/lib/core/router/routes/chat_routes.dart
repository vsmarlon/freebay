import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/features/chat/presentation/pages/new_chat_page.dart';
import 'package:freebay/features/chat/presentation/pages/archived_chats_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:freebay/features/chat/presentation/pages/conversation_details_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_location_page.dart';
import 'package:freebay/features/media_editor/media_editor.dart';

final List<RouteBase> chatRoutes = [
  appCupertinoRoute(AppRoutes.imageEditor, (context, state) {
    final request = ImageEditorRouteRequest.resolve(state);
    if (request == null || !request.isValid) {
      debugPrint('image-editor-route diagnostic: request=$request uri=${state.uri} extra=${state.extra.runtimeType}');
      return AppErrorWidget(
        details: FlutterErrorDetails(
          exception: StateError('Image editor request unavailable'),
        ),
        action: AppErrorAction.back,
        onRecover: () async {
          if (!context.mounted) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.feed);
          }
        },
      );
    }
    return ImageEditorPage(
      initialImageBytes: request.imageBytes,
      purpose: request.purpose,
      initialViewOnce: request.initialViewOnce,
      onComplete: request.onComplete,
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
  appCupertinoRoute(AppRoutes.chatLocationView, (context, state) {
    final details = state.extra;
    return details is ChatLocationDetails
        ? ChatLocationPage(details: details)
        : AppErrorWidget(
            details: FlutterErrorDetails(
              exception: StateError('Shared location unavailable'),
            ),
          );
  }),
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

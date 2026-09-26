import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_search_bar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Search row of the chat list page.
Widget buildChatSearchBar(
  BuildContext context,
  WidgetRef ref,
  TextEditingController controller,
  void Function(String) onSearchChanged,
  bool isDark,
) {
  final hasQuery = ref.watch(
    chatListQueryProvider.select((query) => query.isNotEmpty),
  );
  return ChatSearchBar(
    controller: controller,
    onChanged: onSearchChanged,
    hasQuery: hasQuery,
    onClear: () {
      controller.clear();
      ref.read(chatListQueryProvider.notifier).state = '';
    },
    onArchiveTap: () => context.push(AppRoutes.chatArchived),
    onNewChatTap: () => context.push(AppRoutes.chatNew),
    isDark: isDark,
  );
}

/// Empty state of the chat list page.
Widget buildChatEmptyState(bool isSearching) {
  return Expanded(
    child: EmptyState(
      icon: isSearching ? Icons.search_off : Icons.chat_bubble_outline,
      title: isSearching ? 'NENHUM RESULTADO' : 'SEM CONVERSAS',
      subtitle: isSearching
          ? 'Tente buscar por outro nome'
          : 'Crie uma conversa ou receba uma mensagem para visualizar aqui.',
    ),
  );
}

/// Error state of the chat list page.
Widget buildChatErrorState(WidgetRef ref) {
  return Expanded(
    child: EmptyState.error(
      message:
          'Não foi possível carregar suas conversas. Verifique sua conexão.',
      onRetry: () {
        ref.invalidate(chatsProvider);
        ref.invalidate(liveChatListProvider);
      },
    ),
  );
}

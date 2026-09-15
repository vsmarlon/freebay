import 'dart:async';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_list_tile.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_search_bar.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _animationController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppMotion.base,
      vsync: this,
    );
    _animationController.forward();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(liveChatListProvider.notifier).fetchMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(chatListQueryProvider.notifier).state = value.trim();
    });
  }

  bool _canModifyOrderChat(ChatEntity chat) {
    if (chat.threadType == ChatThreadType.direct) return true;
    return chat.orderStatus == 'COMPLETED' || chat.orderStatus == 'CANCELLED';
  }

  Future<void> _archiveChat(ChatEntity chat) async {
    final result = await ref
        .read(chatRepositoryProvider)
        .archiveChat(chat.id, chat.threadType, !chat.isArchived);
    result.fold((failure) => AppSnackbar.error(context, failure.message), (_) {
      ref.invalidate(chatsProvider);
      ref.invalidate(liveChatListProvider);
      ref.invalidate(archivedChatListProvider);
      AppSnackbar.success(
        context,
        chat.isArchived ? 'Conversa restaurada' : 'Conversa arquivada',
      );
    });
  }

  void _confirmDelete(ChatEntity chat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conversa'),
        content: const Text(
          'Esta ação não pode ser desfeita. A conversa será ocultada para você.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteChat(chat);
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(ChatEntity chat) async {
    final result = await ref
        .read(chatRepositoryProvider)
        .deleteChat(chat.id, chat.threadType);
    result.fold((failure) => AppSnackbar.error(context, failure.message), (_) {
      ref.invalidate(chatsProvider);
      ref.invalidate(liveChatListProvider);
      ref.invalidate(archivedChatListProvider);
      AppSnackbar.success(context, 'Conversa excluída');
    });
  }

  void _showContextMenu(ChatEntity chat) {
    showBrutalistSheet(
      context: context,
      title: 'OPÇÕES DE CONVERSA',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(chat.isArchived ? Icons.unarchive : Icons.archive),
            title: Text(chat.isArchived ? 'Restaurar' : 'Arquivar'),
            enabled: _canModifyOrderChat(chat),
            onTap: () {
              Navigator.pop(ctx);
              _archiveChat(chat);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.error),
            ),
            enabled: _canModifyOrderChat(chat),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(chat);
            },
          ),
          if (!_canModifyOrderChat(chat))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Ações disponíveis apenas após o pedido ser concluído ou cancelado.',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = context.isDark;
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const PageHeader(text: 'MENSAGENS'),
            Expanded(
              child: GuestGateView(
                icon: Icons.chat_bubble_outline,
                title: 'MENSAGENS PRIVADAS',
                description:
                    'Negocie produtos, tire dúvidas e converse em tempo real com compradores e vendedores com segurança.',
                onLoginPressed: () => context.push(loginPathFrom(context)),
                onRegisterPressed: () => context.push(AppRoutes.register),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const PageHeader(text: 'MENSAGENS'),
          Expanded(
            child: Column(
              children: [
                _buildSearchBar(isDark),
                ref
                    .watch(liveChatListProvider)
                    .when(
                      data: (chats) {
                        final query = ref.watch(chatListQueryProvider);
                        final loadingMore = ref.watch(
                          chatListLoadingMoreProvider,
                        );
                        if (chats.isEmpty) {
                          return _buildEmptyState(query.isNotEmpty);
                        }
                        return Expanded(
                          child: AppRefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(chatsProvider);
                              ref.invalidate(liveChatListProvider);
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: chats.length + (loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == chats.length) {
                                  return ChatListLoadingTile(isDark: isDark);
                                }
                                final chat = chats[index];
                                return ChatListTile(
                                  chat: chat,
                                  isDark: isDark,
                                  canSwipe: _canModifyOrderChat(chat),
                                  onTap: () {
                                    context.push(AppRoutes.chatPath(chat.id));
                                  },
                                  onLongPress: () => _showContextMenu(chat),
                                  onArchive: () => _archiveChat(chat),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      loading: () => Expanded(
                        child: ListView.builder(
                          itemCount: 5,
                          itemBuilder: (context, index) =>
                              ChatListLoadingTile(isDark: isDark),
                        ),
                      ),
                      error: (error, stack) => _buildErrorState(),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final hasQuery = ref.watch(chatListQueryProvider).isNotEmpty;
    return ChatSearchBar(
      controller: _searchController,
      onChanged: _onSearchChanged,
      hasQuery: hasQuery,
      onClear: () {
        _searchController.clear();
        ref.read(chatListQueryProvider.notifier).state = '';
      },
      onArchiveTap: () => context.push(AppRoutes.chatArchived),
      onNewChatTap: () => context.push(AppRoutes.chatNew),
      isDark: isDark,
    );
  }

  Widget _buildEmptyState(bool isSearching) {
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

  Widget _buildErrorState() {
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
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_refresh_indicator.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/guest_gate_view.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_list_tile.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_search_bar.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';

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
  Timer? _debounceTimer;
  String _searchQuery = '';
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  List<ChatEntity> _filterAndSortChats(List<ChatEntity> chats) {
    var filtered = chats.where((chat) {
      if (_searchQuery.isEmpty) return true;
      return chat.otherName.toLowerCase().contains(_searchQuery);
    }).toList();

    if (_sortBy == 'name') {
      filtered.sort((a, b) => a.otherName.compareTo(b.otherName));
    } else {
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return filtered;
  }

  bool _canModifyOrderChat(ChatEntity chat) {
    if (chat.threadType == ChatThreadType.direct) return true;
    return chat.orderStatus == 'COMPLETED' || chat.orderStatus == 'CANCELLED';
  }

  Future<void> _archiveChat(ChatEntity chat) async {
    final usecase = ref.read(archiveChatUsecaseProvider);
    final result = await usecase(chat.id, chat.threadType, !chat.isArchived);
    result.fold((failure) => AppSnackbar.error(context, failure.message), (_) {
      ref.invalidate(chatsProvider);
      ref.invalidate(liveChatListProvider);
      ref.invalidate(archivedChatsProvider);
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
    final usecase = ref.read(deleteChatUsecaseProvider);
    final result = await usecase(chat.id, chat.threadType);
    result.fold((failure) => AppSnackbar.error(context, failure.message), (_) {
      ref.invalidate(chatsProvider);
      ref.invalidate(liveChatListProvider);
      ref.invalidate(archivedChatsProvider);
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Ações disponíveis apenas após o pedido ser concluído ou cancelado.',
                style: TextStyle(fontSize: 12, color: AppColors.mediumGray),
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
    final isGuest = user == null || user.isGuest;

    if (isGuest) {
      return Scaffold(
        body: GuestGateView(
          icon: Icons.chat_bubble_outline,
          title: 'MENSAGENS PRIVADAS',
          description:
              'Negocie produtos, tire dúvidas e converse em tempo real com compradores e vendedores com segurança.',
          benefits: const [
            'Chat em tempo real criptografado',
            'Envio e negociação de propostas diretas',
            'Notificações instantâneas de novas mensagens',
          ],
          onLoginPressed: () => context.push('/login'),
          onRegisterPressed: () => context.push('/register'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(text: 'MENSAGENS'),
          Expanded(
            child: Column(
              children: [
                _buildSearchBar(isDark),
                ref
                    .watch(liveChatListProvider)
                    .when(
                      data: (chats) {
                        final filteredChats = _filterAndSortChats(chats);
                        if (filteredChats.isEmpty) {
                          return _buildEmptyState(isDark, chats.isEmpty);
                        }
                        return Expanded(
                          child: AppRefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(chatsProvider);
                              ref.invalidate(liveChatListProvider);
                            },
                            child: ListView.builder(
                              itemCount: filteredChats.length,
                              itemBuilder: (context, index) {
                                final chat = filteredChats[index];
                                return ChatListTile(
                                  chat: chat,
                                  isDark: isDark,
                                  canSwipe: _canModifyOrderChat(chat),
                                  onTap: () {
                                    context.push(
                                      '/chat/${chat.id}',
                                      extra: {
                                        'orderName': chat.otherName,
                                        'orderAvatarUrl': chat.otherAvatarUrl,
                                        'chatType': chat.threadType.name,
                                      },
                                    );
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
                      error: (error, stack) => _buildErrorState(isDark),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return ChatSearchBar(
      controller: _searchController,
      onChanged: _onSearchChanged,
      hasQuery: _searchQuery.isNotEmpty,
      onClear: () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      },
      sortBy: _sortBy,
      onSortChanged: (value) => setState(() => _sortBy = value),
      onArchiveTap: () => context.push('/chat/archived'),
      onNewChatTap: () => context.push('/chat/new'),
      isDark: isDark,
    );
  }

  Widget _buildEmptyState(bool isDark, bool noData) {
    return Expanded(
      child: EmptyState(
        icon: noData ? Icons.chat_bubble_outline : Icons.search_off,
        title: noData ? 'SEM CONVERSAS' : 'NENHUM RESULTADO',
        subtitle: noData
            ? 'Crie uma conversa ou receba uma mensagem para visualizar aqui.'
            : 'Tente buscar por outro nome',
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            Spacing.vMd,
            Text(
              'Erro ao carregar conversas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
            ),
            Spacing.vSm,
            Text(
              'Não foi possível carregar suas conversas. Verifique sua conexão.',
              style: TextStyle(color: AppColors.mediumGray),
              textAlign: TextAlign.center,
            ),
            Spacing.vMd,
            AppButton(
              label: 'Tentar novamente',
              onPressed: () {
                ref.invalidate(chatsProvider);
                ref.invalidate(liveChatListProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

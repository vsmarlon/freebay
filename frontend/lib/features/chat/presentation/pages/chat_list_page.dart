import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/page_header.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage>
    with SingleTickerProviderStateMixin {
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
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
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (_) {
        ref.invalidate(liveChatListProvider);
        ref.invalidate(archivedChatsProvider);
        AppSnackbar.success(context,
            chat.isArchived ? 'Conversa restaurada' : 'Conversa arquivada');
      },
    );
  }

  void _confirmDelete(ChatEntity chat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conversa'),
        content: const Text(
            'Esta ação não pode ser desfeita. A conversa será ocultada para você.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteChat(chat);
            },
            child:
                const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(ChatEntity chat) async {
    final usecase = ref.read(deleteChatUsecaseProvider);
    final result = await usecase(chat.id, chat.threadType);
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (_) {
        ref.invalidate(liveChatListProvider);
        ref.invalidate(archivedChatsProvider);
        AppSnackbar.success(context, 'Conversa excluída');
      },
    );
  }

  void _showContextMenu(ChatEntity chat) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
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
              title: const Text('Excluir',
                  style: TextStyle(color: AppColors.error)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    final isGuest = user == null || user.isGuest;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(text: 'MENSAGENS'),
          Expanded(
            child: isGuest
                ? Column(
                    children: [
                      _buildSearchBar(isDark),
                      _buildEmptyState(isDark, true),
                    ],
                  )
                : Column(
                    children: [
                      _buildSearchBar(isDark),
                      ref.watch(liveChatListProvider).when(
                            data: (chats) {
                              final filteredChats = _filterAndSortChats(chats);
                              if (filteredChats.isEmpty) {
                                return _buildEmptyState(isDark, chats.isEmpty);
                              }
                              return Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () async {
                                    ref.invalidate(liveChatListProvider);
                                  },
                                  child: ListView.builder(
                                    itemCount: filteredChats.length,
                                    itemBuilder: (context, index) {
                                      final chat = filteredChats[index];
                                      return _buildChatItem(
                                          context, isDark, chat, index);
                                    },
                                  ),
                                ),
                              );
                            },
                            loading: () => Expanded(
                              child: ListView.builder(
                                itemCount: 5,
                                itemBuilder: (context, index) =>
                                    _buildLoadingChat(isDark),
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? AppColors.surfaceDark : AppColors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar conversas...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor:
                        isDark ? AppColors.backgroundDark : AppColors.lightGray,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              Spacing.hSm,
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/chat/archived'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderColor, width: 2),
                    ),
                    child: Icon(Icons.archive,
                        color: context.textPrimary, size: 20),
                  ),
                ),
              ),
              Spacing.hSm,
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/chat/new'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: AppColors.brutalistGradient,
                    ),
                    child: const Icon(Icons.edit,
                        color: AppColors.onPrimary, size: 20),
                  ),
                ),
              ),
            ],
          ),
          Spacing.vSm,
          Row(
            children: [
              _buildSortChip('Recentes', 'recent', isDark),
              Spacing.hSm,
              _buildSortChip('Nome', 'name', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, bool isDark) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : (isDark ? AppColors.backgroundDark : AppColors.lightGray),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? AppColors.onPrimary
                : (isDark ? AppColors.white : AppColors.darkGray),
          ),
        ),
      ),
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
            InkWell(
              onTap: () => ref.invalidate(liveChatListProvider),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration:
                    const BoxDecoration(gradient: AppColors.brutalistGradient),
                child: const Center(
                  child: Text(
                    'Tentar novamente',
                    style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingChat(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isDark
                ? AppColors.mediumGray.withAlpha(51)
                : AppColors.mediumGray.withAlpha(51),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              color: isDark
                  ? AppColors.mediumGray.withAlpha(51)
                  : AppColors.lightGray,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 100,
                    color: isDark
                        ? AppColors.mediumGray.withAlpha(51)
                        : AppColors.lightGray,
                  ),
                  Spacing.vSm,
                  Container(
                    height: 12,
                    width: 150,
                    color: isDark
                        ? AppColors.mediumGray.withAlpha(51)
                        : AppColors.lightGray,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(
      BuildContext context, bool isDark, ChatEntity chat, int index) {
    final canSwipe = _canModifyOrderChat(chat);

    Widget tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: chat.unread
                ? AppColors.primaryContainer
                : (isDark
                    ? AppColors.mediumGray.withAlpha(76)
                    : AppColors.mediumGray.withAlpha(102)),
            width: chat.unread ? 2 : 1,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  image: chat.otherAvatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(chat.otherAvatarUrl!),
                          fit: BoxFit.cover)
                      : null,
                  color: isDark
                      ? AppColors.mediumGray.withAlpha(51)
                      : AppColors.lightGray,
                ),
                child: chat.otherAvatarUrl == null
                    ? Icon(Icons.person,
                        color: isDark ? AppColors.white : AppColors.mediumGray)
                    : null,
              ),
              if (chat.unread)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      border: Border.all(
                          color:
                              isDark ? AppColors.surfaceDark : AppColors.white,
                          width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  chat.otherName,
                  style: TextStyle(
                    fontWeight: chat.unread ? FontWeight.bold : FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.darkGray,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                _formatTime(chat.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: chat.unread ? FontWeight.w600 : FontWeight.normal,
                  color: chat.unread
                      ? AppColors.primaryContainer
                      : AppColors.mediumGray,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              if (chat.threadType == ChatThreadType.order) ...[
                Text(
                  'PEDIDO \u2022 ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  chat.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: chat.unread
                        ? (isDark ? AppColors.white : AppColors.darkGray)
                        : AppColors.mediumGray,
                    fontWeight:
                        chat.unread ? FontWeight.w500 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          trailing: !canSwipe
              ? Tooltip(
                  message:
                      'Ações disponíveis apenas após o pedido ser concluído ou cancelado.',
                  child: Icon(Icons.lock_outline,
                      size: 16, color: AppColors.mediumGray),
                )
              : null,
          onTap: () {
            context.push('/chat/${chat.id}', extra: {
              'oderName': chat.otherName,
              'oderAvatarUrl': chat.otherAvatarUrl,
              'chatType': chat.threadType.name,
            });
          },
          onLongPress: () => _showContextMenu(chat),
        ),
      ),
    );

    if (canSwipe) {
      tile = Dismissible(
        key: ValueKey('chat_${chat.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: AppColors.primaryContainer,
          child:
              const Icon(Icons.archive, color: AppColors.onPrimary, size: 28),
        ),
        confirmDismiss: (direction) async {
          await _archiveChat(chat);
          return false;
        },
        child: tile,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: tile,
    );
  }
}

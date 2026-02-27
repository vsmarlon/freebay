import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'recent'; // 'recent' or 'name'

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'agora';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} min';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  List<ChatEntity> _filterAndSortChats(List<ChatEntity> chats) {
    var filtered = chats.where((chat) {
      if (_searchQuery.isEmpty) return true;
      return chat.oderName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (_sortBy == 'name') {
      filtered.sort((a, b) => a.oderName.compareTo(b.oderName));
    } else {
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    final isGuest = user == null || user.isGuest;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Mensagens',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
      ),
      body: isGuest
          ? Column(
              children: [
                _buildSearchBar(isDark),
                _buildEmptyState(isDark, true),
              ],
            )
          : Column(
              children: [
                _buildSearchBar(isDark),
                ref.watch(chatsProvider).when(
                      data: (chats) {
                        final filteredChats = _filterAndSortChats(chats);
                        if (filteredChats.isEmpty) {
                          return _buildEmptyState(isDark, chats.isEmpty);
                        }
                        return Expanded(
                          child: ListView.builder(
                            itemCount: filteredChats.length,
                            itemBuilder: (context, index) {
                              final chat = filteredChats[index];
                              return _buildChatItem(
                                  context, isDark, chat, index);
                            },
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
                      error: (error, stack) => _buildErrorState(isDark,
                          'Não foi possível carregar suas conversas. Verifique sua conexão.'),
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
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSortChip('Recentes', 'recent', isDark),
              const SizedBox(width: 8),
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
              ? (isDark
                  ? AppColors.primaryPurpleLight
                  : AppColors.primaryPurple)
              : (isDark ? AppColors.backgroundDark : AppColors.lightGray),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.white : AppColors.darkGray),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool noData) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noData ? Icons.chat_bubble_outline : Icons.search_off,
              size: 64,
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              noData ? 'Sem conversas' : 'Nenhum resultado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noData
                  ? 'Crie uma conversa ou receba uma mensagem para visualizar aqui.'
                  : 'Tente buscar por outro nome',
              style: TextStyle(
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar conversas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                  color: isDark ? AppColors.mediumGray : AppColors.mediumGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(chatsProvider),
              child: const Text('Tentar novamente'),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.mediumGray.withAlpha(51)
                : AppColors.mediumGray.withAlpha(51),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark
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
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.mediumGray.withAlpha(51)
                          : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 150,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.mediumGray.withAlpha(51)
                          : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: chat.unread
                  ? (isDark
                      ? AppColors.primaryPurpleLight
                      : AppColors.primaryPurple)
                  : (isDark
                      ? AppColors.mediumGray.withAlpha(76)
                      : AppColors.mediumGray.withAlpha(102)),
              width: chat.unread ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.black.withAlpha(51)
                    : AppColors.black.withAlpha(20),
                blurRadius: isDark ? 8 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: chat.oderAvatarUrl != null
                      ? NetworkImage(chat.oderAvatarUrl!)
                      : null,
                  backgroundColor: isDark
                      ? AppColors.mediumGray.withAlpha(51)
                      : AppColors.lightGray,
                  child: chat.oderAvatarUrl == null
                      ? Icon(Icons.person,
                          color:
                              isDark ? AppColors.white : AppColors.mediumGray)
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
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isDark ? AppColors.surfaceDark : AppColors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    chat.oderName,
                    style: TextStyle(
                      fontWeight:
                          chat.unread ? FontWeight.bold : FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  _formatTime(chat.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        chat.unread ? FontWeight.w600 : FontWeight.normal,
                    color: chat.unread
                        ? (isDark
                            ? AppColors.primaryPurpleLight
                            : AppColors.primaryPurple)
                        : (isDark
                            ? AppColors.mediumGray
                            : AppColors.mediumGray),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              chat.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chat.unread
                    ? (isDark ? AppColors.white : AppColors.darkGray)
                    : (isDark ? AppColors.mediumGray : AppColors.mediumGray),
                fontWeight: chat.unread ? FontWeight.w500 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}

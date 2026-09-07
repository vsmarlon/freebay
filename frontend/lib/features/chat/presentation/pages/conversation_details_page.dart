import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/widgets/media_grid.dart';

class ConversationDetailsPage extends ConsumerStatefulWidget {
  final String chatId;
  final String name;
  final String? avatarUrl;
  final List<MessageEntity> messages;

  const ConversationDetailsPage({
    super.key,
    required this.chatId,
    required this.name,
    this.avatarUrl,
    required this.messages,
  });

  @override
  ConsumerState<ConversationDetailsPage> createState() =>
      _ConversationDetailsPageState();
}

class _ConversationDetailsPageState
    extends ConsumerState<ConversationDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'DETALHES',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MediaGrid(
                  conversationId: widget.chatId,
                  initialMessages: widget.messages
                      .where((m) => m.type == 'IMAGE')
                      .toList(),
                  onLoadMore: (cursor) async {
                    final repo = ref.read(chatRepositoryProvider);
                    final res = await repo.getConversationMedia(
                      widget.chatId,
                      cursor: cursor,
                    );
                    return res.fold((l) => [], (r) => r.messages);
                  },
                ),
                ListView(padding: EdgeInsets.zero, children: [_buildActions()]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.mediumGray,
              border: Border.all(color: context.borderColor, width: 2),
              image: widget.avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.avatarUrl == null
                ? const Icon(Icons.person, size: 36, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            widget.name,
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        _buildActionTile(
          _isMuted ? Icons.volume_up : Icons.volume_off,
          _isMuted ? 'Ativar notificações' : 'Silenciar notificações',
          onTap: () {
            setState(() => _isMuted = !_isMuted);
            AppSnackbar.info(
              context,
              _isMuted ? 'Notificações silenciadas' : 'Notificações ativadas',
            );
          },
        ),
        _buildActionTile(
          Icons.color_lens,
          'Tema da conversa',
          onTap: _showThemeSheet,
        ),
        _buildActionTile(
          Icons.block,
          'Bloquear usuário',
          isDestructive: true,
          onTap: () async {
            showBrutalistSheet(
              context: context,
              title: 'BLOQUEAR USUÁRIO',
              builder: (ctx) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tem certeza que deseja bloquear ${widget.name}? Você não receberá mais mensagens deste usuário.',
                      style: TextStyle(color: context.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.block, color: AppColors.error),
                      title: const Text(
                        'Confirmar Bloqueio',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(chatRepositoryProvider)
                            .blockUser(widget.chatId);
                        if (mounted) {
                          AppSnackbar.success(context, 'Usuário bloqueado');
                          context.pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        _buildActionTile(
          Icons.delete_sweep,
          'Apagar conversa',
          isDestructive: true,
          onTap: () async {
            showBrutalistSheet(
              context: context,
              title: 'APAGAR CONVERSA',
              builder: (ctx) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Deseja apagar todas as mensagens desta conversa?',
                      style: TextStyle(color: context.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: AppColors.error,
                      ),
                      title: const Text(
                        'Confirmar e Apagar',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(chatRepositoryProvider)
                            .deleteChat(widget.chatId, ChatThreadType.direct);
                        ref.invalidate(chatsProvider);
                        if (mounted) {
                          AppSnackbar.info(context, 'Conversa apagada');
                          context.go('/chat');
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showThemeSheet() {
    showBrutalistSheet(
      context: context,
      title: 'TEMA DA CONVERSA',
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.circle,
                color: AppColors.primaryContainer,
              ),
              title: const Text('Padrão Magenta FreeBay'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(chatRepositoryProvider)
                    .setTheme(widget.chatId, ChatThreadType.direct, 'DEFAULT');
                if (mounted) AppSnackbar.success(context, 'Tema atualizado');
              },
            ),
            ListTile(
              leading: const Icon(Icons.circle, color: AppColors.info),
              title: const Text('Azul Oceano'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(chatRepositoryProvider)
                    .setTheme(widget.chatId, ChatThreadType.direct, 'OCEAN');
                if (mounted) AppSnackbar.success(context, 'Tema atualizado');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.borderColor)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : context.textPrimary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDestructive ? AppColors.error : context.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: context.textPrimary,
      unselectedLabelColor: context.textSecondary,
      indicatorColor: AppColors.primaryContainer,
      indicatorWeight: 3,
      labelStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      tabs: const [
        Tab(text: 'Mídia'),
        Tab(text: 'Ações'),
      ],
    );
  }
}

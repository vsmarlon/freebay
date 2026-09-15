import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/utils/date_utils.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/conversation_messages_provider.dart';
import 'package:freebay/features/chat/presentation/widgets/media_grid.dart';
import 'package:freebay/features/chat/presentation/widgets/link_preview_card.dart';
import 'package:freebay/core/router/app_routes.dart';

class ConversationDetailsPage extends ConsumerStatefulWidget {
  final String chatId;

  const ConversationDetailsPage({super.key, required this.chatId});

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
  String _mediaFilter = 'IMAGE';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
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
                  _buildMediaTab(),
                  _buildStarredTab(),
                  ListView(
                    padding: EdgeInsets.zero,
                    children: [_buildActions()],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ChatThreadType _threadType(ConversationMessagesState conv) =>
      conv.threadType == 'ORDER' ? ChatThreadType.order : ChatThreadType.direct;

  Widget _buildMediaTab() {
    final messages = ref
        .watch(conversationMessagesProvider(widget.chatId))
        .messages
        .where((message) {
          if (_mediaFilter == 'LINK') {
            final metadata = message.metadata;
            return message.type.toUpperCase() == 'TEXT' &&
                metadata != null &&
                (metadata['url'] is String || metadata['title'] is String);
          }
          return message.type.toUpperCase() == _mediaFilter;
        })
        .toList();
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final type in const ['IMAGE', 'GIF', 'VIDEO', 'LINK'])
              FilterChip(
                label: Text(type),
                selected: _mediaFilter == type,
                onSelected: (_) => setState(() => _mediaFilter = type),
              ),
          ],
        ),
        Expanded(
          child: _mediaFilter == 'LINK'
              ? ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final message in messages)
                      LinkPreviewCard(metadata: message.metadata),
                  ],
                )
              : MediaGrid(
                  conversationId: widget.chatId,
                  initialMessages: messages,
                  onLoadMore: (cursor) async {
                    final result = await ref
                        .read(chatRepositoryProvider)
                        .getConversationMedia(
                          widget.chatId,
                          type: _mediaFilter,
                          cursor: cursor,
                        );
                    return result.fold(
                      (_) => <MessageEntity>[],
                      (page) => page.messages,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final conv = ref.watch(conversationMessagesProvider(widget.chatId));
    final avatarUrl = conv.otherUserAvatarUrl;
    final name = conv.otherUserName;
    if (name == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: ShimmerBlock(width: 160, height: 24),
      );
    }
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
              color: context.textSecondary,
              border: Border.all(color: context.borderColor, width: 2),
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 36, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
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
                      'Tem certeza que deseja bloquear ${ref.read(conversationMessagesProvider(widget.chatId)).otherUserName}? Você não receberá mais mensagens deste usuário.',
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
                        final targetId = ref
                            .read(conversationMessagesProvider(widget.chatId))
                            .otherUserId;
                        if (targetId == null) return;
                        await ref
                            .read(chatRepositoryProvider)
                            .blockUser(targetId);
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
                        final conv = ref.read(
                          conversationMessagesProvider(widget.chatId),
                        );
                        await ref
                            .read(chatRepositoryProvider)
                            .deleteChat(widget.chatId, _threadType(conv));
                        ref.invalidate(chatsProvider);
                        if (mounted) {
                          AppSnackbar.info(context, 'Conversa apagada');
                          context.go(AppRoutes.chat);
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
                final conv = ref.read(
                  conversationMessagesProvider(widget.chatId),
                );
                await ref
                    .read(chatRepositoryProvider)
                    .setTheme(widget.chatId, _threadType(conv), 'DEFAULT');
                if (mounted) AppSnackbar.success(context, 'Tema atualizado');
              },
            ),
            ListTile(
              leading: const Icon(Icons.circle, color: AppColors.info),
              title: const Text('Azul Oceano'),
              onTap: () async {
                Navigator.pop(ctx);
                final conv = ref.read(
                  conversationMessagesProvider(widget.chatId),
                );
                await ref
                    .read(chatRepositoryProvider)
                    .setTheme(widget.chatId, _threadType(conv), 'OCEAN');
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

  Widget _buildStarredTab() {
    final conv = ref.watch(conversationMessagesProvider(widget.chatId));
    final starred = conv.messages
        .where((m) => conv.starredIds.contains(m.id))
        .toList();
    if (starred.isEmpty) {
      return const EmptyState(
        icon: Icons.star_outline,
        title: 'SEM FAVORITAS',
        subtitle: 'Segure uma mensagem e toque na estrela para favoritar.',
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: starred.length,
      itemBuilder: (context, index) {
        final message = starred[index];
        return InkWell(
          onTap: () {
            context.pop(message.id);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star,
                  size: 18,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.previewText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateUtilsCustom.formatShortDate(message.createdAt.toLocal())} ${formatMessageTime(message.createdAt)}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                BrutalistIconButton(
                  icon: Icons.star,
                  iconColor: AppColors.primaryContainer,
                  onTap: () => _unstar(message.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _unstar(String messageId) async {
    final result = await ref
        .read(chatRepositoryProvider)
        .toggleStar(widget.chatId, messageId);
    if (!mounted) return;
    result.fold((failure) => AppSnackbar.error(context, failure.message), (
      _,
    ) async {
      ref
          .read(conversationMessagesProvider(widget.chatId).notifier)
          .setStarred(messageId, false);
      await ref
          .read(conversationMessagesProvider(widget.chatId).notifier)
          .refresh();
    });
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
        Tab(text: 'Favoritas'),
        Tab(text: 'Ações'),
      ],
    );
  }
}

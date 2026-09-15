import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';

class ArchivedChatsPage extends ConsumerStatefulWidget {
  const ArchivedChatsPage({super.key});

  @override
  ConsumerState<ArchivedChatsPage> createState() => _ArchivedChatsPageState();
}

class _ArchivedChatsPageState extends ConsumerState<ArchivedChatsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(archivedChatListProvider.notifier).fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: 'ARQUIVADAS',
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: ref
                  .watch(archivedChatListProvider)
                  .when(
                    data: (chats) {
                      final loadingMore = ref.watch(
                        archivedChatListLoadingMoreProvider,
                      );
                      if (chats.isEmpty) {
                        return const EmptyState(
                          icon: Icons.archive_outlined,
                          title: 'NENHUMA CONVERSA ARQUIVADA',
                          subtitle:
                              'Arraste uma conversa para a esquerda para arquivar.',
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(archivedChatListProvider),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: chats.length + (loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == chats.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                child: ShimmerBlock(height: 72),
                              );
                            }
                            return _buildArchivedItem(
                              context,
                              isDark,
                              chats[index],
                              ref,
                            );
                          },
                        ),
                      );
                    },
                    loading: () => _buildLoadingChat(context),
                    error: (_, _) => const Center(
                      child: Text('Erro ao carregar conversas arquivadas'),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingChat(BuildContext context) {
    return SkeletonList(
      itemCount: 5,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              ShimmerBlock(width: 56, height: 56),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(height: 14, width: 100),
                  SizedBox(height: 6),
                  ShimmerBlock(height: 12, width: 150),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArchivedItem(
    BuildContext context,
    bool isDark,
    ChatEntity chat,
    WidgetRef ref,
  ) {
    final avatarUrl = chat.otherAvatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.bgColor,
          border: Border.all(
            color: isDark
                ? context.textSecondary.withAlpha(76)
                : context.textSecondary.withAlpha(102),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              image: hasAvatar
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: isDark
                  ? context.textSecondary.withAlpha(51)
                  : AppColors.lightGray,
            ),
            child: hasAvatar
                ? null
                : Icon(Icons.person, color: context.textPrimary),
          ),
          title: Text(
            chat.otherName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            chat.lastMessage ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          trailing: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final result = await ref
                    .read(chatRepositoryProvider)
                    .archiveChat(chat.id, chat.threadType, false);
                result.fold((_) {}, (_) {
                  ref.invalidate(archivedChatListProvider);
                  ref.invalidate(chatsProvider);
                  ref.invalidate(liveChatListProvider);
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.unarchive,
                  color: context.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
          onTap: () {
            context.push(AppRoutes.chatPath(chat.id));
          },
        ),
      ),
    );
  }
}

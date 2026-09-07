import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';

class ArchivedChatsPage extends ConsumerWidget {
  const ArchivedChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
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
                .watch(archivedChatsProvider)
                .when(
                  data: (chats) {
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
                          ref.invalidate(archivedChatsProvider),
                      child: ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) => _buildArchivedItem(
                          context,
                          isDark,
                          chats[index],
                          ref,
                        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.bgColor,
          border: Border.all(
            color: isDark
                ? AppColors.mediumGray.withAlpha(76)
                : AppColors.mediumGray.withAlpha(102),
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
              image: chat.otherAvatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(chat.otherAvatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: isDark
                  ? AppColors.mediumGray.withAlpha(51)
                  : AppColors.lightGray,
            ),
            child: chat.otherAvatarUrl == null
                ? Icon(Icons.person, color: context.textPrimary)
                : null,
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
            style: const TextStyle(color: AppColors.mediumGray, fontSize: 13),
          ),
          trailing: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref
                    .read(chatRepositoryProvider)
                    .archiveChat(chat.id, chat.threadType, false)
                    .then((_) {
                      ref.invalidate(archivedChatsProvider);
                      ref.invalidate(chatsProvider);
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
            context.push(
              '/chat/${chat.id}',
              extra: {
                'orderName': chat.otherName,
                'orderAvatarUrl': chat.otherAvatarUrl,
                'chatType': chat.threadType.name,
              },
            );
          },
        ),
      ),
    );
  }
}

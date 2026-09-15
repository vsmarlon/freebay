import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/profile/data/entities/follower_entity.dart';
import 'package:freebay/features/profile/data/entities/block_responses.dart';
import 'package:freebay/features/profile/presentation/pages/blocked_users_page.dart';
import 'package:freebay/features/profile/presentation/providers/follow_list_provider.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';

/// New-conversation picker. Every list comes from a provider — following via
/// [followingProvider], suggestions via [suggestionsProvider], blocked ids
/// via [blockedUsersProvider], search via [userSearchProvider]. The search
/// field and debounce timer are the only local state (hooks, no setState).
class NewChatPage extends HookConsumerWidget {
  final String? targetUserId;
  final String? productId;

  const NewChatPage({super.key, this.targetUserId, this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final draftController = useTextEditingController(
      text: targetUserId != null && productId != null
          ? 'Oi, ainda está disponível?'
          : null,
    );
    final clientMessageId = useRef<String?>(null);
    final attemptedDraft = useRef<String?>(null);
    final isSending = useState(false);
    useListenable(searchController);
    useListenable(draftController);
    useEffect(() {
      void onDraftChanged() {
        if (clientMessageId.value != null &&
            attemptedDraft.value != draftController.text) {
          clientMessageId.value = null;
          attemptedDraft.value = null;
        }
      }

      draftController.addListener(onDraftChanged);
      return () => draftController.removeListener(onDraftChanged);
    }, [draftController]);
    final debounce = useRef<Timer?>(null);
    useEffect(
      () =>
          () => debounce.value?.cancel(),
      const [],
    );

    final isProductContext = targetUserId != null && productId != null;
    final userId = ref.watch(authControllerProvider).value?.id;
    final followingAsync = isProductContext
        ? const AsyncValue<List<FollowerEntity>>.data([])
        : userId == null
        ? const AsyncValue<List<FollowerEntity>>.data([])
        : ref.watch(followingProvider(userId));
    final suggestions = isProductContext
        ? const SuggestionsState()
        : ref.watch(suggestionsProvider);
    final blockedAsync = isProductContext
        ? const AsyncValue<BlockListResponse>.data(
            BlockListResponse(limit: 0, offset: 0),
          )
        : ref.watch(blockedUsersProvider);
    final searchState = isProductContext
        ? const UserSearchState()
        : ref.watch(userSearchProvider);

    final blockedIds = blockedAsync.value?.users.map((u) => u.id).toSet() ?? {};
    List<UserSearchEntity> filterBlocked(List<UserSearchEntity> users) =>
        users.where((u) => !blockedIds.contains(u.id)).toList();

    final following = (followingAsync.value ?? [])
        .map(
          (f) => UserSearchEntity(
            id: f.id,
            displayName: f.displayName,
            avatarUrl: f.avatarUrl,
            isVerified: f.isVerified,
            bio: f.bio,
          ),
        )
        .toList();

    void onSearchChanged(String query) {
      debounce.value?.cancel();
      debounce.value = Timer(const Duration(milliseconds: 300), () {
        ref
            .read(userSearchProvider.notifier)
            .search(query: query, refresh: true);
      });
    }

    Future<void> startConversation(String targetId) async {
      final result = await ref
          .read(chatRepositoryProvider)
          .startDirectConversation(targetId);
      if (!context.mounted) return;
      final conversationId = result.rightOrNull;
      if (conversationId == null) {
        AppSnackbar.error(
          context,
          result.leftOrNull?.message ?? 'Erro ao iniciar conversa',
        );
        return;
      }
      await ref.read(liveChatListProvider.notifier).refreshRecent();
      ref.invalidate(chatsProvider);
      if (!context.mounted) return;
      context.push(AppRoutes.chatPath(conversationId));
    }

    Future<void> sendProductMessage() async {
      if (targetUserId == null || productId == null || isSending.value) return;
      final message = draftController.text.trim();
      if (message.isEmpty) return;

      isSending.value = true;
      clientMessageId.value ??=
          'new-chat-${DateTime.now().microsecondsSinceEpoch}';
      final messageClientId = clientMessageId.value;
      attemptedDraft.value = draftController.text;
      try {
        final conversationResult = await ref
            .read(chatRepositoryProvider)
            .startDirectConversation(targetUserId!, productId: productId);
        if (!context.mounted) return;
        await conversationResult.fold(
          (failure) async => AppSnackbar.error(context, failure.message),
          (conversationId) async {
            final messageResult = await ref
                .read(chatRepositoryProvider)
                .sendMessage(
                  conversationId,
                  message,
                  clientMessageId: messageClientId,
                );
            if (!context.mounted) return;
            final failure = messageResult.leftOrNull;
            if (failure != null) {
              AppSnackbar.error(context, failure.message);
              return;
            }
            await ref.read(liveChatListProvider.notifier).refreshRecent();
            ref.invalidate(chatsProvider);
            if (!context.mounted) return;
            context.push(AppRoutes.chatPath(conversationId));
          },
        );
      } finally {
        if (context.mounted) isSending.value = false;
      }
    }

    final isDark = context.isDark;
    final isSearching = searchController.text.isNotEmpty;

    if (targetUserId != null && productId != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Column(
            children: [
              PageHeader(
                text: 'FALAR SOBRE PRODUTO',
                leading: BrutalistIconButton(
                  icon: Icons.arrow_back,
                  onTap: () {
                    if (context.canPop()) context.pop();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mensagem para o vendedor',
                      style: TextStyle(color: context.textSecondary),
                    ),
                    Spacing.vSm,
                    AppTextField(controller: draftController, maxLines: 5),
                    Spacing.vMd,
                    AppButton(
                      label: 'ENVIAR MENSAGEM',
                      onPressed: draftController.text.trim().isEmpty
                          ? null
                          : sendProductMessage,
                      isLoading: isSending.value,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: 'NOVA CONVERSA',
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar usuários...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: isSearching
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  ref.read(userSearchProvider.notifier).clear();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.white,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                  Expanded(
                    child: isSearching
                        ? _buildSearchResults(
                            context,
                            filterBlocked(searchState.users),
                            searchState.isLoading,
                            startConversation,
                          )
                        : _buildFollowingAndSuggestions(
                            context,
                            filterBlocked(following),
                            followingAsync.isLoading,
                            filterBlocked(suggestions.users),
                            suggestions.isLoading,
                            startConversation,
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

  Widget _buildSearchResults(
    BuildContext context,
    List<UserSearchEntity> users,
    bool isLoading,
    Future<void> Function(String) startConversation,
  ) {
    if (users.isEmpty && !isLoading) {
      return const EmptyState(
        icon: Icons.person_search,
        title: 'NENHUM USUÁRIO',
        subtitle: 'Tente buscar por outro nome.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == users.length) return const ShimmerBlock(height: 72);
        final user = users[index];
        return _buildUserTile(context, user, () => startConversation(user.id));
      },
    );
  }

  Widget _buildFollowingAndSuggestions(
    BuildContext context,
    List<UserSearchEntity> following,
    bool isLoadingFollowing,
    List<UserSearchEntity> suggestions,
    bool isLoadingSuggestions,
    Future<void> Function(String) startConversation,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isLoadingFollowing || following.isNotEmpty) ...[
          _buildSectionTitle(context, 'Quem você segue'),
          if (isLoadingFollowing)
            const ShimmerBlock(width: 20, height: 20)
          else if (following.isEmpty)
            const EmptyState(
              icon: Icons.people_outline,
              title: 'NENHUM SEGUIDO',
              subtitle: 'Você ainda não segue ninguém.',
            )
          else
            for (final u in following)
              _buildUserTile(context, u, () => startConversation(u.id)),
          Spacing.vLg,
        ],
        if (isLoadingSuggestions || suggestions.isNotEmpty) ...[
          _buildSectionTitle(context, 'Sugestões'),
          if (isLoadingSuggestions)
            const ShimmerBlock(width: 20, height: 20)
          else if (suggestions.isEmpty)
            const EmptyState(
              icon: Icons.explore_outlined,
              title: 'NENHUMA SUGESTÃO',
              subtitle: 'No momento não há sugestões de usuários.',
            )
          else
            for (final u in suggestions)
              _buildUserTile(context, u, () => startConversation(u.id)),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: context.textPrimary,
        ),
      ),
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    UserSearchEntity user,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          image: user.avatarUrl != null
              ? DecorationImage(
                  image: NetworkImage(user.avatarUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: context.surfaceColor,
        ),
        child: user.avatarUrl == null
            ? Center(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'U',
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.isVerified) ...[
            Spacing.hXs,
            const Icon(
              Icons.verified,
              color: AppColors.primaryContainer,
              size: 16,
            ),
          ],
        ],
      ),
      subtitle: user.followersCount > 0
          ? Text(
              '${user.followersCount} seguidores',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            )
          : null,
      onTap: onTap,
    );
  }
}

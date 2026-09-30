import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/providers/close_friends_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/story_highlight_provider.dart';

class CloseFriendsPage extends ConsumerStatefulWidget {
  const CloseFriendsPage({super.key});

  @override
  ConsumerState<CloseFriendsPage> createState() => _CloseFriendsPageState();
}

class _CloseFriendsPageState extends ConsumerState<CloseFriendsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _selected = false;
  String? _busyId;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _reload();
    });
  }

  Future<void> _reload() async {
    final failure = await ref
        .read(closeFriendsProvider.notifier)
        .loadMore(
          refresh: true,
          search: _searchController.text.trim(),
          selected: _selected,
        );
    if (mounted && failure != null) AppSnackbar.error(context, failure.message);
  }

  Future<void> _toggle(CloseFriendCandidate candidate) async {
    if (_busyId != null) return;
    setState(() => _busyId = candidate.user.id);
    final result = await ref
        .read(profileRepositoryProvider)
        .setCloseFriend(candidate.user.id, add: !candidate.isCloseFriend);
    if (!mounted) return;
    setState(() => _busyId = null);
    result.fold((failure) => AppSnackbar.error(context, failure.message), (_) {
      ref.invalidate(storiesProvider);
      ref.invalidate(userStoriesProvider);
      ref.invalidate(storyHighlightsProvider);
      ref.invalidate(storyHighlightProvider);
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(closeFriendsProvider);
    final notifier = ref.read(closeFriendsProvider.notifier);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: 'AMIGOS PRÓXIMOS',
              breadcrumbs: context.breadcrumbs,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Só você pode ver sua lista. Ao remover alguém, o acesso a stories e destaques privados acaba imediatamente.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  Spacing.vMd,
                  AppTextField(
                    controller: _searchController,
                    hint: 'Buscar seguidores',
                    prefixIcon: Icons.search,
                    onChanged: _search,
                  ),
                  Spacing.vSm,
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'SEGUIDORES',
                          variant: _selected
                              ? AppButtonVariant.secondary
                              : AppButtonVariant.primary,
                          onPressed: () {
                            setState(() => _selected = false);
                            _reload();
                          },
                        ),
                      ),
                      Spacing.hSm,
                      Expanded(
                        child: AppButton(
                          label: 'NA LISTA',
                          variant: _selected
                              ? AppButtonVariant.primary
                              : AppButtonVariant.secondary,
                          onPressed: () {
                            setState(() => _selected = true);
                            _reload();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: users.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ShimmerBlock(height: 64),
                      Spacing.vSm,
                      ShimmerBlock(height: 64),
                      Spacing.vSm,
                      ShimmerBlock(height: 64),
                    ],
                  ),
                ),
                error: (error, _) => EmptyState.error(
                  message: 'Não foi possível carregar a lista.',
                  onRetry: _reload,
                ),
                data: (items) => items.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: _selected ? 'LISTA VAZIA' : 'NENHUM SEGUIDOR',
                        subtitle: _selected
                            ? 'Adicione seguidores para compartilhar stories reservados.'
                            : 'Tente outra busca ou aguarde novos seguidores.',
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          itemCount: items.length + (notifier.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == items.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: AppButton(
                                  label: 'CARREGAR MAIS',
                                  onPressed: () async {
                                    final failure = await notifier.loadMore();
                                    if (context.mounted && failure != null) {
                                      AppSnackbar.error(
                                        context,
                                        failure.message,
                                      );
                                    }
                                  },
                                ),
                              );
                            }
                            final candidate = items[index];
                            return UserListTile(
                              user: UserListTileItem(
                                id: candidate.user.id,
                                displayName: candidate.user.displayName,
                                username:
                                    candidate.user.username ??
                                    candidate.user.displayName,
                                avatarUrl: candidate.user.avatarUrl,
                              ),
                              trailing: AppButton(
                                label: candidate.isCloseFriend
                                    ? 'REMOVER'
                                    : 'ADICIONAR',
                                size: AppButtonSize.compact,
                                variant: candidate.isCloseFriend
                                    ? AppButtonVariant.secondary
                                    : AppButtonVariant.primary,
                                isLoading: _busyId == candidate.user.id,
                                onPressed: _busyId == null
                                    ? () => _toggle(candidate)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

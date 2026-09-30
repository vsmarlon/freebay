import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/providers/story_highlight_provider.dart';
import 'package:freebay/features/social/presentation/widgets/story_highlight_editor.dart';
import 'package:freebay/features/social/presentation/widgets/story_thumbnail.dart';

class StoryHighlightsSection extends HookConsumerWidget {
  const StoryHighlightsSection({
    super.key,
    required this.userId,
    required this.isOwnProfile,
  });

  final String userId;
  final bool isOwnProfile;

  void _openEditor(BuildContext context, StoryHighlightEntity? highlight) {
    showBrutalistSheet(
      context: context,
      title: highlight == null ? 'NOVO DESTAQUE' : 'EDITAR DESTAQUE',
      builder: (_) =>
          StoryHighlightEditor(userId: userId, highlight: highlight),
    );
  }

  void _manage(
    BuildContext context,
    WidgetRef ref,
    StoryHighlightEntity highlight,
    ValueNotifier<Set<String>> hiddenHighlights,
  ) {
    final repository = ref.read(socialRepositoryProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    showBrutalistSheet(
      context: context,
      title: highlight.title,
      builder: (sheetContext) => Column(
        children: [
          AppButton(
            label: 'EDITAR',
            onPressed: () {
              Navigator.of(sheetContext, rootNavigator: true).pop();
              _openEditor(context, highlight);
            },
            width: double.infinity,
          ),
          Spacing.vSm,
          AppButton(
            label: 'EXCLUIR DESTAQUE',
            variant: AppButtonVariant.danger,
            onPressed: () {
              Navigator.of(sheetContext, rootNavigator: true).pop();
              hiddenHighlights.value = {
                ...hiddenHighlights.value,
                highlight.id,
              };
              AppSnackbar.undoable(
                context,
                message: 'Destaque será excluído.',
                onUndo: () {
                  if (context.mounted) {
                    hiddenHighlights.value = {...hiddenHighlights.value}
                      ..remove(highlight.id);
                  }
                },
                onCommit: () async {
                  final result = await repository.deleteStoryHighlight(
                    highlight.id,
                  );
                  result.fold(
                    (failure) {
                      if (context.mounted) {
                        hiddenHighlights.value = {...hiddenHighlights.value}
                          ..remove(highlight.id);
                      }
                      AppSnackbar.errorOnMessenger(messenger, failure.message);
                    },
                    (_) =>
                        container.invalidate(storyHighlightsProvider(userId)),
                  );
                },
              );
            },
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlights = ref.watch(storyHighlightsProvider(userId));
    final hiddenHighlights = useState(<String>{});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESTAQUES',
          style: AppTypography.brutalistTag.copyWith(
            color: context.textSecondary,
          ),
        ),
        Spacing.vSm,
        SizedBox(
          height: 92,
          child: highlights.when(
            loading: () => const ShimmerBlock(height: 64, width: 64),
            error: (_, _) => AppButton(
              label: 'Tentar novamente',
              onPressed: () => ref.invalidate(storyHighlightsProvider(userId)),
            ),
            data: (items) => ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (isOwnProfile)
                  _tile(
                    context,
                    label: 'Novo',
                    onTap: () => _openEditor(context, null),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                for (final highlight in items.where(
                  (item) => !hiddenHighlights.value.contains(item.id),
                ))
                  _tile(
                    context,
                    label: highlight.title,
                    closeFriends: highlight.stories.any(
                      (story) => story.audience == StoryAudience.closeFriends,
                    ),
                    onTap: () => context.push(
                      AppRoutes.storyHighlightPath(highlight.id),
                    ),
                    onLongPress: isOwnProfile
                        ? () =>
                              _manage(context, ref, highlight, hiddenHighlights)
                        : null,
                    child: StoryThumbnail(
                      url: highlight.coverUrl,
                      mediaType: highlight.stories
                          .firstWhere(
                            (story) => story.id == highlight.coverStoryId,
                            orElse: () => highlight.stories.first,
                          )
                          .mediaType,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required String label,
    bool closeFriends = false,
    required Widget child,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: closeFriends ? AppColors.success : context.borderColor,
                  width: 2,
                ),
              ),
              child: child,
            ),
            Spacing.vXs,
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall,
            ),
          ],
        ),
      ),
    ),
  );
}

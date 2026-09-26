import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/providers/story_highlight_provider.dart';
import 'package:freebay/features/social/presentation/widgets/story_highlight_editor.dart';
import 'package:freebay/features/social/presentation/widgets/story_thumbnail.dart';

class StoryHighlightsSection extends ConsumerWidget {
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
  ) {
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
            onPressed: () async {
              final result = await ref
                  .read(socialRepositoryProvider)
                  .deleteStoryHighlight(highlight.id);
              if (!sheetContext.mounted) return;
              result.fold(
                (failure) => AppSnackbar.error(sheetContext, failure.message),
                (_) {
                  ref.invalidate(storyHighlightsProvider(userId));
                  Navigator.of(sheetContext, rootNavigator: true).pop();
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
                for (final highlight in items)
                  _tile(
                    context,
                    label: highlight.title,
                    onTap: () => context.push(
                      AppRoutes.storyHighlightPath(highlight.id),
                    ),
                    onLongPress: isOwnProfile
                        ? () => _manage(context, ref, highlight)
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
                border: Border.all(color: context.borderColor, width: 2),
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

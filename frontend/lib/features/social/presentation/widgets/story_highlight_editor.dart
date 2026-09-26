import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/providers/story_highlight_provider.dart';
import 'package:freebay/features/social/presentation/widgets/story_thumbnail.dart';

class StoryHighlightEditor extends HookConsumerWidget {
  const StoryHighlightEditor({super.key, required this.userId, this.highlight});

  final String userId;
  final StoryHighlightEntity? highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = useTextEditingController(text: highlight?.title);
    final selected = useState({
      for (final story in highlight?.stories ?? <StoryGroupItem>[]) story.id,
    });
    final coverId = useState<String?>(highlight?.coverStoryId);
    final saving = useState(false);
    final archive = ref.watch(storyArchiveProvider);

    void toggleStory(String id) {
      final next = {...selected.value};
      if (!next.add(id)) {
        next.remove(id);
      }
      selected.value = next;
      if (!next.contains(coverId.value)) {
        coverId.value = next.isEmpty ? null : next.first;
      }
    }

    Future<void> save(List<StoryEntity> stories) async {
      if (saving.value) return;
      final name = title.text.trim();
      final cover = coverId.value;
      if (name.isEmpty || cover == null || selected.value.isEmpty) {
        AppSnackbar.warning(context, 'Escolha um título, stories e uma capa.');
        return;
      }
      saving.value = true;
      final result = await ref
          .read(socialRepositoryProvider)
          .saveStoryHighlight(
            id: highlight?.id,
            title: name,
            storyIds: stories
                .where((story) => selected.value.contains(story.id))
                .map((story) => story.id)
                .toList(),
            coverStoryId: cover,
          );
      if (!context.mounted) return;
      saving.value = false;
      result.fold((failure) => AppSnackbar.error(context, failure.message), (
        id,
      ) {
        ref.invalidate(storyHighlightsProvider(userId));
        ref.invalidate(storyHighlightProvider(id));
        Navigator.of(context, rootNavigator: true).pop();
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: title,
          label: 'Título',
          hint: 'Ex.: Viagens',
          maxLength: 40,
        ),
        Spacing.vMd,
        const Text('SELECIONE OS STORIES', style: AppTypography.labelLarge),
        Spacing.vSm,
        archive.when(
          loading: () => const ShimmerBlock(height: 160),
          error: (_, _) => AppButton(
            label: 'Tentar novamente',
            onPressed: () => ref.invalidate(storyArchiveProvider),
          ),
          data: (stories) => stories.isEmpty
              ? const EmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: 'SEM STORIES',
                  subtitle: 'Crie um story para começar um destaque.',
                )
              : Column(
                  children: [
                    for (final story in stories)
                      Semantics(
                        label: 'Selecionar story ${story.id}',
                        child: InkWell(
                          onTap: () => toggleStory(story.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 58,
                                  height: 64,
                                  child: StoryThumbnail(
                                    url: story.imageUrl,
                                    mediaType: story.mediaType,
                                  ),
                                ),
                                Spacing.hSm,
                                BrutalistCheckbox(
                                  value: selected.value.contains(story.id),
                                  onChanged: (_) => toggleStory(story.id),
                                ),
                                Expanded(
                                  child: Text(
                                    story.caption?.isNotEmpty == true
                                        ? story.caption!
                                        : '${story.createdAt.day}/${story.createdAt.month}/${story.createdAt.year}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall,
                                  ),
                                ),
                                if (selected.value.contains(story.id))
                                  TextButton(
                                    onPressed: () => coverId.value = story.id,
                                    child: Text(
                                      coverId.value == story.id
                                          ? 'CAPA ✓'
                                          : 'Usar capa',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Spacing.vMd,
                    AppButton(
                      label: highlight == null
                          ? 'CRIAR DESTAQUE'
                          : 'SALVAR DESTAQUE',
                      isLoading: saving.value,
                      onPressed: saving.value ? null : () => save(stories),
                      width: double.infinity,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

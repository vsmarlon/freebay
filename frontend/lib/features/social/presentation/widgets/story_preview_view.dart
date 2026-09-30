import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/widgets/story_canvas.dart';
import 'package:video_player/video_player.dart';

class StoryPreviewView extends StatelessWidget {
  final String mediaPath;
  final VideoPlayerController? videoController;
  final List<StoryTextBlockEntity> textBlocks;
  final String? selectedTextId;
  final TextEditingController captionController;
  final bool isLoading;
  final StoryAudience audience;
  final ValueChanged<StoryAudience>? onAudienceChanged;
  final VoidCallback? onManageCloseFriends;
  final VoidCallback onClose;
  final VoidCallback onUpload;
  final void Function(List<StoryTextBlockEntity>) onBlocksChanged;
  final ValueChanged<String?> onSelected;
  final VoidCallback onAddText;
  final VoidCallback onRemoveText;
  final VoidCallback onCycleStyle;
  final VoidCallback onCycleColor;
  final VoidCallback onBringForward;

  const StoryPreviewView({
    super.key,
    required this.mediaPath,
    required this.videoController,
    required this.textBlocks,
    required this.selectedTextId,
    required this.captionController,
    required this.isLoading,
    this.audience = StoryAudience.everyone,
    this.onAudienceChanged,
    this.onManageCloseFriends,
    required this.onClose,
    required this.onUpload,
    required this.onBlocksChanged,
    required this.onSelected,
    required this.onAddText,
    required this.onRemoveText,
    required this.onCycleStyle,
    required this.onCycleColor,
    required this.onBringForward,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = [
      '.mp4',
      '.mov',
      '.webm',
    ].any(mediaPath.toLowerCase().endsWith);
    return Scaffold(
      backgroundColor: AppColors.onSurface,
      body: Stack(
        children: [
          Positioned.fill(
            child: StoryCanvas(
              editable: true,
              blocks: List.unmodifiable(textBlocks),
              selectedId: selectedTextId,
              onChanged: onBlocksChanged,
              onSelected: onSelected,
              background:
                  isVideo && videoController?.value.isInitialized == true
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: videoController!.value.size.width,
                        height: videoController!.value.size.height,
                        child: VideoPlayer(videoController!),
                      ),
                    )
                  : Image.file(File(mediaPath), fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.onPrimary,
                          size: 28,
                        ),
                        onPressed: onClose,
                      ),
                      if (isLoading)
                        const ShimmerBlock(width: 20, height: 20)
                      else
                        AppButton(label: 'PUBLICAR', onPressed: onUpload),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: captionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Adicionar legenda',
                            hintStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.black54,
                          ),
                        ),
                        Spacing.vMd,
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'PÚBLICO',
                                variant: audience == StoryAudience.everyone
                                    ? AppButtonVariant.primary
                                    : AppButtonVariant.secondary,
                                onPressed: () => onAudienceChanged?.call(
                                  StoryAudience.everyone,
                                ),
                              ),
                            ),
                            Spacing.hSm,
                            Expanded(
                              child: AppButton(
                                label: 'AMIGOS PRÓXIMOS',
                                variant: audience == StoryAudience.closeFriends
                                    ? AppButtonVariant.primary
                                    : AppButtonVariant.secondary,
                                onPressed: () => onAudienceChanged?.call(
                                  StoryAudience.closeFriends,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (audience == StoryAudience.closeFriends)
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Somente sua lista poderá ver esta história.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              AppButton(
                                label: 'EDITAR LISTA',
                                variant: AppButtonVariant.secondary,
                                onPressed: onManageCloseFriends,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AppButton(
                          label: 'ADICIONAR TEXTO',
                          onPressed: onAddText,
                        ),
                        const SizedBox(width: 8),
                        if (textBlocks.isNotEmpty) ...[
                          AppButton(label: 'APAGAR', onPressed: onRemoveText),
                          const SizedBox(width: 8),
                        ],
                        AppButton(label: 'ESTILO', onPressed: onCycleStyle),
                        const SizedBox(width: 8),
                        AppButton(label: 'COR', onPressed: onCycleColor),
                        const SizedBox(width: 8),
                        AppButton(label: 'CAMADA', onPressed: onBringForward),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

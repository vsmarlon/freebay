import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:uuid/uuid.dart';

import '../../domain/editor_models.dart';

/// Bottom sheet / dialogs para adicionar stickers (emoji, preço, vendido, local, link).
class StickerPicker {
  static void show({
    required BuildContext context,
    required ValueChanged<StickerLayer> onAddSticker,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _StickerSelectionSheet(
        onAddSticker: (layer) {
          Navigator.pop(ctx);
          onAddSticker(layer);
        },
      ),
    );
  }
}

class _StickerSelectionSheet extends StatefulWidget {
  const _StickerSelectionSheet({required this.onAddSticker});
  final ValueChanged<StickerLayer> onAddSticker;

  @override
  State<_StickerSelectionSheet> createState() => _StickerSelectionSheetState();
}

class _StickerSelectionSheetState extends State<_StickerSelectionSheet> {
  int _tabIndex = 0; // 0: Emojis, 1: Marketplace tags

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      height: 380 + bottomInset,
      color: context.surfaceHighColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: context.surfaceColor,
            child: Row(
              children: [
                _TabButton(
                  title: strings.mediaEditorEmojiTab,
                  isSelected: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  title: strings.mediaEditorMarketTab,
                  isSelected: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? EmojiPicker(
                    onEmojiSelected: (_, emoji) {
                      widget.onAddSticker(
                        StickerLayer(
                          id: const Uuid().v4(),
                          kind: StickerKind.emoji,
                          payload: emoji.emoji,
                        ),
                      );
                    },
                    config: const Config(
                      height: 300,
                      bottomActionBarConfig: BottomActionBarConfig(
                        enabled: false,
                      ),
                    ),
                  )
                : _MarketplaceStickersView(onAddSticker: widget.onAddSticker),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? context.textPrimary : Colors.transparent,
          border: Border.all(color: context.borderColor),
        ),
        child: Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: isSelected ? context.surfaceColor : context.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MarketplaceStickersView extends StatelessWidget {
  const _MarketplaceStickersView({required this.onAddSticker});
  final ValueChanged<StickerLayer> onAddSticker;

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          tileColor: context.surfaceColor,
          leading: const Icon(Icons.sell, color: Color(0xFF16A34A)),
          title: Text(
            strings.mediaEditorPriceStickerTitle,
            style: AppTypography.bodyMedium,
          ),
          subtitle: Text(
            strings.mediaEditorPriceExample,
            style: AppTypography.bodySmall,
          ),
          onTap: () async {
            final price = await _promptText(
              context,
              title: strings.mediaEditorPriceDialogTitle,
              hint: strings.mediaEditorPriceHint,
              initial: 'R\$ ',
            );
            if (price != null && price.trim().isNotEmpty) {
              onAddSticker(
                StickerLayer(
                  id: const Uuid().v4(),
                  kind: StickerKind.price,
                  payload: price.trim(),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          tileColor: context.surfaceColor,
          leading: const Icon(Icons.verified, color: Color(0xFFDC2626)),
          title: Text(
            strings.mediaEditorSoldStickerTitle,
            style: AppTypography.bodyMedium,
          ),
          subtitle: Text(
            strings.mediaEditorSoldSubtitle,
            style: AppTypography.bodySmall,
          ),
          onTap: () {
            onAddSticker(
              StickerLayer(
                id: const Uuid().v4(),
                kind: StickerKind.sold,
                payload: strings.mediaEditorSold,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          tileColor: context.surfaceColor,
          leading: const Icon(Icons.place, color: Colors.blueAccent),
          title: Text(
            strings.mediaEditorLocationTitle,
            style: AppTypography.bodyMedium,
          ),
          subtitle: Text(
            strings.mediaEditorLocationExample,
            style: AppTypography.bodySmall,
          ),
          onTap: () async {
            final location = await _promptText(
              context,
              title: strings.mediaEditorLocationTitle,
              hint: strings.mediaEditorLocationHint,
            );
            if (location != null && location.trim().isNotEmpty) {
              onAddSticker(
                StickerLayer(
                  id: const Uuid().v4(),
                  kind: StickerKind.location,
                  payload: location.trim(),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          tileColor: context.surfaceColor,
          leading: const Icon(Icons.link, color: Colors.purpleAccent),
          title: Text(
            strings.mediaEditorLinkTitle,
            style: AppTypography.bodyMedium,
          ),
          subtitle: Text(
            strings.mediaEditorLinkSubtitle,
            style: AppTypography.bodySmall,
          ),
          onTap: () async {
            final link = await _promptText(
              context,
              title: strings.mediaEditorLinkDialogTitle,
              hint: strings.mediaEditorLinkHint,
            );
            if (link != null && link.trim().isNotEmpty) {
              onAddSticker(
                StickerLayer(
                  id: const Uuid().v4(),
                  kind: StickerKind.link,
                  payload: link.trim(),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String hint,
    String initial = '',
  }) async {
    final strings = l10n(context);
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: const RoundedRectangleBorder(),
        title: Text(title, style: AppTypography.h3),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.commonCancel, style: AppTypography.button),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(strings.commonApply, style: AppTypography.button),
          ),
        ],
      ),
    );
  }
}

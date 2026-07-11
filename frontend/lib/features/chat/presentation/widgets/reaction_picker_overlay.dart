import 'package:flutter/material.dart';

const kReactionEmojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];

class ReactionPickerOverlay extends StatelessWidget {
  final void Function(String emoji) onSelect;

  const ReactionPickerOverlay({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: kReactionEmojis
            .map(
              (emoji) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onSelect(emoji);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

void showReactionPicker(BuildContext context, void Function(String) onSelect) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ReactionPickerOverlay(onSelect: onSelect),
  );
}

import 'package:flutter/material.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';

/// Theme swatch grid for the conversation customize sheet. Owns the
/// optimistic selection state; the parent persists via [onSelected].
class ChatThemePicker extends StatefulWidget {
  const ChatThemePicker({
    super.key,
    required this.initialApiValue,
    required this.onSelected,
  });

  final String initialApiValue;
  final ValueChanged<ChatTheme> onSelected;

  @override
  State<ChatThemePicker> createState() => _ChatThemePickerState();
}

class _ChatThemePickerState extends State<ChatThemePicker> {
  late String _currentTheme = widget.initialApiValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        children: ChatTheme.values.map((t) {
          final isSelected = t.apiValue == _currentTheme;
          return GestureDetector(
            onTap: () {
              setState(() => _currentTheme = t.apiValue);
              widget.onSelected(t);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(int.parse(t.accentHex.replaceFirst('#', '0xFF'))),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

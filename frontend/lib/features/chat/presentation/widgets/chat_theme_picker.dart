import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

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

  String _themeName(BuildContext context, ChatTheme theme) {
    final strings = l10n(context);
    return switch (theme) {
      ChatTheme.defaultTheme => strings.chatThemeDefault,
      ChatTheme.crimson => strings.chatThemeCrimson,
      ChatTheme.cobalt => strings.chatThemeCobalt,
      ChatTheme.forest => strings.chatThemeForest,
      ChatTheme.amber => strings.chatThemeAmber,
      ChatTheme.slate => strings.chatThemeSlate,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: ChatTheme.values.map((t) {
          final isSelected = t.apiValue == _currentTheme;
          final name = _themeName(context, t);
          return GestureDetector(
            onTap: () {
              setState(() => _currentTheme = t.apiValue);
              widget.onSelected(t);
            },
            child: Semantics(
              button: true,
              selected: isSelected,
              label: name,
              child: Tooltip(
                message: name,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(t.accentHex.replaceFirst('#', '0xFF')),
                        ),
                        border: Border.all(
                          color: isSelected
                              ? context.borderColor
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 68,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

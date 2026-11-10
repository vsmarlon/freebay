import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';

/// Inline @mention suggestions for social-owned composer fields.
class MentionSuggestions extends ConsumerStatefulWidget {
  const MentionSuggestions({
    super.key,
    required this.controller,
    this.focusNode,
    this.onSelected,
    this.allowBareQuery = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<UserSearchEntity>? onSelected;
  final bool allowBareQuery;

  @override
  ConsumerState<MentionSuggestions> createState() => _MentionSuggestionsState();
}

class _MentionSuggestionsState extends ConsumerState<MentionSuggestions> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.focusNode?.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant MentionSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_changed);
      widget.focusNode?.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.focusNode?.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final caret = value.selection.extentOffset;
    if ((widget.focusNode != null && !widget.focusNode!.hasFocus) ||
        !value.selection.isValid ||
        !value.selection.isCollapsed ||
        caret < 0 ||
        caret > value.text.length) {
      return const SizedBox.shrink();
    }
    final before = value.text.substring(0, caret);
    final match = RegExp(r'(^|\s)@([^\s@]*)$').firstMatch(before);
    final bareMatch = widget.allowBareQuery
        ? RegExp(r'(^|\s)([^\s@]+)$').firstMatch(before)
        : null;
    final tokenMatch = match ?? bareMatch;
    if (tokenMatch == null) return const SizedBox.shrink();
    final start = tokenMatch.start + tokenMatch.group(1)!.length;
    final query = tokenMatch.group(2)!;
    final users =
        ref.watch(quoteMentionCandidatesProvider(query)).asData?.value ??
        const <UserSearchEntity>[];
    if (users.isEmpty) return const SizedBox.shrink();
    return TextFieldTapRegion(
      child: Material(
        color: context.surfaceMidColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView(
            shrinkWrap: true,
            primary: false,
            padding: EdgeInsets.zero,
            children: [
              for (final user in users.take(5))
                ListTile(
                  dense: true,
                  leading: UserAvatar(imageUrl: user.avatarUrl),
                  title: Text(user.displayName),
                  subtitle: user.username == null
                      ? null
                      : Text('@${user.username}'),
                  onTap: () {
                    final username = user.username;
                    if (username == null || username.isEmpty) return;
                    final current = widget.controller.value;
                    final currentCaret = current.selection.extentOffset;
                    if (current.text != value.text ||
                        currentCaret != caret ||
                        !current.selection.isCollapsed) {
                      return;
                    }
                    final currentBefore = current.text.substring(
                      0,
                      currentCaret,
                    );
                    final currentMatch = RegExp(
                      r'(^|\s)@([^\s@]*)$',
                    ).firstMatch(currentBefore);
                    final currentBare = widget.allowBareQuery
                        ? RegExp(r'(^|\s)([^\s@]+)$').firstMatch(currentBefore)
                        : null;
                    final active = currentMatch ?? currentBare;
                    if (active == null ||
                        active.start + active.group(1)!.length != start ||
                        active.group(2) != query) {
                      return;
                    }
                    var end = caret;
                    while (end < current.text.length &&
                        RegExp(r'[A-Za-z0-9_.]').hasMatch(current.text[end])) {
                      end++;
                    }
                    final text = current.text.replaceRange(
                      start,
                      end,
                      '@$username ',
                    );
                    final selection = TextSelection.collapsed(
                      offset: start + username.length + 2,
                    );
                    widget.controller.value = TextEditingValue(
                      text: text,
                      selection: selection,
                    );
                    widget.focusNode?.requestFocus();
                    widget.onSelected?.call(user);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

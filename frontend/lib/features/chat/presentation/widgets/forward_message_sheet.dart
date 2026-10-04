import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';

class ForwardMessageSheet extends ConsumerStatefulWidget {
  final List<String> messageIds;
  final String? currentChatId;

  const ForwardMessageSheet({
    super.key,
    required this.messageIds,
    this.currentChatId,
  });

  @override
  ConsumerState<ForwardMessageSheet> createState() =>
      _ForwardMessageSheetState();
}

class _ForwardMessageSheetState extends ConsumerState<ForwardMessageSheet> {
  final _searchController = TextEditingController();
  final _selectedChatIds = <String>{};
  bool _isForwarding = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleForward() async {
    if (_selectedChatIds.isEmpty || _isForwarding) return;

    setState(() => _isForwarding = true);

    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.forwardMessages(
      messageIds: widget.messageIds,
      targetConversationIds: _selectedChatIds.toList(),
      sourceConversationId: widget.currentChatId,
    );

    if (!mounted) return;
    setState(() => _isForwarding = false);

    result.fold(
      (failure) {
        AppSnackbar.handleFailure(context, failure);
      },
      (messages) {
        Navigator.pop(context, true);
        AppSnackbar.success(
          context,
          l10n(context).chatForwardSuccessCount(widget.messageIds.length),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final chatsAsync = ref.watch(chatsProvider);
    final isDark = context.isDark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: strings.chatForwardSearchHint,
              hintStyle: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                color: context.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: context.textSecondary,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceContainerHighest,
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.primaryContainer,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),

        // Message count summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            strings.chatForwardSelectedCount(widget.messageIds.length),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ),

        // Conversation list
        Expanded(
          child: chatsAsync.when(
            data: (page) {
              final filtered = page.items.where((c) {
                if (_searchQuery.isEmpty) return true;
                return c.otherName.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: strings.chatNoConversation,
                    subtitle: strings.chatNoForwardResults,
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final chat = filtered[index];
                  final isSelected = _selectedChatIds.contains(chat.id);

                  return Material(
                    color: isSelected
                        ? (isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceContainerHighest)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedChatIds.remove(chat.id);
                          } else {
                            _selectedChatIds.add(chat.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryContainer
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            UserAvatar(
                              imageUrl: chat.otherAvatarUrl,
                              dimension: 40,
                            ),
                            const SizedBox(width: 12),
                            // Name & info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chat.otherName,
                                    style: TextStyle(
                                      fontFamily:
                                          AppTypography.headlineFontFamily,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  if (chat.lastMessage != null)
                                    Text(
                                      chat.lastMessage!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 12,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Checkbox
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryContainer
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryContainer
                                      : AppColors.outlineVariant,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: AppColors.onPrimary,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const ShimmerScope(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    ShimmerBlock(height: 56),
                    SizedBox(height: 8),
                    ShimmerBlock(height: 56),
                    SizedBox(height: 8),
                    ShimmerBlock(height: 56),
                  ],
                ),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                userMessageOf(e),
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ),

        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark
                : AppColors.surfaceContainerHighest,
            border: const Border(
              top: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          child: AppButton(
            label: strings.chatForward,
            onPressed: _selectedChatIds.isNotEmpty ? _handleForward : null,
            isLoading: _isForwarding,
          ),
        ),
      ],
    );
  }
}

/// Helper function to open the forward message sheet.
Future<bool?> showForwardMessageSheet({
  required BuildContext context,
  required List<String> messageIds,
  String? currentChatId,
}) {
  return showBrutalistSheet<bool>(
    context: context,
    title: l10n(context).chatForwardTitle,
    padding: EdgeInsets.zero,
    scrollable: false,
    builder: (_) => ForwardMessageSheet(
      messageIds: messageIds,
      currentChatId: currentChatId,
    ),
  );
}

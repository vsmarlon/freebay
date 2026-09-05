import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
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
        AppSnackbar.error(context, failure.message);
      },
      (messages) {
        Navigator.pop(context, true);
        AppSnackbar.success(
          context,
          '${widget.messageIds.length} mensagem${widget.messageIds.length == 1 ? '' : 'ns'} encaminhada${widget.messageIds.length == 1 ? '' : 's'} com sucesso!',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsProvider);
    final isDark = context.isDark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar conversa ou contato...',
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
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
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
              '${widget.messageIds.length} mensagem${widget.messageIds.length == 1 ? '' : 'ns'} selecionada${widget.messageIds.length == 1 ? '' : 's'}',
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
              data: (chats) {
                final filtered = chats.where((c) {
                  if (_searchQuery.isEmpty) return true;
                  return c.otherName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'NENHUMA CONVERSA',
                      subtitle: 'Nenhuma conversa encontrada para encaminhar.',
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
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.zero,
                                ),
                                child:
                                    chat.otherAvatarUrl != null &&
                                        chat.otherAvatarUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: chat.otherAvatarUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => const Icon(
                                          Icons.person,
                                          color: AppColors.onPrimary,
                                          size: 20,
                                        ),
                                        errorWidget: (_, _, _) => const Icon(
                                          Icons.person,
                                          color: AppColors.onPrimary,
                                          size: 20,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        color: AppColors.onPrimary,
                                        size: 20,
                                      ),
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
              loading: () => const Padding(
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
              error: (e, _) => Center(
                child: Text(
                  'Erro ao carregar conversas: $e',
                  style: TextStyle(
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
                top: BorderSide(color: AppColors.outlineVariant, width: 1),
              ),
            ),
            child: AppButton(
              label: _selectedChatIds.isEmpty
                  ? 'SELECIONE AO MENOS 1 CONVERSA'
                  : 'ENCAMINHAR (${_selectedChatIds.length})',
              onPressed: _selectedChatIds.isNotEmpty ? _handleForward : null,
              isLoading: _isForwarding,
              variant: AppButtonVariant.primary,
            ),
          ),
        ],
      ),
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
    title: 'ENCAMINHAR MENSAGEM',
    padding: EdgeInsets.zero,
    builder: (_) => ForwardMessageSheet(
      messageIds: messageIds,
      currentChatId: currentChatId,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_media_filter.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/conversation_messages_provider.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_theme_picker.dart';
import 'package:freebay/features/chat/presentation/widgets/conversation_details/conversation_details_sections.dart';
import 'package:freebay/features/profile/presentation/pages/blocked_users_page.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class ConversationDetailsPage extends ConsumerStatefulWidget {
  final String chatId;

  const ConversationDetailsPage({super.key, required this.chatId});

  @override
  ConsumerState<ConversationDetailsPage> createState() =>
      _ConversationDetailsPageState();
}

class _ConversationDetailsPageState
    extends ConsumerState<ConversationDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ConversationMediaFilter _mediaFilter = ConversationMediaFilter.image;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ChatThreadType _threadType(ConversationMessagesState conv) =>
      conv.threadType ?? ChatThreadType.direct;

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(conversationMessagesProvider(widget.chatId));
    final mediaMessages = conversation.messages.where((message) {
      if (message.viewOnce || message.deletedAt != null) return false;
      if (_mediaFilter == ConversationMediaFilter.link) {
        final metadata = message.metadata;
        return message.type == MessageType.text &&
            metadata != null &&
            conversationMetadataHasHttpUrl(metadata);
      }
      return message.type.wireValue == _mediaFilter.wireValue;
    }).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: l10n(context).chatDetailsTitle,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: l10n(context).accessibilityBack,
                onTap: () => context.pop(),
              ),
            ),
            ConversationDetailsHeader(
              name: conversation.otherUserName,
              avatarUrl: conversation.otherUserAvatarUrl,
            ),
            TabBar(
              controller: _tabController,
              labelColor: context.textPrimary,
              unselectedLabelColor: context.textSecondary,
              indicatorColor: AppColors.primaryContainer,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: l10n(context).chatMediaTab),
                Tab(text: l10n(context).chatFavoritesTab),
                Tab(text: l10n(context).chatActionsTab),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ConversationDetailsMediaTab(
                    conversationId: widget.chatId,
                    messages: mediaMessages,
                    filter: _mediaFilter,
                    onFilterChanged: (filter) =>
                        setState(() => _mediaFilter = filter),
                    onReply: (message) => context.pop(message),
                    onLoadMore: (cursor) async {
                      final result = await ref
                          .read(chatRepositoryProvider)
                          .getConversationMedia(
                            widget.chatId,
                            type: _mediaFilter,
                            cursor: cursor,
                          );
                      return result.fold(
                        (failure) => throw StateError(failure.message),
                        (page) => page,
                      );
                    },
                  ),
                  ConversationDetailsStarredTab(
                    messages: conversation.messages,
                    starredIds: conversation.starredIds,
                    onOpen: (id) => context.pop(id),
                    onUnstar: _unstar,
                  ),
                  ListView(
                    children: [
                      ConversationDetailsActionsTab(
                        isMuted: conversation.preference?.muted ?? false,
                        onToggleMute: _toggleMute,
                        onTheme: _showThemeSheet,
                        onReport: _reportConversation,
                        onBlock: _showBlockSheet,
                        onDelete: _showDeleteSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleMute() async {
    final conversation = ref.read(conversationMessagesProvider(widget.chatId));
    if (conversation.threadType == null) return;
    final muted = !(conversation.preference?.muted ?? false);
    final result = await ref
        .read(chatRepositoryProvider)
        .setMuted(widget.chatId, _threadType(conversation), muted);
    if (!mounted) return;
    result.fold((failure) => AppSnackbar.error(context, failure.message), (
      preference,
    ) {
      ref
          .read(conversationMessagesProvider(widget.chatId).notifier)
          .setPreference(preference);
      ref.invalidate(chatsProvider);
      ref.invalidate(liveChatListProvider);
      ref.invalidate(archivedChatListProvider);
      AppSnackbar.info(
        context,
        preference.muted
            ? l10n(context).chatNotificationsMuted
            : l10n(context).chatNotificationsEnabled,
      );
    });
  }

  void _showBlockSheet() {
    showBrutalistSheet(
      context: context,
      title: l10n(context).chatBlockTitle,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n(ctx).chatBlockConfirmation(
                ref
                        .read(conversationMessagesProvider(widget.chatId))
                        .otherUserName ??
                    l10n(ctx).commonUnknownUser,
              ),
              style: TextStyle(color: context.textPrimary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.error),
              title: Text(
                l10n(ctx).chatConfirmBlock,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final conversation = ref.read(
                  conversationMessagesProvider(widget.chatId),
                );
                final targetId = conversation.otherUserId;
                if (targetId == null) return;
                final result = await ref
                    .read(chatRepositoryProvider)
                    .blockUser(targetId);
                if (!mounted) return;
                result.fold(
                  (failure) => AppSnackbar.handleFailure(context, failure),
                  (_) {
                    ref.invalidate(chatsProvider);
                    ref.invalidate(liveChatListProvider);
                    ref.invalidate(archivedChatListProvider);
                    ref.invalidate(blockedUsersProvider);
                    AppSnackbar.success(context, l10n(context).chatUserBlocked);
                    context.pop();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSheet() {
    showBrutalistSheet(
      context: context,
      title: l10n(context).chatDeleteTitle,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n(ctx).chatDeleteAllMessagesConfirmation,
              style: TextStyle(color: context.textPrimary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: Text(
                l10n(ctx).chatConfirmDelete,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                final conv = ref.read(
                  conversationMessagesProvider(widget.chatId),
                );
                final repository = ref.read(chatRepositoryProvider);
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );
                final messenger = ScaffoldMessenger.of(context);
                final chatId = widget.chatId;
                final threadType = _threadType(conv);
                AppSnackbar.undoable(
                  context,
                  message: l10n(context).chatDeleteConversationUndo,
                  onUndo: () {
                    if (messenger.mounted) {
                      AppSnackbar.infoOnMessenger(
                        messenger,
                        l10n(messenger.context).chatDeleteCancelled,
                      );
                    }
                  },
                  onCommit: () async {
                    final result = await repository.deleteChat(
                      chatId,
                      threadType,
                    );
                    result.fold(
                      (failure) {
                        if (messenger.mounted) {
                          AppSnackbar.errorOnMessenger(
                            messenger,
                            localizedFailureMessage(messenger.context, failure),
                          );
                        }
                      },
                      (_) {
                        container.invalidate(chatsProvider);
                        container.invalidate(liveChatListProvider);
                        container.invalidate(archivedChatListProvider);
                        if (mounted) context.go(AppRoutes.chat);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSheet() {
    final conversation = ref.read(conversationMessagesProvider(widget.chatId));
    showBrutalistSheet(
      context: context,
      title: l10n(context).chatThemeTitle,
      builder: (_) => ChatThemePicker(
        initialApiValue: conversation.preference?.theme ?? 'DEFAULT',
        onSelected: (theme) async {
          final result = await ref
              .read(chatRepositoryProvider)
              .setTheme(
                widget.chatId,
                _threadType(conversation),
                theme.apiValue,
              );
          if (!mounted) return;
          result.fold(
            (failure) => AppSnackbar.handleFailure(context, failure),
            (preference) => ref
                .read(conversationMessagesProvider(widget.chatId).notifier)
                .setPreference(preference),
          );
        },
      ),
    );
  }

  Future<void> _reportConversation() async {
    final strings = l10n(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(strings.chatReport),
        children: [
          for (final (value, label) in [
            ('SPAM', strings.profileReportSpam),
            ('FRAUD', strings.profileReportFraud),
            ('HARASSMENT', strings.profileReportHarassment),
            ('FAKE_ACCOUNT', strings.profileReportFakeAccount),
            ('IMPERSONATING', strings.profileReportImpersonation),
            ('NUDITY', strings.profileReportNudity),
            ('BLACKMAIL', strings.profileReportBlackmail),
            ('FALSE_ADVERTISING', strings.profileReportFalseAdvertising),
            ('OTHER', strings.profileReportOther),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, value),
              child: Text(label),
            ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    final result = await ref
        .read(reportChatUsecaseProvider)
        .call(
          targetId: widget.chatId,
          targetType: 'CONVERSATION',
          reason: reason,
        );
    if (!mounted) return;
    result.fold(
      (failure) => AppSnackbar.handleFailure(context, failure),
      (_) => AppSnackbar.success(context, strings.profileReportSubmitted),
    );
  }

  Future<void> _unstar(String messageId) async {
    final result = await ref
        .read(chatRepositoryProvider)
        .toggleStar(widget.chatId, messageId);
    if (!mounted) return;
    result.fold((failure) => AppSnackbar.error(context, failure.message), (
      _,
    ) async {
      final notifier = ref.read(
        conversationMessagesProvider(widget.chatId).notifier,
      );
      notifier.setStarred(messageId, false);
      await notifier.refresh();
    });
  }
}

bool conversationMetadataHasHttpUrl(Map<String, dynamic>? metadata) {
  final url = metadata?['url'];
  if (url is! String || url.trim().isEmpty) return false;
  final uri = Uri.tryParse(url.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

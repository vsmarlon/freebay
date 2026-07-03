import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_header.dart';
import 'package:freebay/features/chat/presentation/widgets/message_bubble.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';

class ChatConversationPage extends ConsumerStatefulWidget {
  final String chatId;
  final String oderName;
  final String? oderAvatarUrl;
  final String chatType;

  const ChatConversationPage({
    super.key,
    required this.chatId,
    required this.oderName,
    this.oderAvatarUrl,
    this.chatType = 'order',
  });

  @override
  ConsumerState<ChatConversationPage> createState() =>
      _ChatConversationPageState();
}

class _ChatConversationPageState extends ConsumerState<ChatConversationPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  ConversationPreference? _preference;
  Color _accentColor = AppColors.primaryContainer;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    final socketService = ref.read(chatSocketServiceProvider);
    socketService.leaveConversation(widget.chatId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupSocketListener() {
    _socketSubscription?.cancel();
    final socketService = ref.read(chatSocketServiceProvider);
    socketService.joinConversation(widget.chatId);
    _socketSubscription = socketService.messageStream.listen((msg) {
      final msgConvId = msg['conversationId'] as String?;
      if (msgConvId != widget.chatId) return;
      if (!mounted) return;
      final alreadyExists = _messages.any((m) => m['id'] == msg['id']);
      if (alreadyExists) return;
      setState(() {
        _messages.add(msg);
      });
      _scrollToBottom();
    });
  }

  ChatThreadType get _threadType =>
      widget.chatType == 'order' ? ChatThreadType.order : ChatThreadType.direct;

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await HttpClient.instance.get(
        '/chat/conversations/${widget.chatId}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final prefData = data['preference'] as Map<String, dynamic>?;
        setState(() {
          _messages = (data['messages'] as List?) ?? [];
          _preference = prefData != null
              ? ConversationPreference.fromJson(prefData)
              : null;
          _accentColor = _computeAccentColor();
          _isLoading = false;
        });
        _scrollToBottom();
        _setupSocketListener();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.linear,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final socketService = ref.read(chatSocketServiceProvider);
      if (socketService.isConnected) {
        socketService.sendMessage(widget.chatId, content);
        _messageController.clear();
      } else {
        final result = await ref
            .read(chatRepositoryProvider)
            .sendMessage(widget.chatId, content);
        if (result.isLeft()) throw Exception('send failed');
        _messageController.clear();
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Erro ao enviar mensagem');
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _onThemeChanged(String theme) async {
    final usecase = ref.read(setChatThemeUsecaseProvider);
    final result = await usecase(widget.chatId, _threadType, theme);
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (pref) => setState(() {
        _preference = pref;
        _accentColor = _computeAccentColor();
      }),
    );
  }

  Future<void> _onBackgroundChanged() async {
    final xfile =
        await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    final base64 = base64Encode(bytes);
    final dataUri = 'data:image/jpeg;base64,$base64';

    final usecase = ref.read(setChatBackgroundUsecaseProvider);
    final result = await usecase(widget.chatId, _threadType, dataUri);
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (pref) => setState(() => _preference = pref),
    );
  }

  void _onRemoveBackground() async {
    final usecase = ref.read(setChatBackgroundUsecaseProvider);
    final result = await usecase(widget.chatId, _threadType, '');
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (pref) => setState(() => _preference = pref),
    );
  }

  void _showConfigSheet() {
    showBrutalistSheet(
      context: context,
      title: 'PERSONALIZAR',
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeSection(),
          Spacing.vMd,
          _buildBackgroundSection(),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    final currentTheme = _preference?.theme ?? 'DEFAULT';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COR DE DESTAQUE',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            )),
        Spacing.vSm,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ChatTheme.values.map((t) {
            final isSelected = t.apiValue == currentTheme;
            return GestureDetector(
              onTap: () => _onThemeChanged(t.apiValue),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      Color(int.parse(t.accentHex.replaceFirst('#', '0xFF'))),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : context.borderColor,
                    width: isSelected ? 3 : 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        color: AppColors.onPrimary, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBackgroundSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLANO DE FUNDO',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            )),
        Spacing.vSm,
        Row(
          children: [
            _buildBgButton(
              icon: Icons.image_outlined,
              label: 'ESCOLHER FOTO',
              onTap: _onBackgroundChanged,
            ),
            Spacing.hSm,
            if (_preference?.backgroundUrl != null &&
                _preference!.backgroundUrl!.isNotEmpty)
              _buildBgButton(
                icon: Icons.delete_outline,
                label: 'REMOVER',
                onTap: _onRemoveBackground,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBgButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: context.textPrimary),
              Spacing.hSm,
              Text(label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showThreeDotMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Personalizar'),
              onTap: () {
                Navigator.pop(ctx);
                _showConfigSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.error),
              title: const Text('Denunciar conversa',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _showReportDialog('CONVERSATION');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.error),
              title: const Text('Bloquear usuário',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _blockUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(
                  _preference?.isArchived == true ? 'Restaurar' : 'Arquivar'),
              onTap: () {
                Navigator.pop(ctx);
                _archiveChat();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _archiveChat() async {
    final usecase = ref.read(archiveChatUsecaseProvider);
    final isArchived = _preference?.isArchived ?? false;
    final result = await usecase(widget.chatId, _threadType, !isArchived);
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (_) {
        ref.invalidate(chatsProvider);
        AppSnackbar.success(
            context, isArchived ? 'Conversa restaurada' : 'Conversa arquivada');
        context.pop();
      },
    );
  }

  void _showReportDialog(String targetType) {
    final reasonController = TextEditingController();
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Denunciar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Motivo'),
              items: const [
                DropdownMenuItem(value: 'SPAM', child: Text('Spam')),
                DropdownMenuItem(value: 'HARASSMENT', child: Text('Assédio')),
                DropdownMenuItem(
                    value: 'INAPPROPRIATE', child: Text('Conteúdo impróprio')),
                DropdownMenuItem(value: 'OTHER', child: Text('Outro')),
              ],
              onChanged: (v) => selectedReason = v,
            ),
            if (selectedReason == 'OTHER')
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final reason = selectedReason == 'OTHER'
                  ? reasonController.text.trim()
                  : selectedReason ?? 'SPAM';
              if (reason.isEmpty) return;

              final usecase = ref.read(reportChatUsecaseProvider);
              final result = await usecase(
                targetId: widget.chatId,
                targetType: targetType,
                reason: reason,
                description: null,
              );
              result.fold(
                (failure) => AppSnackbar.error(ctx, failure.message),
                (_) {
                  Navigator.pop(ctx);
                  AppSnackbar.success(context, 'Denúncia enviada');
                },
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  String? _findOtherUserId() {
    final authState = ref.read(authControllerProvider);
    final currentUserId = authState.valueOrNull?.id;
    for (final msg in _messages) {
      final senderId = msg['senderId'] as String?;
      if (senderId != null && senderId != currentUserId) return senderId;
    }
    return null;
  }

  void _blockUser() async {
    final otherUserId = _findOtherUserId();
    if (otherUserId == null) {
      AppSnackbar.error(context, 'Não foi possível identificar o usuário');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bloquear usuário?'),
        content:
            const Text('Você não poderá mais receber mensagens deste usuário.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bloquear',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final usecase = ref.read(blockUserUsecaseProvider);
    final result = await usecase(otherUserId);
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (_) => AppSnackbar.success(context, 'Usuário bloqueado'),
    );
  }

  Color _computeAccentColor() {
    final themeName = _preference?.theme ?? 'DEFAULT';
    final match = ChatTheme.fromApiValue(themeName);
    return Color(int.parse(match.accentHex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState.valueOrNull?.id;
    final accentColor = _accentColor;
    final bgUrl = _preference?.backgroundUrl;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          ChatHeader(
            name: widget.oderName,
            avatarUrl: widget.oderAvatarUrl,
            chatType: widget.chatType,
            accentColor: accentColor,
            onBack: () => context.pop(),
            onConfig: _showThreeDotMenu,
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? _buildLoadingSkeleton()
                      : _messages.isEmpty
                          ? const EmptyState(
                              icon: Icons.chat_bubble_outline,
                              title: 'NENHUMA MENSAGEM',
                              subtitle:
                                  'Envie a primeira mensagem para iniciar a conversa.',
                            )
                          : Container(
                              decoration: bgUrl != null && bgUrl.isNotEmpty
                                  ? BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(bgUrl),
                                        fit: BoxFit.cover,
                                        opacity: 0.15,
                                      ),
                                    )
                                  : null,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                  final isMe = msg['senderId'] == currentUserId;
                                  final prevIsMe = index > 0
                                      ? _messages[index - 1]['senderId'] ==
                                          currentUserId
                                      : false;
                                  final isConsecutive = isMe == prevIsMe;
                                  return MessageBubble(
                                    content: msg['content'] ?? '',
                                    isMe: isMe,
                                    isDark: isDark,
                                    isConsecutive: isConsecutive,
                                    accentColor: accentColor,
                                    createdAt: msg['createdAt'] is String
                                        ? DateTime.parse(msg['createdAt'])
                                        : null,
                                    readAt: msg['readAt'],
                                    deliveredAt: msg['deliveredAt'],
                                  );
                                },
                              ),
                            ),
                ),
                _buildInputBar(isDark, accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SkeletonPage(
      child: Column(
        children: List.generate(6, (index) {
          final isLeft = index.isEven;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              mainAxisAlignment:
                  isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                ShimmerBlock(width: 200, height: 40),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInputBar(bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Digite uma mensagem...',
                filled: true,
                fillColor:
                    isDark ? AppColors.backgroundDark : AppColors.lightGray,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.outline),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          Spacing.hSm,
          BrutalistIconButton(
            icon: Icons.send,
            onTap: _sendMessage,
            size: 48,
            iconSize: 24,
            iconColor: AppColors.onPrimary,
            gradient: AppColors.brutalistGradient,
            isLoading: _isSending,
          ),
        ],
      ),
    );
  }
}

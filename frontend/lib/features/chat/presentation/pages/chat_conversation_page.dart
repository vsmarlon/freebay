import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/http_client.dart';

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
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await HttpClient.instance.get(
        '/chat/conversations/${widget.chatId}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        setState(() {
          _messages = (data['messages'] as List?) ?? [];
          _isLoading = false;
        });
        _markAsRead();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    return;
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await HttpClient.instance.post(
        '/chat/conversations/${widget.chatId}/messages',
        data: {'content': content},
      );

      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar mensagem')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState.valueOrNull?.id;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                image: widget.oderAvatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.oderAvatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: isDark ? AppColors.surfaceContainerDark : AppColors.lightGray,
              ),
              child: widget.oderAvatarUrl == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              widget.oderName,
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma mensagem ainda',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.mediumGray
                                : AppColors.mediumGray,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderId'] == currentUserId;
                          return _MessageBubble(
                            content: msg['content'] ?? '',
                            isMe: isMe,
                            isDark: isDark,
                          );
                        },
                      ),
          ),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
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
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: AppColors.brutalistGradient,
              ),
              child: Center(
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryPurple
              : (isDark ? AppColors.surfaceDark : AppColors.white),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isMe
                ? Colors.white
                : (isDark ? AppColors.white : AppColors.darkGray),
          ),
        ),
      ),
    );
  }
}

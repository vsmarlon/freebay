part of 'chat_conversation_page.dart';

mixin _ChatConversationLifecycle on ConsumerState<ChatConversationPage> {
  Timer? get _typingDebounceTimer;
  set _typingDebounceTimer(Timer? value);
  Map<String, GlobalKey> get _messageKeys;
  String? get _highlightedMessageId;
  set _highlightedMessageId(String? value);
  void _onTextChanged() {
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      final ws = ref.read(chatSocketServiceProvider);
      ws.sendTyping(widget.chatId);
    });
  }

  Future<void> _scrollToQuoted(String id) async {
    final ctx = _messageKeys[id]?.currentContext;
    if (ctx == null) return;
    setState(() => _highlightedMessageId = id);
    await Scrollable.ensureVisible(
      ctx,
      duration: AppMotion.enter,
      curve: AppMotion.enterCurve,
      alignment: 0.5,
    );
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _highlightedMessageId == id) {
        setState(() => _highlightedMessageId = null);
      }
    });
  }

  void _syncMessageKeys(List<MessageEntity> messages) {
    var changed = false;
    for (final m in messages) {
      if (!_messageKeys.containsKey(m.id)) {
        _messageKeys[m.id] = GlobalKey();
        changed = true;
      }
    }
    final ids = {for (final m in messages) m.id};
    final stale = _messageKeys.keys.where((id) => !ids.contains(id)).toList();
    for (final id in stale) {
      _messageKeys.remove(id);
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }
}

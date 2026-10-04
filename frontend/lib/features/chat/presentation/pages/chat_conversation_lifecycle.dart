part of 'chat_conversation_page.dart';

mixin _ChatConversationLifecycle on ConsumerState<ChatConversationPage> {
  Timer? get _typingDebounceTimer;
  set _typingDebounceTimer(Timer? value);
  Map<String, GlobalKey> get _messageKeys;
  String? get _highlightedMessageId;
  set _highlightedMessageId(String? value);
  ScrollController get _scrollController;
  int get _conversationGeneration;
  set _isQuoteNavigationActive(bool value);

  var _quoteNavigationRequest = 0;
  Timer? _quotedHighlightTimer;

  void _cancelQuotedScroll() {
    _quoteNavigationRequest++;
    _isQuoteNavigationActive = false;
    _quotedHighlightTimer?.cancel();
    _quotedHighlightTimer = null;
    if (_scrollController.hasClients &&
        _scrollController.position.hasContentDimensions) {
      _scrollController.jumpTo(_scrollController.position.pixels);
    }
  }

  void _onTextChanged() {
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      final ws = ref.read(chatSocketServiceProvider);
      ws.sendTyping(widget.chatId);
    });
  }

  Future<void> _scrollToQuoted(String id) async {
    final request = ++_quoteNavigationRequest;
    final generation = _conversationGeneration;
    _isQuoteNavigationActive = true;
    _quotedHighlightTimer?.cancel();
    _quotedHighlightTimer = null;
    if (_scrollController.hasClients &&
        _scrollController.position.hasContentDimensions) {
      _scrollController.jumpTo(_scrollController.position.pixels);
    }
    bool isCurrentRequest() =>
        mounted &&
        generation == _conversationGeneration &&
        request == _quoteNavigationRequest;

    try {
      if (!_messageKeys.containsKey(id)) return;
      var targetContext = _messageKeys[id]?.currentContext;
      if (targetContext == null) {
        if (!_scrollController.hasClients) return;
        final position = _scrollController.position;
        if (!position.hasContentDimensions) {
          await WidgetsBinding.instance.endOfFrame;
          if (!isCurrentRequest() || !_scrollController.hasClients) return;
        }
        if (!_scrollController.position.hasContentDimensions) return;

        // ponytail: scan by viewport-sized steps; O(viewports) is the safe
        // fallback for variable-height lazy rows without an indexed list.
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
        await WidgetsBinding.instance.endOfFrame;
        if (!isCurrentRequest() || !_scrollController.hasClients) return;
        targetContext = _messageKeys[id]?.currentContext;

        while (targetContext == null) {
          final currentPosition = _scrollController.position;
          if (currentPosition.pixels >= currentPosition.maxScrollExtent) break;
          final nextOffset =
              (currentPosition.pixels + currentPosition.viewportDimension * 0.8)
                  .clamp(
                    currentPosition.minScrollExtent,
                    currentPosition.maxScrollExtent,
                  )
                  .toDouble();
          if (nextOffset <= currentPosition.pixels) break;
          _scrollController.jumpTo(nextOffset);
          await WidgetsBinding.instance.endOfFrame;
          if (!isCurrentRequest() || !_scrollController.hasClients) return;
          targetContext = _messageKeys[id]?.currentContext;
        }
      }

      if (targetContext == null ||
          !targetContext.mounted ||
          !isCurrentRequest()) {
        return;
      }
      setState(() => _highlightedMessageId = id);
      await Scrollable.ensureVisible(
        targetContext,
        duration: AppMotion.enter,
        curve: AppMotion.enterCurve,
        alignment: 0.5,
      );
      if (!isCurrentRequest()) return;
      _quotedHighlightTimer = Timer(const Duration(milliseconds: 1500), () {
        _quotedHighlightTimer = null;
        if (mounted &&
            request == _quoteNavigationRequest &&
            _highlightedMessageId == id) {
          setState(() => _highlightedMessageId = null);
        }
      });
    } finally {
      if (request == _quoteNavigationRequest) {
        _isQuoteNavigationActive = false;
      }
    }
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

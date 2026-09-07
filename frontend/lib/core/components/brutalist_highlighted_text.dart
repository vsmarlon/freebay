import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class BrutalistHighlightedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color? linkColor;
  final Color? mentionColor;
  final Color? hashtagColor;
  final Color? highlightColor;
  final String? highlightQuery;
  final ValueChanged<String>? onLinkTap;
  final ValueChanged<String>? onMentionTap;
  final ValueChanged<String>? onHashtagTap;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  const BrutalistHighlightedText({
    super.key,
    required this.text,
    this.style,
    this.linkColor,
    this.mentionColor,
    this.hashtagColor,
    this.highlightColor,
    this.highlightQuery,
    this.onLinkTap,
    this.onMentionTap,
    this.onHashtagTap,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.textAlign = TextAlign.start,
  });

  @override
  State<BrutalistHighlightedText> createState() =>
      _BrutalistHighlightedTextState();
}

class _BrutalistHighlightedTextState extends State<BrutalistHighlightedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();

    final defaultStyle =
        widget.style ??
        TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          height: 1.4,
          color: context.textPrimary,
        );

    final effectiveLinkColor = widget.linkColor ?? (context.colors.primary);

    final effectiveMentionColor =
        widget.mentionColor ?? (context.colors.primary);

    final effectiveHashtagColor =
        widget.hashtagColor ?? (context.colors.primary);

    final effectiveHighlightColor =
        widget.highlightColor ??
        AppColors.primaryContainer.withValues(alpha: 0.35);

    final spans = _buildSpans(
      text: widget.text,
      baseStyle: defaultStyle,
      linkColor: effectiveLinkColor,
      mentionColor: effectiveMentionColor,
      hashtagColor: effectiveHashtagColor,
      highlightColor: effectiveHighlightColor,
      highlightQuery: widget.highlightQuery,
    );

    return RichText(
      text: TextSpan(children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }

  List<InlineSpan> _buildSpans({
    required String text,
    required TextStyle baseStyle,
    required Color linkColor,
    required Color mentionColor,
    required Color hashtagColor,
    required Color highlightColor,
    String? highlightQuery,
  }) {
    if (text.isEmpty) return const [];

    final pattern = RegExp(
      r'(https?:\/\/[^\s]+|www\.[^\s]+)|(@[a-zA-Z0-9_\.]+)|(#[a-zA-Z0-9_\u00C0-\u00FF]+)',
      caseSensitive: false,
    );

    final spans = <InlineSpan>[];
    var lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        final plain = text.substring(lastIndex, match.start);
        spans.addAll(
          _buildQueryHighlightedSpans(
            text: plain,
            baseStyle: baseStyle,
            highlightQuery: highlightQuery,
            highlightColor: highlightColor,
          ),
        );
      }

      final urlMatch = match.group(1);
      final mentionMatch = match.group(2);
      final hashtagMatch = match.group(3);

      if (urlMatch != null) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onLinkTap?.call(urlMatch);
        _recognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: urlMatch,
            style: baseStyle.copyWith(
              color: linkColor,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: linkColor.withValues(alpha: 0.6),
            ),
            recognizer: recognizer,
          ),
        );
      } else if (mentionMatch != null) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onMentionTap?.call(mentionMatch);
        _recognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: mentionMatch,
            style: baseStyle.copyWith(
              color: mentionColor,
              fontWeight: FontWeight.w700,
            ),
            recognizer: recognizer,
          ),
        );
      } else if (hashtagMatch != null) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onHashtagTap?.call(hashtagMatch);
        _recognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: hashtagMatch,
            style: baseStyle.copyWith(
              color: hashtagColor,
              fontWeight: FontWeight.w600,
            ),
            recognizer: recognizer,
          ),
        );
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex);
      spans.addAll(
        _buildQueryHighlightedSpans(
          text: remaining,
          baseStyle: baseStyle,
          highlightQuery: highlightQuery,
          highlightColor: highlightColor,
        ),
      );
    }

    return spans;
  }

  List<InlineSpan> _buildQueryHighlightedSpans({
    required String text,
    required TextStyle baseStyle,
    required Color highlightColor,
    String? highlightQuery,
  }) {
    if (highlightQuery == null || highlightQuery.trim().isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final query = highlightQuery.trim().toLowerCase();
    final lowerText = text.toLowerCase();
    final result = <InlineSpan>[];
    var startIndex = 0;

    while (true) {
      final index = lowerText.indexOf(query, startIndex);
      if (index == -1) {
        if (startIndex < text.length) {
          result.add(
            TextSpan(text: text.substring(startIndex), style: baseStyle),
          );
        }
        break;
      }

      if (index > startIndex) {
        result.add(
          TextSpan(text: text.substring(startIndex, index), style: baseStyle),
        );
      }

      final matchText = text.substring(index, index + query.length);
      result.add(
        TextSpan(
          text: matchText,
          style: baseStyle.copyWith(
            backgroundColor: highlightColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

      startIndex = index + query.length;
    }

    return result;
  }
}

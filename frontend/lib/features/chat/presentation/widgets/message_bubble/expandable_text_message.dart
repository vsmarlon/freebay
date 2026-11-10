import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';

class ExpandableTextMessage extends StatefulWidget {
  final String text;
  final bool isMe;

  const ExpandableTextMessage({
    super.key,
    required this.text,
    required this.isMe,
  });

  @override
  State<ExpandableTextMessage> createState() => _ExpandableTextMessageState();
}

class _ExpandableTextMessageState extends State<ExpandableTextMessage> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final shouldTruncate =
        widget.text.length > 300 || widget.text.split('\n').length > 12;
    final textColor = widget.isMe ? AppColors.onPrimary : context.textPrimary;
    final linkColor = widget.isMe
        ? AppColors.onPrimary
        : context.colors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BrutalistHighlightedText(
          text: widget.text,
          maxLines: (_isExpanded || !shouldTruncate) ? null : 12,
          overflow: (_isExpanded || !shouldTruncate)
              ? TextOverflow.clip
              : TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            color: textColor,
          ),
          linkColor: linkColor,
          mentionColor: linkColor,
          hashtagColor: linkColor,
          onLinkTap: (url) => showBrutalistSafeLinkDialog(context, url),
          onMentionTap: (mention) => context.push(
            AppRoutes.peopleSearchWith(mention.replaceFirst('@', '')),
          ),
          onHashtagTap: (tag) => context.push(AppRoutes.postSearchWith(tag)),
        ),
        if (shouldTruncate)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isExpanded ? 'Ver menos' : 'Ver mais',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

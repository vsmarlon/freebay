import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/brutalist_highlighted_text.dart';
import 'package:freebay/core/components/brutalist_safe_link_dialog.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class SocialPostContent extends StatelessWidget {
  final String? content;
  final bool compact;
  final Widget actions;

  const SocialPostContent({
    super.key,
    required this.content,
    required this.compact,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final text = content ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(compact ? 20 : 12),
          child: BrutalistHighlightedText(
            text: text,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textPrimary,
            ),
            maxLines: compact ? 12 : 3,
            overflow: TextOverflow.ellipsis,
            linkColor: compact ? AppColors.primaryContainer : null,
            mentionColor: compact ? AppColors.primaryContainer : null,
            hashtagColor: compact ? AppColors.primaryContainer : null,
            onLinkTap: (url) => showBrutalistSafeLinkDialog(context, url),
            onMentionTap: (mention) => context.push(
              AppRoutes.peopleSearchWith(mention.replaceFirst('@', '')),
            ),
            onHashtagTap: (tag) => context.push(AppRoutes.postSearchWith(tag)),
          ),
        ),
        actions,
      ],
    );
  }
}

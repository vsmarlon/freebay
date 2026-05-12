import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';

class CommentItem extends StatelessWidget {
  final CommentEntity comment;
  final bool isReplying;
  final bool isLiked;
  final int likesCount;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback? onUserTap;

  const CommentItem({
    super.key,
    required this.comment,
    required this.isReplying,
    required this.isLiked,
    required this.likesCount,
    required this.onReply,
    required this.onLike,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onUserTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.surfaceMidColor,
                image: comment.user?.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(comment.user!.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: comment.user?.avatarUrl == null
                  ? Icon(Icons.person, size: 16, color: context.textSecondary)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onUserTap,
                  child: Text(
                    comment.user?.displayName ?? 'Usuário',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: TextStyle(fontSize: 14, color: context.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mediumGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onReply,
                      child: const Text(
                        'Responder',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: isLiked ? Colors.red : AppColors.mediumGray,
                          ),
                          const SizedBox(width: 4),
                          if (likesCount > 0)
                            Text(
                              likesCount.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isLiked ? Colors.red : AppColors.mediumGray,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} d';
    if (diff.inHours > 0) return '${diff.inHours} h';
    if (diff.inMinutes > 0) return '${diff.inMinutes} m';
    return 'agora';
  }
}

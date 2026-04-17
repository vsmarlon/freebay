import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';

class UserSearchList extends StatelessWidget {
  final List<UserSearchEntity> users;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final Function(String userId)? onFollow;
  final Function(String userId)? onUnfollow;

  const UserSearchList({
    super.key,
    required this.users,
    this.isLoading = false,
    this.onLoadMore,
    this.onFollow,
    this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (users.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum usuário encontrado',
              style: TextStyle(
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            onLoadMore != null) {
          onLoadMore!();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == users.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final user = users[index];
          return _UserSearchItem(
            user: user,
            onFollow: onFollow,
            onUnfollow: onUnfollow,
          );
        },
      ),
    );
  }
}

class _UserSearchItem extends StatefulWidget {
  final UserSearchEntity user;
  final Function(String userId)? onFollow;
  final Function(String userId)? onUnfollow;

  const _UserSearchItem({
    required this.user,
    this.onFollow,
    this.onUnfollow,
  });

  @override
  State<_UserSearchItem> createState() => _UserSearchItemState();
}

class _UserSearchItemState extends State<_UserSearchItem> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push('/user/${widget.user.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                image: widget.user.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.user.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: isDark ? AppColors.surfaceDark : AppColors.lightGray,
              ),
              child: widget.user.avatarUrl == null
                  ? Center(
                      child: Text(
                        widget.user.displayName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.user.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? AppColors.white : AppColors.darkGray,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppColors.primaryPurple,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
                    Text(
                      widget.user.bio!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.mediumGray
                            : AppColors.mediumGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.user.followersCount} seguidores',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppColors.mediumGray : AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _isLoading
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _isFollowing
                    ? InkWell(
                        onTap: () async {
                          setState(() => _isLoading = true);
                          await widget.onUnfollow?.call(widget.user.id);
                          setState(() {
                            _isFollowing = false;
                            _isLoading = false;
                          });
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primaryPurple),
                          ),
                          child: const Center(
                            child: Text(
                              'Seguindo',
                              style: TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: () async {
                          setState(() => _isLoading = true);
                          await widget.onFollow?.call(widget.user.id);
                          setState(() {
                            _isFollowing = true;
                            _isLoading = false;
                          });
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: const BoxDecoration(
                            gradient: AppColors.brutalistGradient,
                          ),
                          child: const Center(
                            child: Text(
                              'Seguir',
                              style: TextStyle(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}

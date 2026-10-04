import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'new_chat_user_tile.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class NewChatUserResults extends StatelessWidget {
  final bool isSearching;
  final List<UserSearchEntity> searchUsers;
  final bool isLoadingSearch;
  final List<UserSearchEntity> following;
  final bool isLoadingFollowing;
  final List<UserSearchEntity> suggestions;
  final bool isLoadingSuggestions;
  final Future<void> Function(String userId) onStartConversation;

  const NewChatUserResults({
    super.key,
    required this.isSearching,
    required this.searchUsers,
    required this.isLoadingSearch,
    required this.following,
    required this.isLoadingFollowing,
    required this.suggestions,
    required this.isLoadingSuggestions,
    required this.onStartConversation,
  });

  @override
  Widget build(BuildContext context) {
    return isSearching ? _buildSearch(context) : _buildSuggestions(context);
  }

  Widget _buildSearch(BuildContext context) {
    final strings = l10n(context);
    if (searchUsers.isEmpty && !isLoadingSearch) {
      return EmptyState(
        icon: Icons.person_search,
        title: strings.chatNoUsers,
        subtitle: strings.chatTryAnotherName,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchUsers.length + (isLoadingSearch ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == searchUsers.length) {
          return const ShimmerScope(child: ShimmerBlock(height: 72));
        }
        final user = searchUsers[index];
        return NewChatUserTile(
          user: user,
          onTap: () => onStartConversation(user.id),
        );
      },
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final strings = l10n(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(
          context,
          title: strings.chatFollowedPeople,
          users: following,
          isLoading: isLoadingFollowing,
          emptyIcon: Icons.people_outline,
          emptyTitle: strings.chatFollowNobodyTitle,
          emptySubtitle: strings.chatFollowNobody,
        ),
        if (isLoadingFollowing || following.isNotEmpty) Spacing.vLg,
        _buildSection(
          context,
          title: strings.chatSuggestions,
          users: suggestions,
          isLoading: isLoadingSuggestions,
          emptyIcon: Icons.explore_outlined,
          emptyTitle: strings.chatNoSuggestionsTitle,
          emptySubtitle: strings.chatNoSuggestions,
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<UserSearchEntity> users,
    required bool isLoading,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (!isLoading && users.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
        ),
        if (isLoading)
          const ShimmerScope(child: ShimmerBlock(width: 20, height: 20))
        else if (users.isEmpty)
          EmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
          )
        else
          for (final user in users)
            NewChatUserTile(
              user: user,
              onTap: () => onStartConversation(user.id),
            ),
      ],
    );
  }
}

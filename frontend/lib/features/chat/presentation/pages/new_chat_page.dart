import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/shared/services/http_client.dart';

class NewChatPage extends ConsumerStatefulWidget {
  const NewChatPage({super.key});

  @override
  ConsumerState<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends ConsumerState<NewChatPage> {
  final _searchController = TextEditingController();
  List<UserSearchEntity> _followers = [];
  List<UserSearchEntity> _suggestions = [];
  bool _isLoadingFollowers = true;
  bool _isLoadingSuggestions = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadFollowers(),
      _loadSuggestions(),
    ]);
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoadingFollowers = true);
    try {
      final authState = ref.read(authControllerProvider);
      final userId = authState.valueOrNull?.id;
      if (userId == null) return;

      final response =
          await HttpClient.instance.get('/users/$userId/followers');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final users = (data['users'] as List?)
                ?.map((json) =>
                    UserSearchEntity.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];
        setState(() {
          _followers = users;
          _isLoadingFollowers = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingFollowers = false);
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoadingSuggestions = true);
    try {
      final response = await HttpClient.instance.get('/users/suggestions');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final users = (data['users'] as List?)
                ?.map((json) =>
                    UserSearchEntity.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];
        setState(() {
          _suggestions = users;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingSuggestions = false);
    }
  }

  void _onSearchDebounced(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(userSearchProvider.notifier).search(query: query, refresh: true);
    });
  }

  Future<void> _startConversation(
      String userId, String userName, String? avatarUrl) async {
    try {
      final response = await HttpClient.instance.post(
        '/chat/conversations',
        data: {'targetUserId': userId},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final conversationId = data['conversationId'] as String;

        if (mounted) {
          context.push(
            '/chat/$conversationId',
            extra: {
              'oderName': userName,
              'oderAvatarUrl': avatarUrl,
              'chatType': 'direct',
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao iniciar conversa')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final searchState = ref.watch(userSearchProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          'Nova Conversa',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.appBarColor,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuários...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(userSearchProvider.notifier).clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.white,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchDebounced,
            ),
          ),
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults(searchState, isDark)
                : _buildFollowersAndSuggestions(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(UserSearchState state, bool isDark) {
    if (state.users.isEmpty && !state.isLoading) {
      return Center(
        child: Text(
          'Nenhum usuário encontrado',
          style: TextStyle(
            color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.users.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.users.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = state.users[index];
        return _UserListTile(
          user: user,
          isDark: isDark,
          onTap: () =>
              _startConversation(user.id, user.displayName, user.avatarUrl),
        );
      },
    );
  }

  Widget _buildFollowersAndSuggestions(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_isLoadingFollowers || _followers.isNotEmpty) ...[
          _SectionHeader(title: 'Seus Seguidores', isDark: isDark),
          if (_isLoadingFollowers)
            const Center(child: CircularProgressIndicator())
          else if (_followers.isEmpty)
            Text(
              'Nenhum follower ainda',
              style: TextStyle(
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
            )
          else
            ..._followers.map((user) => _UserListTile(
                  user: user,
                  isDark: isDark,
                  onTap: () => _startConversation(
                      user.id, user.displayName, user.avatarUrl),
                )),
          const SizedBox(height: 24),
        ],
        if (_isLoadingSuggestions || _suggestions.isNotEmpty) ...[
          _SectionHeader(title: 'Sugestões', isDark: isDark),
          if (_isLoadingSuggestions)
            const Center(child: CircularProgressIndicator())
          else if (_suggestions.isEmpty)
            Text(
              'Nenhuma sugestão',
              style: TextStyle(
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
            )
          else
            ..._suggestions.map((user) => _UserListTile(
                  user: user,
                  isDark: isDark,
                  onTap: () => _startConversation(
                      user.id, user.displayName, user.avatarUrl),
                )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.white : AppColors.darkGray,
        ),
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final UserSearchEntity user;
  final bool isDark;
  final VoidCallback onTap;

  const _UserListTile({
    required this.user,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          image: user.avatarUrl != null
              ? DecorationImage(
                  image: NetworkImage(user.avatarUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: isDark ? AppColors.surfaceContainerDark : AppColors.lightGray,
        ),
        child: user.avatarUrl == null
            ? Center(child: Text(user.displayName[0].toUpperCase()))
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.verified,
              color: AppColors.primaryPurple,
              size: 16,
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${user.followersCount} seguidores',
        style: TextStyle(
          color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }
}

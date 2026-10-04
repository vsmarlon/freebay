import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';

class SavedPostsPage extends ConsumerStatefulWidget {
  const SavedPostsPage({super.key});

  @override
  ConsumerState<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends ConsumerState<SavedPostsPage> {
  final _posts = <PostEntity>[];
  String? _cursor;
  bool _loading = true;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  Future<void> _load({required bool refresh}) async {
    if (!refresh && (_loading || !_hasMore)) return;
    final requestCursor = refresh ? null : _cursor;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(socialRepositoryProvider)
        .getSavedPosts(cursor: requestCursor);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (page) => setState(() {
        if (refresh) {
          _posts
            ..clear()
            ..addAll(page.items);
        } else {
          final ids = _posts.map((post) => post.id).toSet();
          _posts.addAll(page.items.where((post) => ids.add(post.id)));
        }
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: l10n(context).profileSavedPostsTitle,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: l10n(context).accessibilityBack,
                onTap: context.pop,
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final strings = l10n(context);
    final saves = ref.watch(savesProvider);
    final visiblePosts = _posts
        .where((post) => saves.getSavedOverride(post.id) ?? true)
        .toList();
    if (_loading && _posts.isEmpty) {
      return const Center(
        child: ShimmerScope(child: ShimmerBlock(height: 180)),
      );
    }
    if (_error != null && _posts.isEmpty) {
      return EmptyState.error(
        message: strings.errorUnknown,
        onRetry: () => _load(refresh: true),
      );
    }
    if (visiblePosts.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_outline,
        title: strings.profileNoSavedPosts,
        subtitle: strings.profileSavedPostsEmpty,
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visiblePosts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == visiblePosts.length) {
            Future.microtask(() => _load(refresh: false));
            return const ShimmerScope(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerBlock(height: 120),
              ),
            );
          }
          final post = visiblePosts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FeedPostItem(
              post: post,
              onUnsaved: () => setState(
                () => _posts.removeWhere((item) => item.id == post.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

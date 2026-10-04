import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/reposts_provider.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';

export 'presentation/providers/likes_provider.dart' show likesProvider;
export 'presentation/providers/reposts_provider.dart' show repostsProvider;
export 'presentation/providers/saves_provider.dart' show savesProvider;
export 'presentation/widgets/feed_post_item.dart' show FeedPostItem;

void reconcileSocialPosts(Ref ref, Iterable<PostEntity> posts) {
  ref.read(likesProvider.notifier).reconcilePosts(posts);
  ref.read(savesProvider.notifier).reconcilePosts(posts);
  ref.read(repostsProvider.notifier).reconcilePosts(posts);
}

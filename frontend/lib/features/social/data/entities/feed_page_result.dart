import 'package:freebay/features/social/data/entities/post_entity.dart';

class FeedPageResult {
  final List<PostEntity> posts;
  final bool hasMore;
  final String? nextCursor;
  final int? nextOffset;

  const FeedPageResult({
    required this.posts,
    required this.hasMore,
    this.nextCursor,
    this.nextOffset,
  });
}

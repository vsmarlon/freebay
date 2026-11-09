import 'package:freebay/core/components/social_post/post_media.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';

extension PostEntitySocialMedia on PostEntity {
  List<SocialPostMediaItem> get socialMedia => [
    for (final item in orderedMedia)
      SocialPostMediaItem(
        url: item.url,
        thumbnailUrl: item.thumbnailUrl,
        isVideo: item.type == PostMediaType.video,
        blurHash: item.blurHash,
      ),
  ];
}

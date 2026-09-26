import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/entities/feed_page_result.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/data/entities/user_post_entry.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/data/entities/user_search_page_result.dart';
import 'package:freebay/features/social/data/entities/social_filters.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/services/image_upload_service.dart';

part 'social_repository_parts/social_repository_stories.dart';
part 'social_repository_parts/social_repository_discovery.dart';
part 'social_repository_parts/social_repository_feed.dart';
part 'social_repository_parts/social_repository_saves.dart';

Map<String, dynamic>? _jsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _jsonMaps(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

class PostMutationState {
  final bool active;
  final int count;
  const PostMutationState({required this.active, required this.count});
}

class SaveMutationState {
  final bool active;
  const SaveMutationState({required this.active});
}

class SocialRepository
    with
        SocialRepositoryStories,
        SocialRepositoryDiscovery,
        SocialRepositoryFeed,
        SocialRepositorySaves {
  @override
  final Dio client;

  SocialRepository({Dio? client}) : client = client ?? HttpClient.instance;

  @override
  Future<Either<Failure, T>> stateMutation<T>(
    String path,
    T Function(Map<String, dynamic> data) fromData, {
    bool patch = false,
  }) {
    T mapMutation(dynamic data) {
      final map = _jsonMap(data);
      if (map == null) throw const FormatException('Invalid mutation payload');
      return fromData(map);
    }

    return requestEither(
      () => patch ? client.patch(path) : client.post(path),
      decoder: (response) {
        final data = response.data['data'];
        return Right(mapMutation(data));
      },
    );
  }
}

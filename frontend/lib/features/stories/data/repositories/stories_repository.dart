import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';

Map<String, dynamic>? _storyJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _storyJsonMaps(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

class StoriesRepository {
  final Dio client;

  StoriesRepository({Dio? client}) : client = client ?? HttpClient.instance;

  Future<Either<Failure, StoriesResponse>> getStories() => requestEither(
    () => client.get('/stories'),
    decoder: (response) {
      final map = response.data['data'] as Map<String, dynamic>;
      final groups =
          (map['stories'] as List?)?.whereType<Map>().map((json) {
            final group = Map<String, dynamic>.from(json);
            final user = StoryUserEntity.fromJson(
              Map<String, dynamic>.from(group['user'] as Map),
            );
            final items =
                (group['stories'] as List?)?.whereType<Map>().map((item) {
                  return StoryGroupItem.fromJson(
                    Map<String, dynamic>.from(item),
                  );
                }).toList() ??
                [];
            return StoryGroupEntity(user: user, stories: items);
          }).toList() ??
          [];
      return Right(
        StoriesResponse(
          groups: groups,
          userHasStory: map['userHasStory'] as bool? ?? false,
        ),
      );
    },
  );

  Future<Either<Failure, StoryEntity>> createStory(
    String imagePath, {
    String? caption,
    List<StoryTextBlockEntity> textBlocks = const [],
    StoryAudience audience = StoryAudience.everyone,
  }) async {
    try {
      final isVideo = [
        '.mp4',
        '.mov',
        '.webm',
      ].any(imagePath.toLowerCase().endsWith);
      final data = FormData.fromMap({
        'image': isVideo
            ? await MultipartFile.fromFile(
                imagePath,
                filename: 'story${path.extension(imagePath).toLowerCase()}',
                contentType: DioMediaType.parse(_videoMime(imagePath)),
              )
            : await ImageUploadService.compressedMultipartFile(
                imagePath,
                filename: 'story.jpg',
              ),
        if (caption != null && caption.trim().isNotEmpty)
          'caption': caption.trim(),
        'audience': audience.wireValue,
        'textBlocks': jsonEncode(
          textBlocks.map((block) => block.toJson()).toList(),
        ),
      });
      return requestEither(
        () => client.post(
          '/stories',
          data: data,
          options: Options(contentType: 'multipart/form-data'),
        ),
        decoder: (response) =>
            Right(StoryEntity.fromJson(response.data['data'])),
      );
    } catch (_) {
      return const Left(ServerFailure('Erro ao processar imagem'));
    }
  }

  String _videoMime(String imagePath) =>
      switch (path.extension(imagePath).toLowerCase()) {
        '.mov' => 'video/quicktime',
        '.webm' => 'video/webm',
        _ => 'video/mp4',
      };

  Future<Either<Failure, void>> deleteStory(String storyId) =>
      requestEither<void>(
        () => client.patch('/stories/$storyId/delete'),
        decoder: (_) => const Right(null),
      );

  Future<Either<Failure, void>> viewStory(String storyId) =>
      requestEither<void>(
        () => client.post('/stories/$storyId/view'),
        decoder: (_) => const Right(null),
      );

  Future<Either<Failure, List<StoryEntity>>> getUserStories(String userId) =>
      requestEither(
        () => client.get('/stories/user/$userId'),
        decoder: (response) {
          final raw = response.data['data'];
          return Right(
            raw is List
                ? raw
                      .whereType<Map>()
                      .map(
                        (item) => StoryEntity.fromJson(
                          Map<String, dynamic>.from(item),
                        ),
                      )
                      .toList()
                : <StoryEntity>[],
          );
        },
      );

  Future<Either<Failure, List<StoryEntity>>> getStoryArchive() => requestEither(
    () => client.get('/stories/archive'),
    decoder: (response) => Right(
      _storyJsonMaps(
        response.data['data']['stories'],
      ).map(StoryEntity.fromJson).toList(),
    ),
  );

  Future<Either<Failure, List<StoryHighlightEntity>>> getStoryHighlights(
    String userId,
  ) => requestEither(
    () => client.get('/stories/highlights/user/$userId'),
    decoder: (response) => Right(
      _storyJsonMaps(
        response.data['data']['highlights'],
      ).map(StoryHighlightEntity.fromJson).toList(),
    ),
  );

  Future<Either<Failure, StoryHighlightEntity>> getStoryHighlight(String id) =>
      requestEither(
        () => client.get('/stories/highlights/$id'),
        decoder: (response) => Right(
          StoryHighlightEntity.fromJson(_storyJsonMap(response.data['data'])!),
        ),
      );

  Future<Either<Failure, String>> saveStoryHighlight({
    String? id,
    required String title,
    required List<String> storyIds,
    required String coverStoryId,
  }) => requestEither(
    () => id == null
        ? client.post(
            '/stories/highlights',
            data: {
              'title': title,
              'storyIds': storyIds,
              'coverStoryId': coverStoryId,
            },
          )
        : client.patch(
            '/stories/highlights/$id',
            data: {
              'title': title,
              'storyIds': storyIds,
              'coverStoryId': coverStoryId,
            },
          ),
    decoder: (response) => Right(response.data['data']['id'] as String),
  );

  Future<Either<Failure, void>> deleteStoryHighlight(String id) =>
      requestEither<void>(
        () => client.patch('/stories/highlights/$id/delete'),
        decoder: (_) => const Right(null),
      );
}

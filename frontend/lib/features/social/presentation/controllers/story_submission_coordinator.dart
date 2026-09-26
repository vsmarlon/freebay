import 'package:flutter/material.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class StorySubmissionCoordinator {
  bool _isSubmitting = false;

  Future<Either<Failure, StoryEntity>?> submit({
    required SocialRepository repository,
    required String imagePath,
    String? caption,
    List<StoryTextBlockEntity> textBlocks = const [],
    required VoidCallback invalidateGlobalStories,
    required void Function(String userId) invalidateUserStories,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    try {
      final result = await repository.createStory(
        imagePath,
        caption: caption,
        textBlocks: textBlocks,
      );
      result.fold((_) {}, (story) {
        invalidateGlobalStories();
        invalidateUserStories(story.userId);
      });
      return result;
    } finally {
      _isSubmitting = false;
    }
  }
}

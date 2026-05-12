import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/features/social/presentation/providers/post_details_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:flutter/material.dart';

class PostDetailsController {
  final Ref _ref;
  final String postId;

  PostDetailsController(this._ref, this.postId);

  Future<bool> sendComment(
    BuildContext context,
    TextEditingController textController, {
    String? parentId,
  }) async {
    final content = textController.text.trim();
    if (content.isEmpty) return false;

    final repository = _ref.read(socialRepositoryProvider);
    final result = await repository.commentPost(
      postId,
      content,
      parentId: parentId,
    );

    return result.fold(
      (failure) {
        if (context.mounted) AppSnackbar.error(context, failure.message);
        return false;
      },
      (_) {
        textController.clear();
        _ref.read(postDetailsProvider(postId).notifier).refresh();
        _ref.invalidate(feedProvider);
        return true;
      },
    );
  }

  void refresh() {
    _ref.read(postDetailsProvider(postId).notifier).refresh();
  }
}

final postDetailsControllerProvider =
    Provider.family<PostDetailsController, String>(
  (ref, postId) => PostDetailsController(ref, postId),
);

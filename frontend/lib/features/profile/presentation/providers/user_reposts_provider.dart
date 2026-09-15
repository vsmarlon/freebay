import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/entities/user_post_entry.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';

final userRepostsProvider = FutureProvider.family<List<UserPostEntry>, String>((
  ref,
  userId,
) async {
  final result = await ref
      .read(socialRepositoryProvider)
      .getRepostsByUser(userId);
  return result.fold((failure) => throw failure, (entries) => entries);
});

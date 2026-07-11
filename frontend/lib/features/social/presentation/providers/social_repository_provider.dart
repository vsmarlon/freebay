import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';

final socialRepositoryProvider = Provider<ISocialRepository>((ref) {
  return SocialRepository();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository();
});

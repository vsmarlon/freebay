import 'package:freebay/features/social/data/entities/user_search_entity.dart';

class UserSearchPageResult {
  final List<UserSearchEntity> users;
  final bool hasMore;
  final int? nextOffset;

  const UserSearchPageResult({
    required this.users,
    required this.hasMore,
    this.nextOffset,
  });
}

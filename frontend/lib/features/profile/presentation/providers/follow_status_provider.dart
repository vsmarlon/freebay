import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/profile/data/services/follow_service.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

final followServiceProvider = Provider<FollowService>((ref) => FollowService());

/// Cache for follow status to avoid redundant API calls.
/// Follow status doesn't change frequently, so we cache it for a short duration.
class FollowStatusCache {
  final Map<String, _CachedEntry> _cache = {};
  static const _cacheDuration = Duration(minutes: 5);

  FollowStatusResponse? get(String userId) {
    final entry = _cache[userId];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > _cacheDuration) {
      _cache.remove(userId);
      return null;
    }
    return entry.status;
  }

  void set(String userId, FollowStatusResponse status) {
    _cache[userId] = _CachedEntry(status: status, timestamp: DateTime.now());
  }

  void invalidate(String userId) {
    _cache.remove(userId);
  }

  void invalidateAll() {
    _cache.clear();
  }
}

class _CachedEntry {
  final FollowStatusResponse status;
  final DateTime timestamp;

  _CachedEntry({required this.status, required this.timestamp});
}

/// Global cache instance
final followStatusCacheProvider = Provider<FollowStatusCache>((ref) {
  return FollowStatusCache();
});

final followStatusProvider =
    FutureProvider.family<FollowStatusResponse?, String>((ref, userId) async {
      final authState = ref.watch(authControllerProvider);
      final user = authState.value;

      if (user == null) {
        return null;
      }

      // Check cache first
      final cache = ref.read(followStatusCacheProvider);
      final cached = cache.get(userId);
      if (cached != null) {
        return cached;
      }

      final service = ref.watch(followServiceProvider);
      final result = await service.getFollowStatus(userId);

      return result.fold((failure) => null, (status) {
        // Cache the result
        cache.set(userId, status);
        return status;
      });
    });

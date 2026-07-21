import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/profile/data/services/follow_service.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

final followServiceProvider = Provider<FollowService>((ref) => FollowService());

final followStatusProvider =
    FutureProvider.family<FollowStatusResponse?, String>((ref, userId) async {
      final authState = ref.watch(authControllerProvider);
      final user = authState.valueOrNull;

      if (user == null || user.isGuest) {
        return null;
      }

      final service = ref.watch(followServiceProvider);
      final result = await service.getFollowStatus(userId);

      return result.fold((failure) => null, (status) => status);
    });

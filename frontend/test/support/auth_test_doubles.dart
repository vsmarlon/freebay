import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/core/router/app_router.dart';

class TestAuthController extends AuthController {
  TestAuthController(this.user);

  final UserEntity? user;

  @override
  AsyncValue<UserEntity?> build() => AsyncValue.data(user);

  @override
  Future<void> logout() async {
    state = const AsyncValue.data(null);
    routerRefreshNotifier.value++;
  }
}

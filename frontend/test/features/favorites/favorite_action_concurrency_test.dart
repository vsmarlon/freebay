import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/favorites/data/services/favorites_service.dart';
import 'package:freebay/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _SlowFavoritesService extends FavoritesService {
  final response = Completer<Either<Failure, void>>();
  int calls = 0;

  @override
  Future<Either<Failure, void>> toggleFavorite(String productId) {
    calls++;
    return response.future;
  }
}

void main() {
  test(
    'five rapid favorite taps issue one request and keep its authoritative state',
    () async {
      final service = _SlowFavoritesService();
      final container = ProviderContainer(
        overrides: [
          favoritesServiceProvider.overrideWithValue(service),
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'favorite-user')),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(favoritesProvider.notifier);
      final taps = List.generate(
        5,
        (_) => notifier.toggleFavorite('product-1'),
      );

      expect(service.calls, 1);
      service.response.complete(const Right(null));

      expect(await Future.wait(taps), [true, false, false, false, false]);
      expect(
        container.read(favoritesProvider).isFavorited('product-1'),
        isTrue,
      );
    },
  );
}

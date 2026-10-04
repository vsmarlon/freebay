import 'dart:async';
import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/data/entities/product_page_result.dart';
import 'package:freebay/features/product/data/repositories/product_repository.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _DelayedProducts extends ProductRepository {
  final cursors = <String?>[];
  final responses = <Completer<Either<Failure, ProductPageResult>>>[];

  @override
  Future<Either<Failure, ProductPageResult>> getProducts({
    String? search,
    String? category,
    int? minPrice,
    int? maxPrice,
    String? cursor,
    ProductCondition? condition,
    String? sort,
    CancelToken? cancelToken,
  }) {
    cursors.add(cursor);
    final response = Completer<Either<Failure, ProductPageResult>>();
    responses.add(response);
    return response.future;
  }
}

ProductPageResult _page(String id, {String? nextCursor}) => ProductPageResult(
  products: [ProductEntity(id: id, sellerId: 'seller', title: id)],
  hasMore: nextCursor != null,
  nextCursor: nextCursor,
);

void main() {
  test('a refreshed catalog ignores an older load-more response', () async {
    final repository = _DelayedProducts();
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
        authControllerProvider.overrideWith(
          () => TestAuthController(testUser(id: 'catalog-user')),
        ),
      ],
    );
    addTearDown(container.dispose);
    const params = GetProductsParams();
    final subscription = container.listen(
      productsFeedProvider(params),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    expect(repository.cursors, [null]);
    repository.responses[0].complete(
      Right(_page('first', nextCursor: 'cursor')),
    );
    await Future<void>.delayed(Duration.zero);

    final feed = container.read(productsFeedProvider(params).notifier);
    final more = feed.loadMore();
    final refreshed = feed.load();
    expect(repository.cursors, [null, 'cursor', null]);
    repository.responses[2].complete(Right(_page('fresh')));
    await refreshed;
    repository.responses[1].complete(Right(_page('stale')));
    await more;

    final state = container.read(productsFeedProvider(params));
    expect(state.products.map((product) => product.id), ['fresh']);
    expect(state.isLoadingMore, isFalse);
  });
}

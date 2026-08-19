import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';

class FavoritesService extends BaseHttpRepository {
  FavoritesService({super.client});

  Future<Either<Failure, void>> toggleFavorite(String productId) =>
      safeVoid(() => client.post('/favorites/$productId'));

  Future<Either<Failure, bool>> isFavorited(String productId) => safeGet<bool>(
    '/favorites/check/$productId',
    extractKey: 'data.isFavorited',
    customMapper: (d) => d == true,
  );

  Future<Either<Failure, List<ProductEntity>>> getFavorites() =>
      safeGetList<ProductEntity>(
        '/favorites',
        listKey: 'data.products',
        fromJson: ProductEntity.fromJson,
      );
}

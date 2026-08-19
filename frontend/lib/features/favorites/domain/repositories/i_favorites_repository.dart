import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract class IFavoritesRepository {
  Future<Either<Failure, void>> toggleFavorite(String productId);
  Future<Either<Failure, bool>> isFavorited(String productId);
  Future<Either<Failure, List<ProductEntity>>> getFavorites();
}

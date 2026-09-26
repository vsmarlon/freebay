import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';

class FavoritesService {
  final Dio client;

  FavoritesService({Dio? client}) : client = client ?? HttpClient.instance;

  Future<Either<Failure, void>> toggleFavorite(String productId) =>
      requestEither<void>(
        () => client.post('/favorites/$productId'),
        decoder: (_) => const Right(null),
      );

  Future<Either<Failure, bool>> isFavorited(String productId) => requestEither(
    () => client.get('/favorites/check/$productId'),
    decoder: (response) => Right(response.data['data']['isFavorited'] == true),
  );

  Future<Either<Failure, List<ProductEntity>>> getFavorites() => requestEither(
    () => client.get('/favorites'),
    decoder: (response) {
      final raw = response.data['data']['products'];
      final products = raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) =>
                      ProductEntity.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <ProductEntity>[];
      return Right(products);
    },
  );
}

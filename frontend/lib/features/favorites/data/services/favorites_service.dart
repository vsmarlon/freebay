import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/http_client.dart';

class FavoritesService {
  Future<Either<Failure, bool>> toggleFavorite(String productId) async {
    try {
      final response = await HttpClient.instance.post('/favorites/$productId');
      final data = response.data['data'] as Map<String, dynamic>?;
      final favorited = data?['favorited'] as bool? ?? false;
      return Right(favorited);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, bool>> isFavorited(String productId) async {
    try {
      final response = await HttpClient.instance.get('/favorites/check/$productId');
      final data = response.data['data'] as Map<String, dynamic>?;
      final isFavorited = data?['isFavorited'] as bool? ?? false;
      return Right(isFavorited);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, List<ProductEntity>>> getFavorites() async {
    try {
      final response = await HttpClient.instance.get('/favorites');
      final data = response.data['data'] as Map<String, dynamic>?;
      final productsData = (data?['products'] as List?) ?? [];

      final products = productsData.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['seller'] != null) {
          map['sellerName'] = map['seller']['displayName'];
          map['sellerAvatar'] = map['seller']['avatarUrl'];
        }
        final images = map['images'] as List?;
        if (images != null && images.isNotEmpty) {
          final firstImage = images.first as Map;
          map['imageUrl'] = firstImage['url'];
        }
        return ProductEntity.fromJson(map);
      }).toList();

      return Right(products);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}

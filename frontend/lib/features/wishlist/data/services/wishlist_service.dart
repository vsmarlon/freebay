import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/http_client.dart';

class WishlistService {
  Future<Either<Failure, bool>> toggleWishlist(String productId) async {
    try {
      final response = await HttpClient.instance.post('/wishlist/$productId');
      final data = response.data['data'] as Map<String, dynamic>?;
      final inWishlist = data?['inWishlist'] as bool? ?? false;
      return Right(inWishlist);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, bool>> isInWishlist(String productId) async {
    try {
      final response = await HttpClient.instance.get('/wishlist/check/$productId');
      final data = response.data['data'] as Map<String, dynamic>?;
      final isInWishlist = data?['isInWishlist'] as bool? ?? false;
      return Right(isInWishlist);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, List<ProductEntity>>> getWishlist() async {
    try {
      final response = await HttpClient.instance.get('/wishlist');
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

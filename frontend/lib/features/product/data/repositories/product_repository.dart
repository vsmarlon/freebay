import 'package:dartz/dartz.dart';
import 'package:freebay/shared/services/http_client.dart';
import '../../../../shared/errors/failures/failures.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../entities/product_entity.dart';

class ProductRepository implements IProductRepository {
  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? search,
    String? category,
    int? minPrice,
    int? maxPrice,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await HttpClient.instance
          .get('/products', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        return Right(data.map((json) {
          if (json['seller'] != null) {
            json['sellerName'] = json['seller']['displayName'];
            json['sellerAvatar'] = json['seller']['avatarUrl'];
          }
          return ProductEntity.fromJson(json);
        }).toList());
      } else {
        return const Left(ServerFailure('Erro ao carregar os anúncios.'));
      }
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> createProduct(
      Map<String, dynamic> productData) async {
    try {
      final response =
          await HttpClient.instance.post('/products', data: productData);
      if (response.statusCode == 201 && response.data != null) {
        return Right(ProductEntity.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro ao criar anúncio.'));
      }
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}

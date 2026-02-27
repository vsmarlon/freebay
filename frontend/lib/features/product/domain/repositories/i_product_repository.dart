import 'package:dartz/dartz.dart';
import '../../../../shared/errors/failures/failures.dart';
import '../../data/entities/product_entity.dart';

abstract class IProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? search,
    String? category,
    int? minPrice,
    int? maxPrice,
    String? cursor,
  });
  Future<Either<Failure, ProductEntity>> createProduct(
      Map<String, dynamic> productData);
}

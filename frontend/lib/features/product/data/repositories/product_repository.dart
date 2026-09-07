import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/features/product/data/entities/product_page_result.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/data/entities/create_product_input.dart';

const _kProductCacheBox = 'product_catalog_cache';

class ProductRepository extends BaseHttpRepository {
  ProductRepository({super.client});

  Future<Box> _cacheBox() => Hive.openBox(_kProductCacheBox);

  Future<void> _writeCache(String key, List<ProductEntity> products) async {
    try {
      final box = await _cacheBox();
      await box.put(key, products.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  Future<List<ProductEntity>?> _readCache(String key) async {
    try {
      final box = await _cacheBox();
      final raw = box.get(key) as List?;
      if (raw == null || raw.isEmpty) return null;
      return raw
          .map(
            (r) => ProductEntity.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<Either<Failure, ProductEntity>> getProductById(String id) =>
      safeGet<ProductEntity>(
        '/products/$id',
        extractKey: 'data.product',
        fromJson: ProductEntity.fromJson,
      );

  Future<Either<Failure, ProductPageResult>> getProducts({
    String? search,
    String? category,
    int? minPrice,
    int? maxPrice,
    String? cursor,
    String? condition,
    String? sort,
  }) async {
    final cacheKey =
        'products|s:$search|cat:$category|min:$minPrice|max:$maxPrice|cond:$condition|sort:$sort|cur:$cursor';

    final result = await safeGet<ProductPageResult>(
      '/products',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (condition != null && condition.isNotEmpty) 'condition': condition,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        'minPrice': ?minPrice,
        'maxPrice': ?maxPrice,
        'cursor': ?cursor,
      },
      extractKey: 'data',
      customMapper: (data) {
        final map = data as Map<String, dynamic>?;
        final productsData = (map?['products'] as List?) ?? [];
        final nextCursor = map?['nextCursor'] as String?;
        final products = productsData
            .whereType<Map>()
            .map((j) => ProductEntity.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        _writeCache(cacheKey, products);
        return ProductPageResult(
          products: products,
          hasMore: nextCursor != null,
          nextCursor: nextCursor,
        );
      },
    );

    if (result.isLeft) {
      final cached = await _readCache(cacheKey);
      if (cached != null) {
        return Right(ProductPageResult(products: cached, hasMore: false));
      }
    }
    return result;
  }

  Future<Either<Failure, ProductEntity>> createProduct(
    CreateProductInput input,
  ) async {
    try {
      final formData = FormData.fromMap({
        'title': input.title,
        'description': input.description,
        'price': input.price,
        'condition': input.condition,
        'categoryId': input.categoryId,
        if (input.imagePath.isNotEmpty)
          'image': await ImageUploadService.compressedMultipartFile(
            input.imagePath,
            filename: 'product.jpg',
          ),
      });

      return safePost<ProductEntity>(
        '/products',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        extractKey: 'data',
        fromJson: ProductEntity.fromJson,
      );
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, ProductEntity>> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) => safePatch<ProductEntity>(
    '/products/$id',
    data: productData,
    extractKey: 'data',
    fromJson: ProductEntity.fromJson,
  );

  Future<Either<Failure, List<ProductEntity>>> getMyProducts() =>
      safeGetList<ProductEntity>(
        '/products/mine/all',
        listKey: 'data.products',
        fromJson: ProductEntity.fromJson,
      );
}

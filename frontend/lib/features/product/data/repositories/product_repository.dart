import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/features/product/data/entities/product_page_result.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/data/entities/create_product_input.dart';
import 'package:freebay/features/product/domain/product_filters.dart';

const _kProductCacheBox = 'product_catalog_cache';
const _maxProductCachePages = 8;

class ProductRepository {
  final Dio client;

  ProductRepository({Dio? client}) : client = client ?? HttpClient.instance;

  Future<Box> _cacheBox() => Hive.openBox(_kProductCacheBox);

  Future<void> _writeCache(String key, List<ProductEntity> products) async {
    try {
      final box = await _cacheBox();
      if (box.containsKey(key)) await box.delete(key);
      await box.put(key, products.map((e) => e.toJson()).toList());
      // ponytail: only recent first pages stay hot; older filters refetch.
      while (box.length > _maxProductCachePages) {
        await box.delete(box.keys.first);
      }
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
      requestEither(
        () => client.get('/products/$id'),
        decoder: (response) =>
            Right(ProductEntity.fromJson(response.data['data']['product'])),
      );

  Future<Either<Failure, ProductPageResult>> getProducts({
    String? search,
    String? category,
    int? minPrice,
    int? maxPrice,
    String? cursor,
    ProductCondition? condition,
    String? sort,
  }) async {
    final cacheKey =
        'products|s:$search|cat:$category|min:$minPrice|max:$maxPrice|cond:${condition?.wireValue}|sort:$sort|cur:$cursor';

    final result = await requestEither<ProductPageResult>(
      () => client.get(
        '/products',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty) 'category': category,
          if (condition != null) 'condition': condition.wireValue,
          if (sort != null && sort.isNotEmpty) 'sort': sort,
          'minPrice': ?minPrice,
          'maxPrice': ?maxPrice,
          'cursor': ?cursor,
        },
      ),
      decoder: (response) {
        final data = response.data['data'];
        final map = data as Map<String, dynamic>?;
        final productsData = (map?['products'] as List?) ?? [];
        final nextCursor = map?['nextCursor'] as String?;
        final products = productsData
            .whereType<Map>()
            .map((j) => ProductEntity.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        return Right(
          ProductPageResult(
            products: products,
            hasMore: nextCursor != null,
            nextCursor: nextCursor,
          ),
        );
      },
    );

    if (result.isRight && cursor == null) {
      await _writeCache(cacheKey, result.rightOrNull!.products);
    } else if (result.isLeft && cursor == null) {
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
        'condition': input.condition.wireValue,
        'categoryId': input.categoryId,
        if (input.imagePath.isNotEmpty)
          'image': await ImageUploadService.compressedMultipartFile(
            input.imagePath,
            filename: 'product.jpg',
          ),
      });

      return requestEither(
        () => client.post(
          '/products',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        ),
        decoder: (response) =>
            Right(ProductEntity.fromJson(response.data['data'])),
      );
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, ProductEntity>> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) => requestEither(
    () => client.patch('/products/$id', data: productData),
    decoder: (response) => Right(ProductEntity.fromJson(response.data['data'])),
  );

  Future<Either<Failure, List<ProductEntity>>> getMyProducts() => requestEither(
    () => client.get('/products/mine/all'),
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

import 'package:freebay/shared/either/either.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/product/domain/repositories/i_product_repository.dart';
import 'package:freebay/features/product/data/entities/product_page_result.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

/// Box name for the product catalog cache.
const _kProductCacheBox = 'product_catalog_cache';

/// Serialises a [ProductEntity] to a JSON-compatible map for Hive storage.
Map<String, dynamic> _entityToMap(ProductEntity e) => e.toJson();

/// Deserialises a Hive-stored map back into a [ProductEntity].
ProductEntity _mapToEntity(dynamic raw) =>
    ProductEntity.fromJson(Map<String, dynamic>.from(raw as Map));

class ProductRepository implements IProductRepository {
  // ── Hive cache helpers ───────────────────────────────────────────────────

  /// Opens (or returns the already-open) product cache box.
  Future<Box> _cacheBox() => Hive.openBox(_kProductCacheBox);

  /// Writes [products] into Hive under the given [cacheKey].
  Future<void> _writeCache(
    String cacheKey,
    List<ProductEntity> products,
  ) async {
    try {
      final box = await _cacheBox();
      await box.put(cacheKey, products.map(_entityToMap).toList());
    } catch (e) {
      if (kDebugMode) debugPrint('[PRODUCT CACHE] write error: $e');
    }
  }

  /// Returns cached products for [cacheKey], or null if the cache is empty.
  Future<List<ProductEntity>?> _readCache(String cacheKey) async {
    try {
      final box = await _cacheBox();
      final raw = box.get(cacheKey) as List?;
      if (raw == null || raw.isEmpty) return null;
      return raw.map(_mapToEntity).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[PRODUCT CACHE] read error: $e');
      return null;
    }
  }

  // ── Repository interface ─────────────────────────────────────────────────

  @override
  Future<Either<Failure, ProductEntity>> getProductById(String id) async {
    try {
      final response = await HttpClient.instance.get('/products/$id');

      if (kDebugMode) {
        debugPrint('[PRODUCT] getProductById status: ${response.statusCode}');
        debugPrint('[PRODUCT] getProductById data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'] as Map<String, dynamic>;
        final productData = responseData['product'] as Map<String, dynamic>;

        return Right(ProductEntity.fromJson(productData));
      }
      return const Left(NotFoundFailure('Produto não encontrado.'));
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] getProductById DioException: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] getProductById error: $e');
        debugPrint('[PRODUCT] getProductById stack: $stack');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ProductPageResult>> getProducts({
    String? search,
    String? category,
    int? minPrice,
    int? maxPrice,
    String? cursor,
    String? condition,
    String? sort,
  }) async {
    // Build a deterministic cache key from the query parameters.
    final cacheKey =
        'products|s:$search|cat:$category|min:$minPrice|max:$maxPrice|cond:$condition|sort:$sort|cur:$cursor';

    try {
      final queryParams = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (condition != null && condition.isNotEmpty) 'condition': condition,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        'minPrice': ?minPrice,
        'maxPrice': ?maxPrice,
        'cursor': ?cursor,
      };

      final response = await HttpClient.instance.get(
        '/products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final productsData = (data?['products'] as List?) ?? [];
        final nextCursor = data?['nextCursor'] as String?;

        final products = productsData.map((json) {
          final map = Map<String, dynamic>.from(json as Map);
          return ProductEntity.fromJson(map);
        }).toList();

        // Persist fresh results for offline fallback.
        await _writeCache(cacheKey, products);

        return Right(
          ProductPageResult(
            products: products,
            hasMore: nextCursor != null,
            nextCursor: nextCursor,
          ),
        );
      } else {
        return const Left(ServerFailure('Erro ao carregar os anúncios.'));
      }
    } on DioException catch (e) {
      // Network failure — serve stale cache if available.
      final cached = await _readCache(cacheKey);
      if (cached != null) {
        return Right(ProductPageResult(products: cached, hasMore: false));
      }

      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      // Generic failure — serve stale cache if available.
      final cached = await _readCache(cacheKey);
      if (cached != null) {
        return Right(ProductPageResult(products: cached, hasMore: false));
      }

      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      final imagePath = productData.remove('imagePath') as String?;
      if (kDebugMode) {
        debugPrint('[PRODUCT REPO] createProduct payload=$productData');
        debugPrint('[PRODUCT REPO] createProduct imagePath=$imagePath');
      }
      final formData = FormData.fromMap({
        ...productData,
        if (imagePath != null)
          'image': await ImageUploadService.compressedMultipartFile(
            imagePath,
            filename: 'product.jpg',
          ),
      });

      final response = await HttpClient.instance.post(
        '/products',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (kDebugMode) {
        debugPrint(
          '[PRODUCT REPO] createProduct status=${response.statusCode}',
        );
        debugPrint('[PRODUCT REPO] createProduct response=${response.data}');
      }
      if (response.statusCode == 201 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Right(ProductEntity.fromJson(data));
      } else {
        return const Left(ServerFailure('Erro ao criar anúncio.'));
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] createProduct DioException: ${e.type}');
        debugPrint('[PRODUCT] createProduct message: ${e.message}');
        debugPrint('[PRODUCT] createProduct response: ${e.response?.data}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] createProduct unexpected error: $e');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await HttpClient.instance.patch(
        '/products/$id',
        data: productData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Right(ProductEntity.fromJson(data));
      }

      return const Left(ServerFailure('Erro ao atualizar anúncio.'));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getMyProducts() async {
    try {
      final response = await HttpClient.instance.get('/products/mine/all');

      if (kDebugMode) {
        debugPrint('[PRODUCT] getMyProducts status: ${response.statusCode}');
        debugPrint('[PRODUCT] getMyProducts data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final productsData = (data?['products'] as List?) ?? [];

        final products = productsData.map((json) {
          final map = Map<String, dynamic>.from(json as Map);
          return ProductEntity.fromJson(map);
        }).toList();

        return Right(products);
      }
      return const Left(ServerFailure('Erro ao carregar seus anúncios.'));
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] getMyProducts DioException: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] getMyProducts error: $e');
        debugPrint('[PRODUCT] getMyProducts stack: $stack');
      }
      return const Left(UnknownFailure());
    }
  }
}

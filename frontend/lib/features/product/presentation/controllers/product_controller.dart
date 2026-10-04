import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart' show RangeValues;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/features/product/data/repositories/product_repository.dart';
import 'package:freebay/features/product/data/repositories/category_repository.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/domain/usecases/create_product_usecase.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/storage_service.dart';

part 'product_controller.g.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final getProductsUsecaseProvider = Provider(
  (ref) => GetProductsUsecase(ref.watch(productRepositoryProvider)),
);
final createProductUsecaseProvider = Provider(
  (ref) => CreateProductUsecase(ref.watch(productRepositoryProvider)),
);

// My products provider
final myProductsProvider = FutureProvider<List<ProductEntity>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getMyProducts();
  return result.fold((failure) => throw failure, (products) => products);
});

// Single product provider
final productByIdProvider = FutureProvider.autoDispose
    .family<ProductEntity, String>((ref, productId) async {
      final repository = ref.watch(productRepositoryProvider);
      final cancelToken = CancelToken();
      ref.onDispose(cancelToken.cancel);
      final result = await repository.getProductById(
        productId,
        cancelToken: cancelToken,
      );

      return result.fold((failure) => throw failure, (product) => product);
    });

class ProductsFeedState {
  final List<ProductEntity> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;
  final String? error;
  final bool isRefreshing;
  final bool isStale;

  const ProductsFeedState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.nextCursor,
    this.error,
    this.isRefreshing = false,
    this.isStale = false,
  });

  ProductsFeedState copyWith({
    List<ProductEntity>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? nextCursor,
    String? error,
    bool? isRefreshing,
    bool? isStale,
  }) {
    return ProductsFeedState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor,
      error: error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isStale: isStale ?? this.isStale,
    );
  }
}

@riverpod
class ProductsFeed extends _$ProductsFeed {
  int _requestId = 0;
  String? _accountId;
  bool _restored = false;

  @override
  ProductsFeedState build(GetProductsParams params) {
    final accountId = ref.watch(
      authControllerProvider.select((auth) => auth.asData?.value?.id),
    );
    if (_accountId != accountId) {
      _accountId = accountId;
      _requestId++;
      _restored = false;
    }
    Future.microtask(() {
      if (ref.mounted) load();
    });
    return const ProductsFeedState(isLoading: true);
  }

  Future<void> load() async {
    final requestId = ++_requestId;
    final accountId = _accountId;
    if (!_restored && accountId != null && params.cursor == null) {
      _restored = true;
      final cachedPages = await StorageService.readCachedJson(
        userId: accountId,
        key: 'catalog.first-pages.v1',
      );
      if (!ref.mounted ||
          requestId != _requestId ||
          accountId != ref.read(authControllerProvider).asData?.value?.id) {
        return;
      }
      final products = _decodeCachedProducts(
        _findCachedProductPage(cachedPages, _productCacheKey(params)),
      );
      if (products != null) {
        state = state.copyWith(
          products: products,
          isLoading: false,
          isStale: true,
        );
      }
    }
    state = state.copyWith(
      isLoading: state.products.isEmpty,
      isRefreshing: state.products.isNotEmpty,
      isLoadingMore: false,
      nextCursor: state.nextCursor,
    );
    final usecase = ref.read(getProductsUsecaseProvider);
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);
    final result = await usecase(
      params.withCursor(null),
      cancelToken: cancelToken,
    );
    if (!ref.mounted ||
        requestId != _requestId ||
        accountId != ref.read(authControllerProvider).asData?.value?.id) {
      return;
    }

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        isRefreshing: false,
        nextCursor: state.nextCursor,
      ),
      (page) {
        if (accountId != null) {
          unawaited(
            _cacheProducts(
              accountId,
              params,
              page.products,
              page.hasMore,
              page.nextCursor,
            ),
          );
        }
        state = ProductsFeedState(
          products: page.products,
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final cursor = state.nextCursor;
    if (cursor == null) return;

    final requestId = _requestId;
    state = state.copyWith(isLoadingMore: true, nextCursor: cursor);
    final usecase = ref.read(getProductsUsecaseProvider);
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);
    final result = await usecase(
      params.withCursor(cursor),
      cancelToken: cancelToken,
    );
    if (!ref.mounted || requestId != _requestId) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        error: failure.message,
        nextCursor: cursor,
      ),
      (page) => state = ProductsFeedState(
        products: [...state.products, ...page.products],
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }
}

String _productCacheKey(GetProductsParams params) =>
    'catalog.first-page.v1.${Uri.encodeComponent(jsonEncode({'search': params.search, 'category': params.category, 'minPrice': params.minPrice, 'maxPrice': params.maxPrice, 'condition': params.condition?.wireValue, 'sort': params.sort.wireValue}))}';

Map<String, Object?>? _findCachedProductPage(
  Map<String, Object?>? cache,
  String pageKey,
) {
  final pages = cache?['pages'];
  if (cache?['cacheVersion'] != 1 ||
      pages is! List ||
      !pages.every((page) => page is Map<String, dynamic>)) {
    return null;
  }
  for (final page in pages.whereType<Map<String, dynamic>>()) {
    if (page['key'] == pageKey) return Map<String, Object?>.from(page);
  }
  return null;
}

bool _isSafeCachedUrl(String url) {
  final normalized = url.toLowerCase();
  return !normalized.contains('/private/') &&
      !normalized.contains('/signed/') &&
      !normalized.contains('signature=') &&
      !normalized.contains('token=');
}

List<ProductEntity>? _decodeCachedProducts(Map<String, Object?>? cached) {
  final rawProducts = cached?['products'];
  if (cached?['pageVersion'] != 1 ||
      cached?['limit'] != 20 ||
      rawProducts is! List ||
      !rawProducts.every((item) => item is Map<String, dynamic>)) {
    return null;
  }
  try {
    return rawProducts.map((item) => ProductEntity.fromJson(item)).toList();
  } catch (_) {
    return null;
  }
}

Future<void> _catalogCacheWrite = Future<void>.value();

Future<void> _cacheProducts(
  String userId,
  GetProductsParams params,
  List<ProductEntity> products,
  bool hasMore,
  String? nextCursor,
) {
  final write = _catalogCacheWrite.then(
    (_) => _writeCatalogProducts(userId, params, products, hasMore, nextCursor),
  );
  _catalogCacheWrite = write.then<void>(
    (_) {},
    onError: (Object error, StackTrace stackTrace) {},
  );
  return write;
}

Future<void> _writeCatalogProducts(
  String userId,
  GetProductsParams params,
  List<ProductEntity> products,
  bool hasMore,
  String? nextCursor,
) async {
  final publicProducts = products
      .where(
        (product) =>
            product.images?.every((image) => _isSafeCachedUrl(image.url)) ??
            true,
      )
      .map((product) {
        final json = product.toJson();
        final seller = product.seller;
        if (seller != null) {
          json['seller'] = {
            'id': seller.id,
            'displayName': seller.displayName,
            'username': seller.username,
            'avatarUrl':
                seller.avatarUrl != null && _isSafeCachedUrl(seller.avatarUrl!)
                ? seller.avatarUrl
                : null,
            'isVerified': seller.isVerified,
          };
        }
        return json;
      })
      .toList();
  const cacheKey = 'catalog.first-pages.v1';
  final cached = await StorageService.readCachedJson(
    userId: userId,
    key: cacheKey,
  );
  final pages = _findCachedProductPages(cached)
    ..removeWhere((page) => page['key'] == _productCacheKey(params))
    ..add({
      'key': _productCacheKey(params),
      'pageVersion': 1,
      'limit': 20,
      'products': publicProducts,
      'hasMore': hasMore,
      'nextCursor': nextCursor,
    });
  if (pages.length > 8) pages.removeRange(0, pages.length - 8);
  await StorageService.writeCachedJson(
    userId: userId,
    key: cacheKey,
    json: {'cacheVersion': 1, 'pages': pages},
  );
}

List<Map<String, Object?>> _findCachedProductPages(
  Map<String, Object?>? cache,
) {
  final pages = cache?['pages'];
  if (cache?['cacheVersion'] != 1 || pages is! List) return [];
  return pages
      .whereType<Map<String, dynamic>>()
      .map(Map<String, Object?>.from)
      .where((page) => page['pageVersion'] == 1 && page['key'] is String)
      .toList();
}

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

// Search state provider
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

// Selected category provider
final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String?>(
      SelectedCategoryNotifier.new,
    );

class ProductSortNotifier extends Notifier<ProductSort> {
  @override
  ProductSort build() => ProductSort.recent;

  @override
  set state(ProductSort value) => super.state = value;
}

// Sort + condition + price filters for the Explorar tab
final productSortProvider = NotifierProvider<ProductSortNotifier, ProductSort>(
  ProductSortNotifier.new,
);

class ProductConditionNotifier extends Notifier<ProductCondition?> {
  @override
  ProductCondition? build() => null;

  @override
  set state(ProductCondition? value) => super.state = value;
}

final productConditionProvider =
    NotifierProvider<ProductConditionNotifier, ProductCondition?>(
      ProductConditionNotifier.new,
    );

class ProductPriceRangeNotifier extends Notifier<RangeValues?> {
  @override
  RangeValues? build() => null;

  @override
  set state(RangeValues? value) => super.state = value;
}

final productPriceRangeProvider =
    NotifierProvider<ProductPriceRangeNotifier, RangeValues?>(
      ProductPriceRangeNotifier.new,
    );

// Categories from backend
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategories();

  return result.fold((failure) => throw failure, (categories) => categories);
});

// Flat list of categories for filter chips (includes children)
final flatCategoriesProvider = Provider<AsyncValue<List<CategoryEntity>>>((
  ref,
) {
  final categoriesAsync = ref.watch(categoriesProvider);

  return categoriesAsync.whenData((categories) {
    final flat = <CategoryEntity>[];
    void addWithChildren(List<CategoryEntity> cats) {
      for (final cat in cats) {
        flat.add(cat);
        if (cat.children.isNotEmpty) {
          addWithChildren(cat.children);
        }
      }
    }

    addWithChildren(categories);
    return flat;
  });
});

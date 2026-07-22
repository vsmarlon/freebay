import 'package:flutter/material.dart' show RangeValues;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/product/data/repositories/product_repository.dart';
import 'package:freebay/features/product/data/repositories/category_repository.dart';
import 'package:freebay/features/product/domain/repositories/i_product_repository.dart';
import 'package:freebay/features/product/domain/repositories/i_category_repository.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/domain/usecases/create_product_usecase.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';

final productRepositoryProvider = Provider<IProductRepository>((ref) {
  return ProductRepository();
});

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  return CategoryRepository();
});

final getProductsUsecaseProvider = Provider(
  (ref) => GetProductsUsecase(ref.watch(productRepositoryProvider)),
);
final createProductUsecaseProvider = Provider(
  (ref) => CreateProductUsecase(ref.watch(productRepositoryProvider)),
);

// Single product provider
final productByIdProvider = FutureProvider.autoDispose
    .family<ProductEntity, String>((ref, productId) async {
      final repository = ref.watch(productRepositoryProvider);
      final result = await repository.getProductById(productId);

      return result.fold(
        (failure) => throw Exception(failure.message),
        (product) => product,
      );
    });

class ProductsFeedState {
  final List<ProductEntity> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;
  final String? error;

  const ProductsFeedState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.nextCursor,
    this.error,
  });

  ProductsFeedState copyWith({
    List<ProductEntity>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? nextCursor,
    String? error,
  }) {
    return ProductsFeedState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor,
      error: error,
    );
  }
}

class ProductsFeedNotifier extends StateNotifier<ProductsFeedState> {
  final GetProductsUsecase _usecase;
  final GetProductsParams _params;

  ProductsFeedNotifier(this._usecase, this._params)
    : super(const ProductsFeedState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null, nextCursor: null);
    final result = await _usecase(_params.withCursor(null));

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (page) => state = ProductsFeedState(
        products: page.products,
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.nextCursor == null) return;

    state = state.copyWith(isLoadingMore: true, nextCursor: state.nextCursor);
    final result = await _usecase(_params.withCursor(state.nextCursor));

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        error: failure.message,
        nextCursor: state.nextCursor,
      ),
      (page) => state = ProductsFeedState(
        products: [...state.products, ...page.products],
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }
}

final productsFeedProvider =
    StateNotifierProvider.family<
      ProductsFeedNotifier,
      ProductsFeedState,
      GetProductsParams
    >((ref, params) {
      return ProductsFeedNotifier(
        ref.watch(getProductsUsecaseProvider),
        params,
      );
    });

// Search state provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Selected category provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Sort + condition + price filters for the Explorar tab
final productSortProvider = StateProvider<String>((ref) => 'recent');

final productConditionProvider = StateProvider<String?>((ref) => null);

final productPriceRangeProvider = StateProvider<RangeValues?>((ref) => null);

// Categories from backend
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategories();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../data/entities/product_entity.dart';
import '../../data/entities/category_entity.dart';

final productRepositoryProvider = Provider<IProductRepository>((ref) {
  return ProductRepository();
});

final categoryRepositoryProvider = Provider((ref) {
  return CategoryRepository();
});

final getProductsUsecaseProvider =
    Provider((ref) => GetProductsUsecase(ref.watch(productRepositoryProvider)));
final createProductUsecaseProvider = Provider(
    (ref) => CreateProductUsecase(ref.watch(productRepositoryProvider)));

// Single product provider
final productByIdProvider =
    FutureProvider.family<ProductEntity, String>((ref, productId) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProductById(productId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (product) => product,
  );
});

final productsFeedProvider =
    FutureProvider.family<List<ProductEntity>, GetProductsParams>(
        (ref, params) async {
  final usecase = ref.watch(getProductsUsecaseProvider);
  final result = await usecase(params);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (products) => products,
  );
});

// Search state provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Selected category provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

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
final flatCategoriesProvider =
    Provider<AsyncValue<List<CategoryEntity>>>((ref) {
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

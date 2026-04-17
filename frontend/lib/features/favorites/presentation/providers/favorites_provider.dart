import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/favorites/data/services/favorites_service.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

final favoritesServiceProvider = Provider((ref) => FavoritesService());

class FavoritesState {
  final bool isLoading;
  final List<ProductEntity> products;
  final Set<String> favoritedProductIds;

  const FavoritesState({
    this.isLoading = false,
    this.products = const [],
    this.favoritedProductIds = const {},
  });

  FavoritesState copyWith({
    bool? isLoading,
    List<ProductEntity>? products,
    Set<String>? favoritedProductIds,
  }) {
    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      favoritedProductIds: favoritedProductIds ?? this.favoritedProductIds,
    );
  }

  bool isFavorited(String productId) => favoritedProductIds.contains(productId);
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final FavoritesService _service;

  FavoritesNotifier(this._service) : super(const FavoritesState());

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true);
    final result = await _service.getFavorites();
    result.fold(
      (_) => state = state.copyWith(isLoading: false),
      (products) {
        final ids = products.map((p) => p.id).toSet();
        state = state.copyWith(
          isLoading: false,
          products: products,
          favoritedProductIds: ids,
        );
      },
    );
  }

  Future<bool> initializeFavoriteStatus(String productId) async {
    final result = await _service.isFavorited(productId);
    return result.fold(
      (_) => false,
      (isFavorited) {
        final ids = Set<String>.from(state.favoritedProductIds);
        if (isFavorited) {
          ids.add(productId);
        } else {
          ids.remove(productId);
        }
        state = state.copyWith(favoritedProductIds: ids);
        return isFavorited;
      },
    );
  }

  Future<bool> toggleFavorite(String productId) async {
    final current = state.favoritedProductIds.contains(productId);
    final ids = Set<String>.from(state.favoritedProductIds);

    if (current) {
      ids.remove(productId);
    } else {
      ids.add(productId);
    }
    state = state.copyWith(favoritedProductIds: ids);

    final result = await _service.toggleFavorite(productId);
    return result.fold(
      (_) {
        final rollback = Set<String>.from(state.favoritedProductIds);
        if (current) {
          rollback.add(productId);
        } else {
          rollback.remove(productId);
        }
        state = state.copyWith(favoritedProductIds: rollback);
        return false;
      },
      (favorited) {
        final next = Set<String>.from(state.favoritedProductIds);
        if (favorited) {
          next.add(productId);
        } else {
          next.remove(productId);
          state = state.copyWith(
            products: state.products.where((p) => p.id != productId).toList(),
          );
        }
        state = state.copyWith(favoritedProductIds: next);
        return true;
      },
    );
  }

  bool isFavorited(String productId) {
    return state.favoritedProductIds.contains(productId);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier(ref.watch(favoritesServiceProvider));
});

final isFavoritedProvider = FutureProvider.family<bool, String>((ref, productId) async {
  final result = await ref.read(favoritesServiceProvider).isFavorited(productId);
  return result.fold((_) => false, (value) => value);
});

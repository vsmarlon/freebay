import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/wishlist/data/services/wishlist_service.dart';

final wishlistServiceProvider = Provider((ref) => WishlistService());

class WishlistState {
  final bool isLoading;
  final List<ProductEntity> products;
  final Set<String> wishlistProductIds;

  const WishlistState({
    this.isLoading = false,
    this.products = const [],
    this.wishlistProductIds = const {},
  });

  WishlistState copyWith({
    bool? isLoading,
    List<ProductEntity>? products,
    Set<String>? wishlistProductIds,
  }) {
    return WishlistState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      wishlistProductIds: wishlistProductIds ?? this.wishlistProductIds,
    );
  }

  bool isInWishlist(String productId) => wishlistProductIds.contains(productId);
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistService _service;

  WishlistNotifier(this._service) : super(const WishlistState());

  Future<void> loadWishlist() async {
    state = state.copyWith(isLoading: true);
    final result = await _service.getWishlist();
    result.fold(
      (_) => state = state.copyWith(isLoading: false),
      (products) {
        final ids = products.map((p) => p.id).toSet();
        state = state.copyWith(
          isLoading: false,
          products: products,
          wishlistProductIds: ids,
        );
      },
    );
  }

  Future<bool> initializeWishlistStatus(String productId) async {
    final result = await _service.isInWishlist(productId);
    return result.fold(
      (_) => false,
      (isInWishlist) {
        final ids = Set<String>.from(state.wishlistProductIds);
        if (isInWishlist) {
          ids.add(productId);
        } else {
          ids.remove(productId);
        }
        state = state.copyWith(wishlistProductIds: ids);
        return isInWishlist;
      },
    );
  }

  Future<bool> toggleWishlist(String productId) async {
    final current = state.wishlistProductIds.contains(productId);
    final ids = Set<String>.from(state.wishlistProductIds);
    if (current) {
      ids.remove(productId);
    } else {
      ids.add(productId);
    }
    state = state.copyWith(wishlistProductIds: ids);

    final result = await _service.toggleWishlist(productId);
    return result.fold(
      (_) {
        final rollback = Set<String>.from(state.wishlistProductIds);
        if (current) {
          rollback.add(productId);
        } else {
          rollback.remove(productId);
        }
        state = state.copyWith(wishlistProductIds: rollback);
        return false;
      },
      (inWishlist) {
        final next = Set<String>.from(state.wishlistProductIds);
        if (inWishlist) {
          next.add(productId);
        } else {
          next.remove(productId);
          state = state.copyWith(
            products: state.products.where((p) => p.id != productId).toList(),
          );
        }
        state = state.copyWith(wishlistProductIds: next);
        return true;
      },
    );
  }

  bool isInWishlist(String productId) {
    return state.wishlistProductIds.contains(productId);
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier(ref.watch(wishlistServiceProvider));
});

final isInWishlistProvider = FutureProvider.family<bool, String>((ref, productId) async {
  final result = await ref.read(wishlistServiceProvider).isInWishlist(productId);
  return result.fold((_) => false, (value) => value);
});

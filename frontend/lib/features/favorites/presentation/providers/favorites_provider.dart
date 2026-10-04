import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/favorites/data/services/favorites_service.dart';
import 'package:freebay/features/favorites/data/repositories/favorites_repository.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

final favoritesServiceProvider = Provider((ref) => FavoritesService());

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(favoritesServiceProvider));
});

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

class FavoritesNotifier extends Notifier<FavoritesState> {
  String? _ownerId;
  int _sessionId = 0;
  int _requestId = 0;
  final Set<String> _inFlight = <String>{};

  @override
  FavoritesState build() {
    final ownerId = ref.watch(
      authControllerProvider.select((auth) => auth.asData?.value?.id),
    );
    if (_ownerId != ownerId) {
      _ownerId = ownerId;
      _sessionId++;
      _requestId++;
      _inFlight.clear();
    }
    return const FavoritesState();
  }

  void clear() {
    _sessionId++;
    _requestId++;
    _inFlight.clear();
    state = const FavoritesState();
  }

  Future<void> loadFavorites() async {
    if (_inFlight.isNotEmpty) return;
    final sessionId = _sessionId;
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true);
    final result = await ref.read(favoritesRepositoryProvider).getFavorites();
    if (!ref.mounted || sessionId != _sessionId || requestId != _requestId) {
      return;
    }
    result.fold((_) => state = state.copyWith(isLoading: false), (products) {
      final ids = products.map((p) => p.id).toSet();
      state = state.copyWith(
        isLoading: false,
        products: products,
        favoritedProductIds: ids,
      );
    });
  }

  Future<bool> initializeFavoriteStatus(String productId) async {
    if (_inFlight.contains(productId)) {
      return state.isFavorited(productId);
    }
    final sessionId = _sessionId;
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: false);
    final result = await ref
        .read(favoritesRepositoryProvider)
        .isFavorited(productId);
    if (!ref.mounted || sessionId != _sessionId || requestId != _requestId) {
      return false;
    }
    return result.fold((_) => false, (isFavorited) {
      final ids = Set<String>.from(state.favoritedProductIds);
      if (isFavorited) {
        ids.add(productId);
      } else {
        ids.remove(productId);
      }
      state = state.copyWith(favoritedProductIds: ids);
      return isFavorited;
    });
  }

  Future<bool> toggleFavorite(String productId) async {
    if (!_inFlight.add(productId)) return false;
    final sessionId = _sessionId;
    _requestId++;
    final current = state.favoritedProductIds.contains(productId);
    final ids = Set<String>.from(state.favoritedProductIds);

    if (current) {
      ids.remove(productId);
    } else {
      ids.add(productId);
    }
    state = state.copyWith(isLoading: false, favoritedProductIds: ids);

    try {
      final result = await ref
          .read(favoritesRepositoryProvider)
          .toggleFavorite(productId);
      if (!ref.mounted || sessionId != _sessionId) return false;
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
        (_) {
          return !current;
        },
      );
    } catch (_) {
      if (ref.mounted && sessionId == _sessionId) {
        final rollback = Set<String>.from(state.favoritedProductIds);
        if (current) {
          rollback.add(productId);
        } else {
          rollback.remove(productId);
        }
        state = state.copyWith(favoritedProductIds: rollback);
      }
      return false;
    } finally {
      if (sessionId == _sessionId) _inFlight.remove(productId);
    }
  }

  bool isFavorited(String productId) {
    return state.favoritedProductIds.contains(productId);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, FavoritesState>(
  FavoritesNotifier.new,
);

final isFavoritedProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  productId,
) async {
  ref.watch(authControllerProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  final result = await ref
      .read(favoritesRepositoryProvider)
      .isFavorited(productId, cancelToken: cancelToken);
  return result.fold((_) => false, (value) => value);
});

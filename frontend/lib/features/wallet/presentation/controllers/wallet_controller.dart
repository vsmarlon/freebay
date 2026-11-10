import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/repositories/wallet_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_controller.g.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

@Riverpod(keepAlive: true)
class Wallet extends _$Wallet {
  int _generation = 0;
  String? _userId;

  @override
  AsyncValue<WalletEntity?> build() {
    ref.watch(walletRepositoryProvider);
    return const AsyncValue.loading();
  }

  Future<void> loadWallet(String userId) async {
    final generation = ++_generation;
    _userId = userId;
    state = const AsyncValue.loading();
    final result = await ref.read(walletRepositoryProvider).getWallet();

    if (generation != _generation || _userId != userId) return;

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (wallet) => state = AsyncValue.data(wallet),
    );
  }

  void reset() {
    _generation++;
    _userId = null;
    state = const AsyncValue.loading();
  }
}

class WalletHistoryState {
  final List<WalletTransactionEntity> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;
  final String? error;

  const WalletHistoryState({
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextCursor,
    this.error,
  });

  WalletHistoryState copyWith({
    List<WalletTransactionEntity>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? nextCursor,
    String? error,
  }) {
    return WalletHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      error: error,
    );
  }
}

@Riverpod(keepAlive: true)
class WalletHistory extends _$WalletHistory {
  int _generation = 0;
  String? _userId;

  @override
  WalletHistoryState build() {
    ref.watch(walletRepositoryProvider);
    return const WalletHistoryState();
  }

  Future<void> load(String userId) async {
    final generation = ++_generation;
    _userId = userId;
    state = state.copyWith(isLoading: true, isLoadingMore: false);

    final result = await ref.read(walletRepositoryProvider).getTransactions();

    if (generation != _generation || _userId != userId) return;

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (page) => state = WalletHistoryState(
        transactions: page.items,
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }

  void reset() {
    _generation++;
    _userId = null;
    state = const WalletHistoryState();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final cursor = state.nextCursor;
    if (cursor == null || _userId == null) return;
    final generation = _generation;
    final userId = _userId!;

    state = state.copyWith(isLoadingMore: true);

    final result = await ref
        .read(walletRepositoryProvider)
        .getTransactions(cursor: cursor);

    if (generation != _generation || _userId != userId) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        error: failure.message,
        nextCursor: state.nextCursor,
      ),
      (page) => state = WalletHistoryState(
        transactions: [...state.transactions, ...page.items],
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }
}

@Riverpod(keepAlive: true)
class ConnectStatus extends _$ConnectStatus {
  int _generation = 0;
  String? _userId;

  @override
  AsyncValue<ConnectStatusEntity?> build() {
    ref.watch(walletRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> load(String userId) async {
    final generation = ++_generation;
    _userId = userId;
    state = const AsyncValue.loading();
    final result = await ref.read(walletRepositoryProvider).getConnectStatus();

    if (generation != _generation || _userId != userId) return;

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (status) => state = AsyncValue.data(status),
    );
  }

  void reset() {
    _generation++;
    _userId = null;
    state = const AsyncValue.data(null);
  }
}

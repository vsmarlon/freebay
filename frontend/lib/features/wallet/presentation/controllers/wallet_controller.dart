import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/repositories/wallet_repository.dart';
import 'package:freebay/features/wallet/data/services/wallet_service.dart';
import 'package:freebay/features/wallet/domain/repositories/i_wallet_repository.dart';
import 'package:freebay/features/wallet/domain/usecases/get_wallet_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_controller.g.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

final walletRepositoryProvider = Provider<IWalletRepository>((ref) {
  return WalletRepository(ref.watch(walletServiceProvider));
});

final getWalletUsecaseProvider = Provider(
  (ref) => GetWalletUsecase(ref.watch(walletRepositoryProvider)),
);

@Riverpod(keepAlive: true)
class Wallet extends _$Wallet {
  @override
  AsyncValue<WalletEntity?> build() {
    ref.watch(getWalletUsecaseProvider);
    return const AsyncValue.loading();
  }

  Future<void> loadWallet() async {
    state = const AsyncValue.loading();
    final result = await ref.read(getWalletUsecaseProvider)();

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (wallet) => state = AsyncValue.data(wallet),
    );
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
  @override
  WalletHistoryState build() {
    ref.watch(walletRepositoryProvider);
    return const WalletHistoryState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(walletRepositoryProvider).getTransactions();

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

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.nextCursor == null) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    final result = await ref
        .read(walletRepositoryProvider)
        .getTransactions(cursor: state.nextCursor);

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
  @override
  AsyncValue<ConnectStatusEntity?> build() {
    ref.watch(walletRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    final result = await ref.read(walletRepositoryProvider).getConnectStatus();

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (status) => state = AsyncValue.data(status),
    );
  }
}

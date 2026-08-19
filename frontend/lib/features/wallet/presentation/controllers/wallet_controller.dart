import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/entities/withdrawal_entity.dart';
import 'package:freebay/features/wallet/data/repositories/wallet_repository.dart';
import 'package:freebay/features/wallet/data/services/wallet_service.dart';
import 'package:freebay/features/wallet/domain/repositories/i_wallet_repository.dart';
import 'package:freebay/features/wallet/domain/usecases/get_wallet_usecase.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
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
  final List<WithdrawalEntity> withdrawals;
  final bool isLoading;
  final String? error;

  const WalletHistoryState({
    this.transactions = const [],
    this.withdrawals = const [],
    this.isLoading = false,
    this.error,
  });

  WalletHistoryState copyWith({
    List<WalletTransactionEntity>? transactions,
    List<WithdrawalEntity>? withdrawals,
    bool? isLoading,
    String? error,
  }) {
    return WalletHistoryState(
      transactions: transactions ?? this.transactions,
      withdrawals: withdrawals ?? this.withdrawals,
      isLoading: isLoading ?? this.isLoading,
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

    final repository = ref.read(walletRepositoryProvider);
    final results = await Future.wait([
      repository.getTransactions(),
      repository.getWithdrawals(),
    ]);

    final transactionsResult =
        results[0] as Either<Failure, List<WalletTransactionEntity>>;
    final withdrawalsResult =
        results[1] as Either<Failure, List<WithdrawalEntity>>;

    final failure =
        transactionsResult.leftOrNull ?? withdrawalsResult.leftOrNull;
    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure.message);
      return;
    }

    state = state.copyWith(
      isLoading: false,
      transactions: transactionsResult.rightOrNull ?? const [],
      withdrawals: withdrawalsResult.rightOrNull ?? const [],
    );
  }
}

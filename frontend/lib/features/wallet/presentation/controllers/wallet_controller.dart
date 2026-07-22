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

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

final walletRepositoryProvider = Provider<IWalletRepository>((ref) {
  return WalletRepository(ref.watch(walletServiceProvider));
});

final getWalletUsecaseProvider = Provider(
  (ref) => GetWalletUsecase(ref.watch(walletRepositoryProvider)),
);

final walletProvider =
    StateNotifierProvider<WalletController, AsyncValue<WalletEntity?>>((ref) {
      return WalletController(ref.watch(getWalletUsecaseProvider));
    });

class WalletController extends StateNotifier<AsyncValue<WalletEntity?>> {
  final GetWalletUsecase _getWalletUsecase;

  WalletController(this._getWalletUsecase) : super(const AsyncValue.loading());

  Future<void> loadWallet() async {
    state = const AsyncValue.loading();
    final result = await _getWalletUsecase();

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

class WalletHistoryNotifier extends StateNotifier<WalletHistoryState> {
  final IWalletRepository _repository;

  WalletHistoryNotifier(this._repository) : super(const WalletHistoryState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    final results = await Future.wait([
      _repository.getTransactions(),
      _repository.getWithdrawals(),
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

final walletHistoryProvider =
    StateNotifierProvider<WalletHistoryNotifier, WalletHistoryState>((ref) {
      return WalletHistoryNotifier(ref.watch(walletRepositoryProvider));
    });

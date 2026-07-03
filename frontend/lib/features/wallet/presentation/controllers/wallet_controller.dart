import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/repositories/wallet_repository.dart';
import 'package:freebay/features/wallet/data/services/wallet_service.dart';
import 'package:freebay/features/wallet/domain/repositories/i_wallet_repository.dart';
import 'package:freebay/features/wallet/domain/usecases/get_wallet_usecase.dart';

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

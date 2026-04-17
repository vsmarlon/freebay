import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/wallet/data/models/wallet_model.dart';
import 'package:freebay/features/wallet/data/services/wallet_service.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

final walletProvider =
    StateNotifierProvider<WalletController, AsyncValue<WalletModel?>>((ref) {
  return WalletController(ref.watch(walletServiceProvider));
});

class WalletController extends StateNotifier<AsyncValue<WalletModel?>> {
  final WalletService _walletService;

  WalletController(this._walletService) : super(const AsyncValue.loading());

  Future<void> loadWallet() async {
    state = const AsyncValue.loading();
    final result = await _walletService.getWallet();

    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (wallet) => state = AsyncValue.data(wallet),
    );
  }
}

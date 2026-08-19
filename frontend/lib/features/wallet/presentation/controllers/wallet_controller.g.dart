// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Wallet)
final walletProvider = WalletProvider._();

final class WalletProvider
    extends $NotifierProvider<Wallet, AsyncValue<WalletEntity?>> {
  WalletProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletHash();

  @$internal
  @override
  Wallet create() => Wallet();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<WalletEntity?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<WalletEntity?>>(value),
    );
  }
}

String _$walletHash() => r'1ae087dc1cb408ac9fd79f4aa06a10d87ca49443';

abstract class _$Wallet extends $Notifier<AsyncValue<WalletEntity?>> {
  AsyncValue<WalletEntity?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<WalletEntity?>, AsyncValue<WalletEntity?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WalletEntity?>, AsyncValue<WalletEntity?>>,
              AsyncValue<WalletEntity?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(WalletHistory)
final walletHistoryProvider = WalletHistoryProvider._();

final class WalletHistoryProvider
    extends $NotifierProvider<WalletHistory, WalletHistoryState> {
  WalletHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletHistoryHash();

  @$internal
  @override
  WalletHistory create() => WalletHistory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletHistoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletHistoryState>(value),
    );
  }
}

String _$walletHistoryHash() => r'dc3788bb64c25a94c67ca062540db53bf56e3a81';

abstract class _$WalletHistory extends $Notifier<WalletHistoryState> {
  WalletHistoryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WalletHistoryState, WalletHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WalletHistoryState, WalletHistoryState>,
              WalletHistoryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

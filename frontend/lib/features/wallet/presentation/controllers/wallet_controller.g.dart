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

String _$walletHash() => r'93f1f87eefa45204e2749a708e3bdb606c9fa308';

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

String _$walletHistoryHash() => r'47d7222c4ffb18465a58e5594770f352c77918c8';

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

@ProviderFor(ConnectStatus)
final connectStatusProvider = ConnectStatusProvider._();

final class ConnectStatusProvider
    extends $NotifierProvider<ConnectStatus, AsyncValue<ConnectStatusEntity?>> {
  ConnectStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectStatusHash();

  @$internal
  @override
  ConnectStatus create() => ConnectStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ConnectStatusEntity?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ConnectStatusEntity?>>(
        value,
      ),
    );
  }
}

String _$connectStatusHash() => r'76104238aca0cd4f818f9e7560de0c1f3f7b4810';

abstract class _$ConnectStatus
    extends $Notifier<AsyncValue<ConnectStatusEntity?>> {
  AsyncValue<ConnectStatusEntity?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ConnectStatusEntity?>,
              AsyncValue<ConnectStatusEntity?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ConnectStatusEntity?>,
                AsyncValue<ConnectStatusEntity?>
              >,
              AsyncValue<ConnectStatusEntity?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

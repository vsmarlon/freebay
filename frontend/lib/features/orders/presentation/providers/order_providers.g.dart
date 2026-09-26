// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrderDetail)
final orderDetailProvider = OrderDetailFamily._();

final class OrderDetailProvider
    extends $NotifierProvider<OrderDetail, OrderDetailState> {
  OrderDetailProvider._({
    required OrderDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderDetailHash();

  @override
  String toString() {
    return r'orderDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OrderDetail create() => OrderDetail();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderDetailHash() => r'9c9e1b1592d7d6aab521f87c90df2d64841d981d';

final class OrderDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          OrderDetail,
          OrderDetailState,
          OrderDetailState,
          OrderDetailState,
          String
        > {
  OrderDetailFamily._()
    : super(
        retry: null,
        name: r'orderDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderDetailProvider call(String orderId) =>
      OrderDetailProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderDetailProvider';
}

abstract class _$OrderDetail extends $Notifier<OrderDetailState> {
  late final _$args = ref.$arg as String;
  String get orderId => _$args;

  OrderDetailState build(String orderId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OrderDetailState, OrderDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OrderDetailState, OrderDetailState>,
              OrderDetailState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(PurchasesList)
final purchasesListProvider = PurchasesListProvider._();

final class PurchasesListProvider
    extends $NotifierProvider<PurchasesList, PurchasesListState> {
  PurchasesListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchasesListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchasesListHash();

  @$internal
  @override
  PurchasesList create() => PurchasesList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchasesListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchasesListState>(value),
    );
  }
}

String _$purchasesListHash() => r'f70d95a996d99ed953578df5b229494291c02f03';

abstract class _$PurchasesList extends $Notifier<PurchasesListState> {
  PurchasesListState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PurchasesListState, PurchasesListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PurchasesListState, PurchasesListState>,
              PurchasesListState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SalesList)
final salesListProvider = SalesListProvider._();

final class SalesListProvider
    extends $NotifierProvider<SalesList, SalesListState> {
  SalesListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesListHash();

  @$internal
  @override
  SalesList create() => SalesList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SalesListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SalesListState>(value),
    );
  }
}

String _$salesListHash() => r'62cd3f9567b5d066bd90ddf77c2c8b9bbdaabaad';

abstract class _$SalesList extends $Notifier<SalesListState> {
  SalesListState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SalesListState, SalesListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SalesListState, SalesListState>,
              SalesListState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

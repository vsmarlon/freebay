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

String _$orderDetailHash() => r'6412a9e209d19f6506cd9d3c36003c1225deb689';

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

String _$purchasesListHash() => r'3d607f6bc10720305122c6cc29495cc1883837d0';

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

String _$salesListHash() => r'a2bbf0e7681928a068574c2715fc66e200be2443';

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

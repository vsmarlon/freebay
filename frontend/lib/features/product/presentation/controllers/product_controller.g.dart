// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProductsFeed)
final productsFeedProvider = ProductsFeedFamily._();

final class ProductsFeedProvider
    extends $NotifierProvider<ProductsFeed, ProductsFeedState> {
  ProductsFeedProvider._({
    required ProductsFeedFamily super.from,
    required GetProductsParams super.argument,
  }) : super(
         retry: null,
         name: r'productsFeedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productsFeedHash();

  @override
  String toString() {
    return r'productsFeedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProductsFeed create() => ProductsFeed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductsFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductsFeedState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductsFeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productsFeedHash() => r'6cd9e5b1274da322f6be83c82b0d77fc039dc56f';

final class ProductsFeedFamily extends $Family
    with
        $ClassFamilyOverride<
          ProductsFeed,
          ProductsFeedState,
          ProductsFeedState,
          ProductsFeedState,
          GetProductsParams
        > {
  ProductsFeedFamily._()
    : super(
        retry: null,
        name: r'productsFeedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductsFeedProvider call(GetProductsParams params) =>
      ProductsFeedProvider._(argument: params, from: this);

  @override
  String toString() => r'productsFeedProvider';
}

abstract class _$ProductsFeed extends $Notifier<ProductsFeedState> {
  late final _$args = ref.$arg as GetProductsParams;
  GetProductsParams get params => _$args;

  ProductsFeedState build(GetProductsParams params);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProductsFeedState, ProductsFeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProductsFeedState, ProductsFeedState>,
              ProductsFeedState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

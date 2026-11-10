// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PaymentCheckout)
final paymentCheckoutProvider = PaymentCheckoutProvider._();

final class PaymentCheckoutProvider
    extends $NotifierProvider<PaymentCheckout, PaymentCheckoutState> {
  PaymentCheckoutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentCheckoutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentCheckoutHash();

  @$internal
  @override
  PaymentCheckout create() => PaymentCheckout();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentCheckoutState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentCheckoutState>(value),
    );
  }
}

String _$paymentCheckoutHash() => r'3da6255b8fc4bc302ce4f0ce1f893af5d413aff9';

abstract class _$PaymentCheckout extends $Notifier<PaymentCheckoutState> {
  PaymentCheckoutState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PaymentCheckoutState, PaymentCheckoutState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PaymentCheckoutState, PaymentCheckoutState>,
              PaymentCheckoutState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

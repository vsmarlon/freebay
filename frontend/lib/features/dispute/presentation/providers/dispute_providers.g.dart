// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DisputeList)
final disputeListProvider = DisputeListProvider._();

final class DisputeListProvider
    extends $NotifierProvider<DisputeList, DisputeListState> {
  DisputeListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'disputeListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$disputeListHash();

  @$internal
  @override
  DisputeList create() => DisputeList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DisputeListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DisputeListState>(value),
    );
  }
}

String _$disputeListHash() => r'a97a31b481778f49655e0eb52eb7361a7cceec82';

abstract class _$DisputeList extends $Notifier<DisputeListState> {
  DisputeListState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DisputeListState, DisputeListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DisputeListState, DisputeListState>,
              DisputeListState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(DisputeDetail)
final disputeDetailProvider = DisputeDetailFamily._();

final class DisputeDetailProvider
    extends $NotifierProvider<DisputeDetail, DisputeDetailState> {
  DisputeDetailProvider._({
    required DisputeDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'disputeDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$disputeDetailHash();

  @override
  String toString() {
    return r'disputeDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DisputeDetail create() => DisputeDetail();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DisputeDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DisputeDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DisputeDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$disputeDetailHash() => r'0de7671232262df1efcbb8e7ba5fe65228814ac7';

final class DisputeDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          DisputeDetail,
          DisputeDetailState,
          DisputeDetailState,
          DisputeDetailState,
          String
        > {
  DisputeDetailFamily._()
    : super(
        retry: null,
        name: r'disputeDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DisputeDetailProvider call(String disputeId) =>
      DisputeDetailProvider._(argument: disputeId, from: this);

  @override
  String toString() => r'disputeDetailProvider';
}

abstract class _$DisputeDetail extends $Notifier<DisputeDetailState> {
  late final _$args = ref.$arg as String;
  String get disputeId => _$args;

  DisputeDetailState build(String disputeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DisputeDetailState, DisputeDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DisputeDetailState, DisputeDetailState>,
              DisputeDetailState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

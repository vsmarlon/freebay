// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FeedTypeSetting)
final feedTypeProvider = FeedTypeSettingProvider._();

final class FeedTypeSettingProvider
    extends $NotifierProvider<FeedTypeSetting, FeedType> {
  FeedTypeSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedTypeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedTypeSettingHash();

  @$internal
  @override
  FeedTypeSetting create() => FeedTypeSetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedType>(value),
    );
  }
}

String _$feedTypeSettingHash() => r'8b23f802bafe98bdacc76e759cb4d3516f235bee';

abstract class _$FeedTypeSetting extends $Notifier<FeedType> {
  FeedType build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FeedType, FeedType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FeedType, FeedType>,
              FeedType,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FeedContentFilterSetting)
final feedContentFilterProvider = FeedContentFilterSettingProvider._();

final class FeedContentFilterSettingProvider
    extends $NotifierProvider<FeedContentFilterSetting, FeedContentFilter> {
  FeedContentFilterSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedContentFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedContentFilterSettingHash();

  @$internal
  @override
  FeedContentFilterSetting create() => FeedContentFilterSetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedContentFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedContentFilter>(value),
    );
  }
}

String _$feedContentFilterSettingHash() =>
    r'f9a278e75970a1b9dddc67dcf1efd449200688aa';

abstract class _$FeedContentFilterSetting extends $Notifier<FeedContentFilter> {
  FeedContentFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FeedContentFilter, FeedContentFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FeedContentFilter, FeedContentFilter>,
              FeedContentFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(Feed)
final feedProvider = FeedProvider._();

final class FeedProvider extends $NotifierProvider<Feed, FeedState> {
  FeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedHash();

  @$internal
  @override
  Feed create() => Feed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedState>(value),
    );
  }
}

String _$feedHash() => r'732c6e9d817383674982c128d520f1d22b77d089';

abstract class _$Feed extends $Notifier<FeedState> {
  FeedState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FeedState, FeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FeedState, FeedState>,
              FeedState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

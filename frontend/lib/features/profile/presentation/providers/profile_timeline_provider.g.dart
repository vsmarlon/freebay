// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_timeline_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileTimeline)
final profileTimelineProvider = ProfileTimelineFamily._();

final class ProfileTimelineProvider
    extends $NotifierProvider<ProfileTimeline, ProfileTimelineState> {
  ProfileTimelineProvider._({
    required ProfileTimelineFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'profileTimelineProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profileTimelineHash();

  @override
  String toString() {
    return r'profileTimelineProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProfileTimeline create() => ProfileTimeline();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileTimelineState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileTimelineState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileTimelineProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profileTimelineHash() => r'bcc6fc42875615cee5b2b3d45671b530d9056d91';

final class ProfileTimelineFamily extends $Family
    with
        $ClassFamilyOverride<
          ProfileTimeline,
          ProfileTimelineState,
          ProfileTimelineState,
          ProfileTimelineState,
          String
        > {
  ProfileTimelineFamily._()
    : super(
        retry: null,
        name: r'profileTimelineProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProfileTimelineProvider call(String userId) =>
      ProfileTimelineProvider._(argument: userId, from: this);

  @override
  String toString() => r'profileTimelineProvider';
}

abstract class _$ProfileTimeline extends $Notifier<ProfileTimelineState> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  ProfileTimelineState build(String userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProfileTimelineState, ProfileTimelineState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileTimelineState, ProfileTimelineState>,
              ProfileTimelineState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

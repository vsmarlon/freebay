// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Notifications)
final notificationsProvider = NotificationsProvider._();

final class NotificationsProvider
    extends
        $NotifierProvider<Notifications, AsyncValue<List<NotificationEntity>>> {
  NotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsHash();

  @$internal
  @override
  Notifications create() => Notifications();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<NotificationEntity>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<NotificationEntity>>>(value),
    );
  }
}

String _$notificationsHash() => r'a1b70fbf60718c7e52a3a496b65a4d0290654940';

abstract class _$Notifications
    extends $Notifier<AsyncValue<List<NotificationEntity>>> {
  AsyncValue<List<NotificationEntity>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<NotificationEntity>>,
              AsyncValue<List<NotificationEntity>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<NotificationEntity>>,
                AsyncValue<List<NotificationEntity>>
              >,
              AsyncValue<List<NotificationEntity>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(UnreadCount)
final unreadCountProvider = UnreadCountProvider._();

final class UnreadCountProvider extends $NotifierProvider<UnreadCount, int> {
  UnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadCountHash();

  @$internal
  @override
  UnreadCount create() => UnreadCount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$unreadCountHash() => r'431e0e007291ea4608d89cc323f467e53372b27c';

abstract class _$UnreadCount extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

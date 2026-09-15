export 'package:freebay/features/profile/presentation/providers/follow_status_provider.dart'
    show
        FollowStateNotifier,
        FollowsInFlightNotifier,
        followStateProvider,
        followStatusProvider,
        followServiceProvider,
        followsInFlightProvider;

class FollowInfo {
  final bool isFollowing;
  final int delta;

  const FollowInfo({this.isFollowing = false, this.delta = 0});
}

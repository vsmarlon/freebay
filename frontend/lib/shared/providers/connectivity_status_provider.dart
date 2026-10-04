import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_status_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<bool> connectivityStatus(Ref ref) async* {
  final connectivity = Connectivity();
  yield _hasConnection(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasConnection);
}

bool _hasConnection(List<ConnectivityResult> results) =>
    results.any((result) => result != ConnectivityResult.none);

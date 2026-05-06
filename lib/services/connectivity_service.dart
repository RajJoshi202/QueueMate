import 'package:connectivity_plus/connectivity_plus.dart';

/// ConnectivityService monitors network connectivity status.
/// Provides both stream-based and one-shot connectivity checks
/// using the connectivity_plus package.
/// NOTE: connectivity_plus 5.0.2 returns a single ConnectivityResult (not a List).
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream that emits true when online, false when offline.
  /// Listens to connectivity changes and maps result to boolean.
  Stream<bool> get isOnlineStream {
    return _connectivity.onConnectivityChanged.map((result) {
      // In connectivity_plus 5.0.2, result is a single ConnectivityResult
      if (result is List) {
        return (result as List).any((r) => r != ConnectivityResult.none);
      }
      return result != ConnectivityResult.none;
    });
  }

  /// Checks current connectivity status.
  /// Returns true if any network connection is available.
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    // Handle both List and single ConnectivityResult
    if (result is List) {
      return (result as List).any((r) => r != ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }
}

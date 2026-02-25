import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitors network connectivity state.
///
/// Exposes a [ValueNotifier<bool>] for widgets to listen to.
class ConnectivityService {
  /// Whether the device currently has internet connectivity.
  final ValueNotifier<bool> isConnected = ValueNotifier(true);

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Start monitoring. Call once at app init.
  Future<void> init() async {
    // Check initial state.
    final results = await _connectivity.checkConnectivity();
    isConnected.value = _hasConnection(results);

    // Listen for changes.
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      isConnected.value = _hasConnection(results);
    });
  }

  /// Dispose monitoring subscription.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    isConnected.dispose();
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }
}

import 'package:flutter/foundation.dart';

/// Global connectivity state.
///
/// Backed by [ConnectivityService], exposed as a [ValueNotifier<bool>].
class ConnectivityNotifier extends ValueNotifier<bool> {
  /// Creates a [ConnectivityNotifier] with the given initial connection
  /// state.
  ConnectivityNotifier(super.isConnected);
}

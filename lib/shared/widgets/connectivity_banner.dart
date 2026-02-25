import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';

/// Offline banner that slides down from below the AppBar when connectivity
/// is lost, and slides back up when restored.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({
    super.key,
    required this.isConnected,
  });

  /// Whether the device is currently connected.
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: AppDurations.emphasis,
      curve: Curves.easeInOut,
      offset: isConnected ? const Offset(0, -1) : Offset.zero,
      child: AnimatedOpacity(
        duration: AppDurations.emphasis,
        opacity: isConnected ? 0.0 : 1.0,
        child: Container(
          width: double.infinity,
          height: 36,
          color: AppColors.error,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off,
                size: 16,
                color: AppColors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                'No internet connection',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.white,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

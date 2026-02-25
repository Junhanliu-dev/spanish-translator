import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/router/route_names.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../onboarding_view_model.dart';

/// Onboarding screen for requesting microphone and camera permissions.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  late final OnboardingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel(
      secureStorage: ServiceLocator.secureStorage,
      settingsService: ServiceLocator.settingsService,
      apiClient: ServiceLocator.apiClient,
    );
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    final micStatus = await Permission.microphone.status;
    final camStatus = await Permission.camera.status;
    _viewModel.micPermissionGranted = micStatus.isGranted;
    _viewModel.cameraPermissionGranted = camStatus.isGranted;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String get _continueLabel {
    if (_viewModel.micPermissionGranted && _viewModel.cameraPermissionGranted) {
      return 'Continue';
    }
    final denied = <String>[];
    if (!_viewModel.micPermissionGranted) denied.add('microphone');
    if (!_viewModel.cameraPermissionGranted) denied.add('camera');
    return 'Continue without ${denied.join(' & ')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () =>
                  context.go(RoutePaths.onboardingLanguagePrefs),
            ),
            title: const Text('3/4'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: AppColors.stone200,
                    color: AppColors.terracotta,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: AppSpacing.xl3),
                      children: [
                        Text(
                          'App Permissions',
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'To translate speech and menus, LinguaViaje needs:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.stone600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl2),

                        // Microphone permission.
                        _PermissionRow(
                          icon: Icons.mic,
                          title: 'Microphone',
                          description: 'For speech translation',
                          isGranted: _viewModel.micPermissionGranted,
                          onRequest: () =>
                              _viewModel.requestMicPermission(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Camera permission.
                        _PermissionRow(
                          icon: Icons.camera_alt,
                          title: 'Camera',
                          description: 'For photographing menus',
                          isGranted: _viewModel.cameraPermissionGranted,
                          onRequest: () =>
                              _viewModel.requestCameraPermission(),
                        ),

                        const SizedBox(height: AppSpacing.xl3),
                        Text(
                          'You can change these anytime in your '
                          "phone's Settings.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.stone500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.go(RoutePaths.onboardingTutorial),
                      child: Text(_continueLabel),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.stone900 : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDark ? AppColors.stone700 : AppColors.stone200),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppColors.terracotta),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.stone500,
                  ),
                ),
              ],
            ),
          ),
          if (isGranted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  'Granted',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            )
          else
            TextButton(
              onPressed: onRequest,
              child: const Text('Allow Access'),
            ),
        ],
      ),
    );
  }
}

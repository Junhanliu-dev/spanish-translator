import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/router/route_names.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/connectivity_banner.dart';
import '../../../shared/widgets/language_toggle_pill.dart';
import '../home_view_model.dart';
import 'widgets/feature_card.dart';
import 'widgets/greeting_banner.dart';
import 'widgets/recent_translations_section.dart';

/// The main home screen with feature cards and recent translations.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      historyRepo: ServiceLocator.historyRepo,
      secureStorage: ServiceLocator.secureStorage,
      settingsService: ServiceLocator.settingsService,
    );
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onSpeechTap() async {
    if (!_viewModel.hasApiKey) {
      _showNoApiKeySheet();
      return;
    }
    if (!await _ensurePermission(Permission.microphone, 'Microphone')) return;
    if (mounted) context.push(RoutePaths.speech);
  }

  void _onPhotoTap() async {
    if (!_viewModel.hasApiKey) {
      _showNoApiKeySheet();
      return;
    }
    if (!await _ensurePermission(Permission.camera, 'Camera')) return;
    if (mounted) context.push(RoutePaths.photo);
  }

  void _onTextTap() {
    if (!_viewModel.hasApiKey) {
      _showNoApiKeySheet();
      return;
    }
    context.push(RoutePaths.text);
  }

  /// Requests the given [permission] if not already granted.
  ///
  /// Returns true if the permission is granted, false otherwise. Shows a
  /// dialog to guide the user to Settings on permanent denial.
  Future<bool> _ensurePermission(
    Permission permission,
    String permissionName,
  ) async {
    if (await permission.isGranted) return true;
    final status = await permission.request();
    if (status.isGranted) {
      _viewModel.checkPermissions();
      return true;
    }
    if (mounted) _showPermissionDialog(permissionName);
    return false;
  }

  void _showNoApiKeySheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stone300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(
                Icons.vpn_key_outlined,
                size: 48,
                color: AppColors.terracotta,
              ),
              const SizedBox(height: 16),
              Text(
                'API Key Required',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'LinguaViaje uses OpenAI\'s AI for translation. '
                'You\'ll need an API key to use this feature.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.stone600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(RoutePaths.settings);
                },
                child: const Text('Set Up API Key'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(RoutePaths.settingsApiKeyGuide);
                },
                child: const Text('Learn More'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showPermissionDialog(String permission) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('$permission Access Required'),
          content: Text(
            'LinguaViaje needs access to your ${permission.toLowerCase()} '
            'to translate. Please enable it in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('LinguaViaje'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: LanguageTogglePill(
                  selected: ServiceLocator.languagePrefs.targetLanguage,
                  onChanged: (lang) {
                    ServiceLocator.languagePrefs.targetLanguage = lang;
                  },
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable:
                    ServiceLocator.connectivityService.isConnected,
                builder: (context, isConnected, _) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Tooltip(
                      message: isConnected
                          ? 'Connected to internet'
                          : 'No internet connection',
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppColors.success
                              : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable:
                    ServiceLocator.connectivityService.isConnected,
                builder: (context, isConnected, _) {
                  return ConnectivityBanner(isConnected: isConnected);
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _viewModel.refresh,
                  child: ListView(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.lg,
                      bottom: AppSpacing.xl6,
                    ),
                    children: [
                      // No API key banner.
                      if (!_viewModel.hasApiKey)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageHorizontal,
                            0,
                            AppSpacing.pageHorizontal,
                            AppSpacing.lg,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.saffronFaint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.saffron),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.settings,
                                  color: AppColors.terracotta,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Set up your API key to translate',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.go(RoutePaths.settings),
                                  child: const Text('Set Up Now'),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Greeting banner.
                      if (_viewModel.showGreeting) ...[
                        GreetingBanner(
                          onDismiss: _viewModel.dismissGreeting,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Section: Translate.
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                        ),
                        child: Text(
                          'Translate',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.stone500,
                                  ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Feature cards.
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                        ),
                        child: FeatureCard(
                          icon: Icons.mic,
                          title: 'Speech Translation',
                          subtitle: 'Speak and hear it',
                          isEnabled: _viewModel.hasMicPermission,
                          disabledSubtitle: 'Tap to enable microphone',
                          onTap: _onSpeechTap,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                        ),
                        child: FeatureCard(
                          icon: Icons.camera_alt,
                          title: 'Photo Translation',
                          subtitle: 'Photograph a menu',
                          isEnabled: _viewModel.hasCameraPermission,
                          disabledSubtitle: 'Tap to enable camera',
                          onTap: _onPhotoTap,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                        ),
                        child: FeatureCard(
                          icon: Icons.text_fields,
                          title: 'Text Translation',
                          subtitle: 'Paste or type text',
                          onTap: _onTextTap,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sectionSpacing),

                      // Recent translations.
                      RecentTranslationsSection(
                        translations: _viewModel.recentTranslations,
                        onViewAll: () => context.go(RoutePaths.history),
                        onTap: (_) => context.go(RoutePaths.history),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

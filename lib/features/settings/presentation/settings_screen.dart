import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/connectivity_banner.dart';
import '../settings_view_model.dart';
import 'widgets/api_key_section.dart';
import 'widgets/appearance_section.dart';
import 'widgets/language_prefs_section.dart';

/// The Settings screen with API key, language, theme, and about sections.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel(
      secureStorage: ServiceLocator.secureStorage,
      settingsService: ServiceLocator.settingsService,
      apiClient: ServiceLocator.apiClient,
      languagePrefs: ServiceLocator.languagePrefs,
      themeNotifier: ServiceLocator.themeNotifier,
    );
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.pageVertical,
                  ),
                  children: [
                    // API KEY section.
                    _SectionHeader(title: 'API KEY'),
                    _SectionCard(
                      child: ApiKeySection(
                        viewModel: _viewModel,
                        onNavigateToGuide: () =>
                            context.push(RoutePaths.settingsApiKeyGuide),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // LANGUAGES section.
                    _SectionHeader(title: 'LANGUAGES'),
                    _SectionCard(
                      child: LanguagePrefsSection(viewModel: _viewModel),
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // APPEARANCE section.
                    _SectionHeader(title: 'APPEARANCE'),
                    _SectionCard(
                      child: AppearanceSection(viewModel: _viewModel),
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // ABOUT section.
                    _SectionHeader(title: 'ABOUT'),
                    _SectionCard(
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('LinguaViaje'),
                            trailing: Text(
                              'v1.0.0',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: AppColors.stone400,
                            ),
                            onTap: () {
                              // Open privacy policy URL.
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Open Source Licenses'),
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: AppColors.stone400,
                            ),
                            onTap: () {
                              showLicensePage(
                                context: context,
                                applicationName: 'LinguaViaje',
                                applicationVersion: '1.0.0',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl6),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.stone500,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.stone900 : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.stone700 : AppColors.stone200,
        ),
      ),
      child: child,
    );
  }
}

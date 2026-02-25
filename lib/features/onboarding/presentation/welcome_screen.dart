import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../onboarding_view_model.dart';

/// Welcome screen: first screen of the onboarding flow.
///
/// Shows the app name, tagline, language selector, and "Get Started" button.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final OnboardingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel(
      secureStorage: ServiceLocator.secureStorage,
      settingsService: ServiceLocator.settingsService,
      apiClient: ServiceLocator.apiClient,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // App icon.
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.terracottaFaint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.translate,
                      size: 40,
                      color: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // Title.
                  Text(
                    'LinguaViaje',
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Subtitle.
                  Text(
                    'Order food in Spain\nlike a local',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.stone600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Mandarin subtitle.
                  Text(
                    '\u70b9\u83dc\u50cf\u5f53\u5730\u4eba\u4e00\u6837',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.stone500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Language selector.
                  Text(
                    'App language:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.stone500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'en',
                          label: Text('English'),
                        ),
                        ButtonSegment(
                          value: 'zh',
                          label: Text('\u4e2d\u6587'),
                        ),
                      ],
                      selected: {_viewModel.selectedLocale},
                      onSelectionChanged: (selection) {
                        _viewModel.setLocale(selection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        selectedForegroundColor: AppColors.white,
                        selectedBackgroundColor: AppColors.terracotta,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl3),

                  // Get Started button.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.go(RoutePaths.onboardingApiKey),
                      child: const Text('Get Started'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl5),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

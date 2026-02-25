import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../onboarding_view_model.dart';

/// Onboarding API key entry screen.
///
/// Validates the key with a lightweight API call before advancing.
class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  late final OnboardingViewModel _viewModel;
  final _controller = TextEditingController();
  bool _obscureText = true;

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
    _controller.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _validateAndContinue() async {
    final success = await _viewModel.validateAndSaveKey(_controller.text);
    if (success && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go(RoutePaths.onboardingLanguagePrefs);
    }
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
              onPressed: () => context.go(RoutePaths.onboardingWelcome),
            ),
            title: const Text('1/4'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
              ),
              child: Column(
                children: [
                  // Progress bar.
                  LinearProgressIndicator(
                    value: 0.25,
                    backgroundColor: AppColors.stone200,
                    color: AppColors.terracotta,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: AppSpacing.xl3),
                      children: [
                        // Icon.
                        Icon(
                          Icons.vpn_key,
                          size: 48,
                          color: AppColors.terracotta,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Title.
                        Text(
                          'Set Up Your API Key',
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Description.
                        Text(
                          "This app uses OpenAI's AI to translate menus and "
                          "conversations. You'll need an API key.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.stone600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Typical usage: \$0.50\u20132.00/day',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.stone500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl2),

                        // API key input.
                        TextFormField(
                          controller: _controller,
                          obscureText: _obscureText,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Paste your API key',
                            prefixText: 'sk-',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                                color: AppColors.stone500,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscureText = !_obscureText,
                                );
                              },
                            ),
                            errorText: _viewModel.keyValidationError,
                          ),
                        ),

                        // Success indicator.
                        if (_viewModel.keyValidated) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'API key validated',
                                style:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: AppSpacing.md),

                        // Guide link.
                        TextButton(
                          onPressed: () => context.push(
                            RoutePaths.onboardingApiKeyGuide,
                          ),
                          child: Text(
                            'How do I get one? \u2192',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom buttons.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _viewModel.isValidatingKey
                          ? null
                          : _validateAndContinue,
                      child: _viewModel.isValidatingKey
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Validate & Continue'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      _viewModel.skipApiKey();
                      context.go(RoutePaths.onboardingLanguagePrefs);
                    },
                    child: Text(
                      'Skip for now \u2014 you can add this in Settings later',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.stone400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

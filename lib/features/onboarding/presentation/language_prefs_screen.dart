import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/target_language.dart';
import '../onboarding_view_model.dart';

/// Onboarding screen for source and target language selection.
class LanguagePrefsScreen extends StatefulWidget {
  const LanguagePrefsScreen({super.key});

  @override
  State<LanguagePrefsScreen> createState() => _LanguagePrefsScreenState();
}

class _LanguagePrefsScreenState extends State<LanguagePrefsScreen> {
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
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => context.go(RoutePaths.onboardingApiKey),
            ),
            title: const Text('2/4'),
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
                    value: 0.5,
                    backgroundColor: AppColors.stone200,
                    color: AppColors.terracotta,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: AppSpacing.xl3),
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 48,
                          color: AppColors.bilbaoBlue,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Your Language Preferences',
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl2),

                        // Source language.
                        Text(
                          'What language do you speak?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.stone600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _LanguageOption<AppLanguage>(
                          label: 'English',
                          value: AppLanguage.english,
                          selected: _viewModel.selectedSourceLanguage,
                          onSelected: _viewModel.setSourceLanguage,
                        ),
                        _LanguageOption<AppLanguage>(
                          label: 'Mandarin (Simplified)',
                          value: AppLanguage.mandarin,
                          selected: _viewModel.selectedSourceLanguage,
                          onSelected: _viewModel.setSourceLanguage,
                        ),

                        const Divider(height: 32),

                        // Target language.
                        Text(
                          'Default target language',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.stone600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _LanguageOption<TargetLanguage>(
                          label: 'Spanish (most of Spain)',
                          value: TargetLanguage.spanish,
                          selected: _viewModel.selectedTargetLanguage,
                          onSelected: _viewModel.setTargetLanguage,
                        ),
                        _LanguageOption<TargetLanguage>(
                          label: 'Basque (Basque Country)',
                          value: TargetLanguage.basque,
                          selected: _viewModel.selectedTargetLanguage,
                          onSelected: _viewModel.setTargetLanguage,
                        ),

                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'You can change this anytime in Settings or on each screen.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.stone500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _viewModel.saveLanguagePrefs();
                        context.go(RoutePaths.onboardingPermissions);
                      },
                      child: const Text('Continue'),
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

class _LanguageOption<T> extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final T value;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppColors.terracotta : AppColors.stone400,
      ),
      title: Text(label),
      onTap: () => onSelected(value),
    );
  }
}

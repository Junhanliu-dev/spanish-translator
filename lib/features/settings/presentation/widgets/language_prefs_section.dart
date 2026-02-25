import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/app_language.dart';
import '../../../../shared/models/target_language.dart';
import '../../settings_view_model.dart';

/// Settings section for source and target language preferences.
class LanguagePrefsSection extends StatelessWidget {
  const LanguagePrefsSection({
    super.key,
    required this.viewModel,
  });

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source language.
        Text('Your Language', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<AppLanguage>(
          segments: const [
            ButtonSegment(
              value: AppLanguage.english,
              label: Text('English'),
            ),
            ButtonSegment(
              value: AppLanguage.mandarin,
              label: Text('Mandarin'),
            ),
          ],
          selected: {viewModel.sourceLanguage},
          onSelectionChanged: (selection) {
            viewModel.setSourceLanguage(selection.first);
          },
          style: _segmentedStyle(theme),
        ),
        const SizedBox(height: AppSpacing.xl2),

        // Target language.
        Text('Default Translation Target', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<TargetLanguage>(
          segments: const [
            ButtonSegment(
              value: TargetLanguage.spanish,
              label: Text('Spanish'),
            ),
            ButtonSegment(
              value: TargetLanguage.basque,
              label: Text('Basque'),
            ),
          ],
          selected: {viewModel.targetLanguage},
          onSelectionChanged: (selection) {
            viewModel.setTargetLanguage(selection.first);
          },
          style: _segmentedStyle(theme),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'You can always switch between Spanish and Basque during any translation.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.stone500,
          ),
        ),
      ],
    );
  }

  ButtonStyle _segmentedStyle(ThemeData theme) {
    return SegmentedButton.styleFrom(
      selectedForegroundColor: AppColors.white,
      selectedBackgroundColor: theme.colorScheme.primary,
    );
  }
}

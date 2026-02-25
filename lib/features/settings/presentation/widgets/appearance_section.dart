import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../settings_view_model.dart';

/// Settings section for theme and app language appearance preferences.
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({
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
        // App language.
        Text('App Language', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'en', label: Text('English')),
            ButtonSegment(value: 'zh', label: Text('\u4e2d\u6587')),
          ],
          selected: {viewModel.appLocale},
          onSelectionChanged: (selection) {
            viewModel.setAppLocale(selection.first);
          },
          style: _segmentedStyle(theme),
        ),
        const SizedBox(height: AppSpacing.xl2),

        // Theme.
        Text('Theme', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.settings_suggest, size: 18),
            ),
          ],
          selected: {viewModel.themeMode},
          onSelectionChanged: (selection) {
            viewModel.setThemeMode(selection.first);
          },
          style: _segmentedStyle(theme),
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

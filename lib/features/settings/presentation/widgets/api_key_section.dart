import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../settings_view_model.dart';

/// Settings section for API key display, editing, and validation.
class ApiKeySection extends StatefulWidget {
  const ApiKeySection({
    super.key,
    required this.viewModel,
    required this.onNavigateToGuide,
  });

  final SettingsViewModel viewModel;
  final VoidCallback onNavigateToGuide;

  @override
  State<ApiKeySection> createState() => _ApiKeySectionState();
}

class _ApiKeySectionState extends State<ApiKeySection> {
  final _controller = TextEditingController();
  bool _obscureText = true;

  SettingsViewModel get vm => widget.viewModel;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    final Color dotColor;
    final String statusText;

    switch (vm.apiKeyStatus) {
      case ApiKeyStatus.valid:
        dotColor = AppColors.success;
        statusText = vm.apiKeyStatusMessage ?? 'Valid';
      case ApiKeyStatus.invalid:
        dotColor = AppColors.error;
        statusText = vm.apiKeyStatusMessage ?? 'Invalid';
      case ApiKeyStatus.unverified:
        dotColor = AppColors.warning;
        statusText = vm.apiKeyStatusMessage ?? 'Unverified';
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(color: dotColor),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!vm.hasApiKey && !vm.isEditing) {
      return _buildNoKeyState(theme);
    }

    if (vm.isEditing) {
      return _buildEditState(theme);
    }

    return _buildDisplayState(theme);
  }

  Widget _buildNoKeyState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No API key configured',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
        ),
        const SizedBox(height: 4),
        Text(
          'Translation features are disabled until you add a key.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.stone500,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: () => vm.toggleEditing(),
          child: const Text('Enter API Key'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: widget.onNavigateToGuide,
          child: Text(
            'How do I get one? \u2192',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OpenAI API Key',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          vm.maskedApiKey ?? '',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatusIndicator(theme),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            TextButton(
              onPressed: () => vm.toggleEditing(),
              child: const Text('Change'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: vm.isValidating ? null : () => vm.verifyApiKey(),
              child: vm.isValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Verify',
                      style: TextStyle(color: AppColors.stone600),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OpenAI API Key', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          obscureText: _obscureText,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'sk-\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'
                '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: AppColors.stone500,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
          ),
        ),
        if (vm.apiKeyStatus == ApiKeyStatus.invalid &&
            vm.apiKeyStatusMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            vm.apiKeyStatusMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: vm.isValidating
                    ? null
                    : () => vm.saveApiKey(_controller.text),
                child: vm.isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                _controller.clear();
                vm.toggleEditing();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: widget.onNavigateToGuide,
          child: Text(
            'How do I get one? \u2192',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

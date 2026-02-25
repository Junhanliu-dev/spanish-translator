import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Step-by-step guide for obtaining an OpenAI API key.
///
/// Used both in settings (/settings/api-key-guide) and onboarding
/// (/onboarding/api-key-guide).
class ApiKeyGuideScreen extends StatelessWidget {
  const ApiKeyGuideScreen({super.key});

  static const _openAiUrl = 'https://platform.openai.com';

  Future<void> _openUrl() async {
    final uri = Uri.parse(_openAiUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get an API Key')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: [
          const SizedBox(height: AppSpacing.lg),
          _StepCard(
            step: 1,
            title: 'Create an OpenAI account',
            description:
                'Go to platform.openai.com and create a free account.',
            action: TextButton.icon(
              onPressed: _openUrl,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open in Browser'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _StepCard(
            step: 2,
            title: 'Navigate to API Keys',
            description:
                'In your account settings, find the "API Keys" section '
                'under the sidebar menu.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _StepCard(
            step: 3,
            title: 'Create a new secret key',
            description:
                'Click "Create new secret key" and copy the key that '
                'appears. You will not be able to see it again.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _StepCard(
            step: 4,
            title: 'Paste it in the app',
            description:
                'Come back here and paste your key to start translating.',
          ),
          const SizedBox(height: AppSpacing.xl3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I have my key \u2014 Go Back'),
          ),
          const SizedBox(height: AppSpacing.xl3),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    this.action,
  });

  final int step;
  final String title;
  final String description;
  final Widget? action;

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
          color: isDark ? AppColors.stone700 : AppColors.stone200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.stone600,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: action,
            ),
          ],
        ],
      ),
    );
  }
}

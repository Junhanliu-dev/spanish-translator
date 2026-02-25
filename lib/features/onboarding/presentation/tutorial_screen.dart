import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../onboarding_view_model.dart';

/// 3-page tutorial shown at the end of onboarding.
///
/// Explains Speech, Photo, and Text features with animated illustrations.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late final OnboardingViewModel _viewModel;
  late final PageController _pageController;

  static const _pages = [
    _TutorialPage(
      icon: Icons.mic,
      title: 'Speak to Translate',
      description:
          'Tap the mic button and speak. '
          "We'll translate it instantly.",
    ),
    _TutorialPage(
      icon: Icons.camera_alt,
      title: 'Photograph Menus',
      description:
          'Point your camera at a menu and get every item translated '
          'with descriptions.',
    ),
    _TutorialPage(
      icon: Icons.text_fields,
      title: 'Type or Paste Text',
      description:
          'Paste text from anywhere, or type it in. '
          'Get translations with context and pronunciation.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel(
      secureStorage: ServiceLocator.secureStorage,
      settingsService: ServiceLocator.settingsService,
      apiClient: ServiceLocator.apiClient,
    );
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await _viewModel.completeOnboarding();
    if (mounted) context.go(RoutePaths.home);
  }

  void _nextPage() {
    if (_viewModel.tutorialPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final isLastPage = _viewModel.tutorialPage == _pages.length - 1;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('4/4'),
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
                    value: 1.0,
                    backgroundColor: AppColors.stone200,
                    color: AppColors.terracotta,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _pages.length,
                      onPageChanged: _viewModel.setTutorialPage,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return _TutorialPageView(page: page);
                      },
                    ),
                  ),

                  // Page dots.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _viewModel.tutorialPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 10 : 8,
                        height: isActive ? 10 : 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.terracotta
                              : AppColors.stone300,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: AppSpacing.xl2),

                  // Buttons.
                  Row(
                    children: [
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.stone500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(140, 52),
                        ),
                        child: Text(
                          isLastPage ? 'Start Translating!' : 'Next \u2192',
                        ),
                      ),
                    ],
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

class _TutorialPage {
  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _TutorialPageView extends StatelessWidget {
  const _TutorialPageView({required this.page});

  final _TutorialPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated illustration area.
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.terracottaFaint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            page.icon,
            size: 56,
            color: AppColors.terracotta,
          ),
        ),
        const SizedBox(height: AppSpacing.xl3),

        Text(
          page.title,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            page.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.stone600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

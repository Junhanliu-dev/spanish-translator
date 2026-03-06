import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/discover/presentation/discover_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/api_key_screen.dart';
import '../../features/onboarding/presentation/language_prefs_screen.dart';
import '../../features/onboarding/presentation/permissions_screen.dart';
import '../../features/onboarding/presentation/tutorial_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/photo/presentation/photo_capture_screen.dart';
import '../../features/photo/presentation/photo_preview_screen.dart';
import '../../features/photo/presentation/photo_results_screen.dart';
import '../../features/settings/presentation/api_key_guide_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/speech/presentation/speech_screen.dart';
import '../../features/text/presentation/text_translation_screen.dart';
import 'route_names.dart';

/// Creates the application [GoRouter] configuration.
GoRouter createRouter({
  required bool onboardingComplete,
}) {
  var onboardingDone = onboardingComplete;

  return GoRouter(
    initialLocation:
        onboardingDone ? RoutePaths.home : RoutePaths.onboardingWelcome,
    redirect: (context, state) {
      // Once the user navigates to /home, onboarding is done for this session.
      if (state.matchedLocation == RoutePaths.home) {
        onboardingDone = true;
      }
      if (!onboardingDone &&
          !state.matchedLocation.startsWith('/onboarding')) {
        return RoutePaths.onboardingWelcome;
      }
      return null;
    },
    routes: [
      // --- Onboarding routes (no bottom nav) ---
      GoRoute(
        path: RoutePaths.onboardingWelcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingApiKey,
        builder: (context, state) => const ApiKeyScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingApiKeyGuide,
        builder: (context, state) => const ApiKeyGuideScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingLanguagePrefs,
        builder: (context, state) => const LanguagePrefsScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingPermissions,
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingTutorial,
        builder: (context, state) => const TutorialScreen(),
      ),

      // --- Shell route with persistent bottom navigation ---
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.discover,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoverScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.history,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'api-key-guide',
                builder: (context, state) => const ApiKeyGuideScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Full-screen routes (no bottom nav) ---
      GoRoute(
        path: RoutePaths.speech,
        builder: (context, state) => const SpeechScreen(),
      ),
      GoRoute(
        path: RoutePaths.photo,
        builder: (context, state) => const PhotoCaptureScreen(),
      ),
      GoRoute(
        path: RoutePaths.photoPreview,
        builder: (context, state) {
          final imagePath = state.extra as String? ?? '';
          return PhotoPreviewScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: RoutePaths.photoResults,
        builder: (context, state) {
          final imagePath = state.extra as String? ?? '';
          return PhotoResultsScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: RoutePaths.text,
        builder: (context, state) => const TextTranslationScreen(),
      ),
    ],
  );
}

/// The shell that provides persistent bottom navigation.
class _AppShell extends StatefulWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;

  static const _tabs = [
    RoutePaths.home,
    RoutePaths.discover,
    RoutePaths.history,
    RoutePaths.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) {
        _currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index != _currentIndex) {
            context.go(_tabs[index]);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

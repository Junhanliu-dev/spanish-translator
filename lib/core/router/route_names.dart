/// Route path constants for the entire application.
class RoutePaths {
  RoutePaths._();

  // Shell routes (bottom nav)
  static const String home = '/home';
  static const String discover = '/discover';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String settingsApiKeyGuide = '/settings/api-key-guide';

  // Full-screen feature routes
  static const String speech = '/speech';
  static const String photo = '/photo';
  static const String photoPreview = '/photo/preview';
  static const String photoResults = '/photo/results';
  static const String text = '/text';

  // Onboarding routes
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingApiKey = '/onboarding/api-key';
  static const String onboardingApiKeyGuide = '/onboarding/api-key-guide';
  static const String onboardingLanguagePrefs = '/onboarding/language-prefs';
  static const String onboardingPermissions = '/onboarding/permissions';
  static const String onboardingTutorial = '/onboarding/tutorial';
}

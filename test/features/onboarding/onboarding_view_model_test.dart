import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_viaje/core/api/openai_client.dart';
import 'package:lingua_viaje/core/storage/secure_storage_service.dart';
import 'package:lingua_viaje/core/storage/settings_service.dart';
import 'package:lingua_viaje/features/onboarding/onboarding_view_model.dart';
import 'package:lingua_viaje/shared/models/app_language.dart';
import 'package:lingua_viaje/shared/models/target_language.dart';
import 'package:mocktail/mocktail.dart';

// --- Mocks ---

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSettingsService extends Mock implements SettingsService {}

class MockOpenAIClient extends Mock implements OpenAIClient {}

void main() {
  late MockSecureStorageService mockSecureStorage;
  late MockSettingsService mockSettingsService;
  late MockOpenAIClient mockApiClient;

  setUp(() {
    mockSecureStorage = MockSecureStorageService();
    mockSettingsService = MockSettingsService();
    mockApiClient = MockOpenAIClient();
  });

  OnboardingViewModel createViewModel() {
    return OnboardingViewModel(
      secureStorage: mockSecureStorage,
      settingsService: mockSettingsService,
      apiClient: mockApiClient,
    );
  }

  group('OnboardingViewModel', () {
    test('initial state has correct defaults', () {
      final vm = createViewModel();

      expect(vm.currentStep, 0);
      expect(vm.apiKeyInput, isNull);
      expect(vm.isValidatingKey, isFalse);
      expect(vm.keyValidationError, isNull);
      expect(vm.keyValidated, isFalse);
      expect(vm.selectedSourceLanguage, AppLanguage.english);
      expect(vm.selectedTargetLanguage, TargetLanguage.spanish);
      expect(vm.selectedLocale, 'en');
      expect(vm.micPermissionGranted, isFalse);
      expect(vm.cameraPermissionGranted, isFalse);
      expect(vm.tutorialPage, 0);
    });

    group('validateAndSaveKey()', () {
      test('rejects keys that do not start with sk-', () async {
        final vm = createViewModel();

        final result = await vm.validateAndSaveKey('pk-abcdefghijk1234567890');

        expect(result, isFalse);
        expect(vm.keyValidationError,
            'API keys start with sk- and are 50+ characters');
        expect(vm.keyValidated, isFalse);
      });

      test('rejects keys shorter than 20 characters', () async {
        final vm = createViewModel();

        final result = await vm.validateAndSaveKey('sk-short');

        expect(result, isFalse);
        expect(vm.keyValidationError,
            'API keys start with sk- and are 50+ characters');
        expect(vm.keyValidated, isFalse);
      });

      test('rejects key with sk- prefix but under 20 chars', () async {
        final vm = createViewModel();

        final result = await vm.validateAndSaveKey('sk-1234567890');

        expect(result, isFalse);
        expect(vm.keyValidationError, isNotNull);
        expect(vm.keyValidated, isFalse);
      });

      test('notifies listeners on format validation failure', () async {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        await vm.validateAndSaveKey('bad-key');

        expect(notified, isTrue);
      });

      test('sets isValidatingKey during validation', () async {
        const validKey = 'sk-proj-abcdefghijk1234567890abcdefghijk';

        when(() => mockApiClient.validateApiKey())
            .thenAnswer((_) async => true);
        when(() => mockSecureStorage.setApiKey(validKey))
            .thenAnswer((_) async {});

        final vm = createViewModel();
        final states = <bool>[];
        vm.addListener(() => states.add(vm.isValidatingKey));

        await vm.validateAndSaveKey(validKey);

        // Should have been true at some point, then false.
        expect(states, contains(true));
        expect(states.last, isFalse);
      });

      test('persists key only after successful validation', () async {
        const validKey = 'sk-proj-abcdefghijk1234567890abcdefghijk';

        when(() => mockApiClient.validateApiKey())
            .thenAnswer((_) async => true);
        when(() => mockSecureStorage.setApiKey(validKey))
            .thenAnswer((_) async {});

        final vm = createViewModel();
        final result = await vm.validateAndSaveKey(validKey);

        expect(result, isTrue);
        expect(vm.keyValidated, isTrue);
        expect(vm.apiKeyInput, validKey);
        expect(vm.isValidatingKey, isFalse);
        expect(vm.keyValidationError, isNull);

        // Verify key was persisted.
        verify(() => mockSecureStorage.setApiKey(validKey)).called(1);
        // Verify API client received the key.
        verify(() => mockApiClient.updateApiKey(validKey)).called(1);
      });

      test('does not persist key when validation returns false', () async {
        const validKey = 'sk-proj-abcdefghijk1234567890abcdefghijk';

        when(() => mockApiClient.validateApiKey())
            .thenAnswer((_) async => false);

        final vm = createViewModel();
        final result = await vm.validateAndSaveKey(validKey);

        expect(result, isFalse);
        expect(vm.keyValidated, isFalse);
        expect(vm.keyValidationError,
            "Key didn't work \u2014 check it and try again");
        expect(vm.isValidatingKey, isFalse);

        // Should NOT persist.
        verifyNever(() => mockSecureStorage.setApiKey(any()));
        // Should clear the key from the client.
        verify(() => mockApiClient.updateApiKey('')).called(1);
      });

      test('clears API key on validation exception', () async {
        const validKey = 'sk-proj-abcdefghijk1234567890abcdefghijk';

        when(() => mockApiClient.validateApiKey())
            .thenThrow(Exception('Network error'));

        final vm = createViewModel();
        final result = await vm.validateAndSaveKey(validKey);

        expect(result, isFalse);
        expect(vm.keyValidated, isFalse);
        expect(vm.keyValidationError,
            "Couldn't verify key. Please check your connection.");
        expect(vm.isValidatingKey, isFalse);

        // Should NOT persist.
        verifyNever(() => mockSecureStorage.setApiKey(any()));
        // Should clear the key from the client.
        verify(() => mockApiClient.updateApiKey('')).called(1);
      });

      test('clears previous error before starting validation', () async {
        const validKey = 'sk-proj-abcdefghijk1234567890abcdefghijk';

        when(() => mockApiClient.validateApiKey())
            .thenAnswer((_) async => true);
        when(() => mockSecureStorage.setApiKey(validKey))
            .thenAnswer((_) async {});

        final vm = createViewModel();

        // First: fail with bad format to set an error.
        await vm.validateAndSaveKey('bad');
        expect(vm.keyValidationError, isNotNull);

        // Second: valid key should clear previous error.
        String? errorDuringValidation;
        vm.addListener(() {
          if (vm.isValidatingKey) {
            errorDuringValidation = vm.keyValidationError;
          }
        });

        await vm.validateAndSaveKey(validKey);

        expect(errorDuringValidation, isNull);
        expect(vm.keyValidationError, isNull);
      });
    });

    group('skipApiKey()', () {
      test('resets key state without persisting', () {
        final vm = createViewModel();
        vm.keyValidated = true;
        vm.apiKeyInput = 'sk-something';

        vm.skipApiKey();

        expect(vm.keyValidated, isFalse);
        expect(vm.apiKeyInput, isNull);
      });
    });

    group('setSourceLanguage()', () {
      test('updates language and notifies', () {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.setSourceLanguage(AppLanguage.mandarin);

        expect(vm.selectedSourceLanguage, AppLanguage.mandarin);
        expect(notified, isTrue);
      });
    });

    group('setTargetLanguage()', () {
      test('updates language and notifies', () {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.setTargetLanguage(TargetLanguage.basque);

        expect(vm.selectedTargetLanguage, TargetLanguage.basque);
        expect(notified, isTrue);
      });
    });

    group('setLocale()', () {
      test('updates locale, persists, and notifies', () {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.setLocale('zh');

        expect(vm.selectedLocale, 'zh');
        expect(notified, isTrue);
        verify(() => mockSettingsService.setAppLocale('zh')).called(1);
      });
    });

    group('saveLanguagePrefs()', () {
      test('persists both source and target language', () {
        final vm = createViewModel();
        vm.setSourceLanguage(AppLanguage.mandarin);
        vm.setTargetLanguage(TargetLanguage.basque);

        vm.saveLanguagePrefs();

        verify(() =>
            mockSettingsService.setSourceLanguage(AppLanguage.mandarin),
        ).called(1);
        verify(() =>
            mockSettingsService.setTargetLanguage(TargetLanguage.basque),
        ).called(1);
      });
    });

    group('setTutorialPage()', () {
      test('updates page and notifies', () {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.setTutorialPage(2);

        expect(vm.tutorialPage, 2);
        expect(notified, isTrue);
      });
    });

    group('completeOnboarding()', () {
      test('saves language prefs and marks onboarding complete', () async {
        final vm = createViewModel();

        await vm.completeOnboarding();

        verify(() =>
            mockSettingsService.setSourceLanguage(AppLanguage.english),
        ).called(1);
        verify(() =>
            mockSettingsService.setTargetLanguage(TargetLanguage.spanish),
        ).called(1);
        verify(() => mockSettingsService.setOnboardingComplete(true)).called(1);
        verify(() => mockSettingsService.setFirstLaunch(true)).called(1);
      });
    });
  });
}

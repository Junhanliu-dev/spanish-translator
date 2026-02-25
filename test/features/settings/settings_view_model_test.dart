import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_viaje/core/api/openai_client.dart';
import 'package:lingua_viaje/core/storage/secure_storage_service.dart';
import 'package:lingua_viaje/core/storage/settings_service.dart';
import 'package:lingua_viaje/features/settings/settings_view_model.dart';
import 'package:lingua_viaje/shared/models/app_language.dart';
import 'package:lingua_viaje/shared/models/target_language.dart';
import 'package:lingua_viaje/shared/notifiers/language_prefs_notifier.dart';
import 'package:lingua_viaje/shared/notifiers/theme_notifier.dart';
import 'package:mocktail/mocktail.dart';

// --- Mocks ---

class MockSecureStorageService extends Mock
    implements SecureStorageService {}

class MockSettingsService extends Mock implements SettingsService {}

class MockOpenAIClient extends Mock implements OpenAIClient {}

class MockLanguagePrefsNotifier extends Mock
    implements LanguagePrefsNotifier {}

class MockThemeNotifier extends Mock implements ThemeNotifier {}

void main() {
  late MockSecureStorageService mockSecureStorage;
  late MockSettingsService mockSettingsService;
  late MockOpenAIClient mockApiClient;
  late MockLanguagePrefsNotifier mockLanguagePrefs;
  late MockThemeNotifier mockThemeNotifier;

  setUp(() {
    mockSecureStorage = MockSecureStorageService();
    mockSettingsService = MockSettingsService();
    mockApiClient = MockOpenAIClient();
    mockLanguagePrefs = MockLanguagePrefsNotifier();
    mockThemeNotifier = MockThemeNotifier();

    when(() => mockLanguagePrefs.sourceLanguage)
        .thenReturn(AppLanguage.english);
    when(() => mockLanguagePrefs.targetLanguage)
        .thenReturn(TargetLanguage.spanish);
    when(() => mockThemeNotifier.themeMode).thenReturn(ThemeMode.system);
    when(() => mockSettingsService.getAppLocale()).thenReturn('en');
  });

  SettingsViewModel createViewModel() {
    return SettingsViewModel(
      secureStorage: mockSecureStorage,
      settingsService: mockSettingsService,
      apiClient: mockApiClient,
      languagePrefs: mockLanguagePrefs,
      themeNotifier: mockThemeNotifier,
    );
  }

  group('SettingsViewModel', () {
    test('initial state has no API key and unverified status', () {
      final vm = createViewModel();
      expect(vm.hasApiKey, isFalse);
      expect(vm.maskedApiKey, isNull);
      expect(vm.apiKeyStatus, ApiKeyStatus.unverified);
      expect(vm.isValidating, isFalse);
      expect(vm.isEditing, isFalse);
    });

    group('init()', () {
      test('loads masked key when one exists', () async {
        const storedKey = 'sk-proj-abcdefghijk1234567890abcdefghijk';
        when(() => mockSecureStorage.hasApiKey())
            .thenAnswer((_) async => true);
        when(() => mockSecureStorage.getApiKey())
            .thenAnswer((_) async => storedKey);

        final vm = createViewModel();
        await vm.init();

        expect(vm.hasApiKey, isTrue);
        expect(vm.maskedApiKey, isNotNull);
        // Masked key should start with 'sk-' and end with last 4 chars.
        expect(vm.maskedApiKey, startsWith('sk-'));
        expect(vm.maskedApiKey, endsWith('ijk'));
      });

      test('has no masked key when none stored', () async {
        when(() => mockSecureStorage.hasApiKey())
            .thenAnswer((_) async => false);

        final vm = createViewModel();
        await vm.init();

        expect(vm.hasApiKey, isFalse);
        expect(vm.maskedApiKey, isNull);
      });

      test('handles null from getApiKey gracefully', () async {
        when(() => mockSecureStorage.hasApiKey())
            .thenAnswer((_) async => true);
        when(() => mockSecureStorage.getApiKey())
            .thenAnswer((_) async => null);

        final vm = createViewModel();
        await vm.init();

        expect(vm.hasApiKey, isTrue);
        expect(vm.maskedApiKey, isNull);
      });
    });

    group('saveApiKey()', () {
      test('rejects keys that do not start with sk-', () async {
        final vm = createViewModel();

        final result =
            await vm.saveApiKey('pk-12345678901234567890');

        expect(result, isFalse);
        expect(vm.apiKeyStatus, ApiKeyStatus.invalid);
        expect(vm.apiKeyStatusMessage,
            'API keys start with sk- and are 50+ characters');
      });

      test('rejects keys shorter than 20 characters', () async {
        final vm = createViewModel();

        final result = await vm.saveApiKey('sk-short');

        expect(result, isFalse);
        expect(vm.apiKeyStatus, ApiKeyStatus.invalid);
        expect(vm.apiKeyStatusMessage,
            'API keys start with sk- and are 50+ characters');
      });

      test('rejects key with sk- prefix but under 20 chars', () async {
        final vm = createViewModel();

        final result = await vm.saveApiKey('sk-1234567890');

        expect(result, isFalse);
        expect(vm.apiKeyStatus, ApiKeyStatus.invalid);
      });

      test('validates and persists a valid key', () async {
        const validKey = 'sk-proj-abcdefghijk1234567890abcdefghijk';

        when(() => mockSecureStorage.getApiKey())
            .thenAnswer((_) async => null);
        when(() => mockApiClient.validateApiKey())
            .thenAnswer((_) async => true);
        when(() => mockSecureStorage.setApiKey(validKey))
            .thenAnswer((_) async {});

        final vm = createViewModel();
        final result = await vm.saveApiKey(validKey);

        expect(result, isTrue);
        expect(vm.apiKeyStatus, ApiKeyStatus.valid);
        expect(vm.hasApiKey, isTrue);
        expect(vm.maskedApiKey, isNotNull);
        expect(vm.isEditing, isFalse);
        expect(vm.isValidating, isFalse);

        verify(() => mockApiClient.updateApiKey(validKey)).called(1);
        verify(() => mockSecureStorage.setApiKey(validKey)).called(1);
      });

      test('restores previous key when validation fails', () async {
        const validKey = 'sk-proj-abcdefghijk1234567890abcdefghijk';
        const previousKey = 'sk-proj-previouskey1234567890previous';

        when(() => mockSecureStorage.getApiKey())
            .thenAnswer((_) async => previousKey);
        when(() => mockApiClient.validateApiKey())
            .thenAnswer((_) async => false);

        final vm = createViewModel();
        final result = await vm.saveApiKey(validKey);

        expect(result, isFalse);
        expect(vm.apiKeyStatus, ApiKeyStatus.invalid);

        // Should restore previous key.
        verify(() => mockApiClient.updateApiKey(previousKey)).called(1);
      });

      test(
          'restores previous key and sets unverified on network error',
          () async {
        const validKey = 'sk-proj-abcdefghijk1234567890abcdefghijk';

        when(() => mockSecureStorage.getApiKey())
            .thenAnswer((_) async => null);
        when(() => mockApiClient.validateApiKey())
            .thenThrow(Exception('Network error'));

        final vm = createViewModel();
        final result = await vm.saveApiKey(validKey);

        expect(result, isFalse);
        expect(vm.apiKeyStatus, ApiKeyStatus.unverified);
        expect(vm.apiKeyStatusMessage,
            contains('check your connection'));
      });
    });

    group('verifyApiKey()', () {
      test('sets valid on successful verification', () async {
        when(() => mockApiClient.validateApiKey())
            .thenAnswer((_) async => true);

        final vm = createViewModel();
        await vm.verifyApiKey();

        expect(vm.apiKeyStatus, ApiKeyStatus.valid);
        expect(vm.isValidating, isFalse);
      });

      test('sets invalid on failed verification', () async {
        when(() => mockApiClient.validateApiKey())
            .thenAnswer((_) async => false);

        final vm = createViewModel();
        await vm.verifyApiKey();

        expect(vm.apiKeyStatus, ApiKeyStatus.invalid);
      });
    });

    group('toggleEditing()', () {
      test('flips isEditing', () {
        final vm = createViewModel();
        expect(vm.isEditing, isFalse);
        vm.toggleEditing();
        expect(vm.isEditing, isTrue);
        vm.toggleEditing();
        expect(vm.isEditing, isFalse);
      });
    });

    group('language and theme accessors', () {
      test('sourceLanguage delegates to languagePrefs', () {
        final vm = createViewModel();
        expect(vm.sourceLanguage, AppLanguage.english);
      });

      test('targetLanguage delegates to languagePrefs', () {
        final vm = createViewModel();
        expect(vm.targetLanguage, TargetLanguage.spanish);
      });

      test('themeMode delegates to themeNotifier', () {
        final vm = createViewModel();
        expect(vm.themeMode, ThemeMode.system);
      });

      test('appLocale delegates to settingsService', () {
        final vm = createViewModel();
        expect(vm.appLocale, 'en');
      });
    });

    group('setSourceLanguage()', () {
      test('updates language prefs and notifies', () {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.setSourceLanguage(AppLanguage.mandarin);

        verify(
          () => mockLanguagePrefs.sourceLanguage = AppLanguage.mandarin,
        ).called(1);
        expect(notified, isTrue);
      });
    });

    group('setThemeMode()', () {
      test('updates theme notifier and notifies', () {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.setThemeMode(ThemeMode.dark);

        verify(
          () => mockThemeNotifier.themeMode = ThemeMode.dark,
        ).called(1);
        expect(notified, isTrue);
      });
    });
  });
}

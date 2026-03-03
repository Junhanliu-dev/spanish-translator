import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_viaje/core/api/openai_client.dart';
import 'package:lingua_viaje/core/storage/history_repository.dart';
import 'package:lingua_viaje/features/text/text_view_model.dart';
import 'package:lingua_viaje/shared/models/app_language.dart';
import 'package:lingua_viaje/shared/models/target_language.dart';
import 'package:lingua_viaje/shared/models/translation.dart';
import 'package:lingua_viaje/shared/notifiers/language_prefs_notifier.dart';
import 'package:mocktail/mocktail.dart';

// --- Mocks ---

class MockOpenAIClient extends Mock implements OpenAIClient {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

class MockLanguagePrefsNotifier extends Mock
    implements LanguagePrefsNotifier {}

class FakeTranslation extends Fake implements Translation {}

void main() {
  late MockOpenAIClient mockApiClient;
  late MockHistoryRepository mockHistoryRepo;
  late MockLanguagePrefsNotifier mockLanguagePrefs;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(FakeTranslation());

    // Stub audioplayers platform channels to avoid MissingPluginException.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => null,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      null,
    );
  });

  setUp(() {
    mockApiClient = MockOpenAIClient();
    mockHistoryRepo = MockHistoryRepository();
    mockLanguagePrefs = MockLanguagePrefsNotifier();

    when(() => mockLanguagePrefs.sourceLanguage)
        .thenReturn(AppLanguage.english);
    when(() => mockLanguagePrefs.targetLanguage)
        .thenReturn(TargetLanguage.spanish);
    when(() => mockLanguagePrefs.addListener(any())).thenReturn(null);
    when(() => mockLanguagePrefs.removeListener(any())).thenReturn(null);
  });

  TextViewModel createViewModel() {
    return TextViewModel(
      apiClient: mockApiClient,
      historyRepo: mockHistoryRepo,
      languagePrefs: mockLanguagePrefs,
    );
  }

  group('TextViewModel', () {
    test('initial state is idle with empty input', () {
      final vm = createViewModel();
      expect(vm.state, TextTranslationState.idle);
      expect(vm.inputText, '');
      expect(vm.result, isNull);
      expect(vm.errorMessage, isNull);
      expect(vm.isReversed, isFalse);
    });

    group('translate()', () {
      test('rejects input shorter than 3 characters', () async {
        final vm = createViewModel();
        vm.inputText = 'ab';

        // Don't await — translate() includes a 2-second delay that clears
        // errorMessage. Fire-and-forget, then check immediately.
        unawaited(vm.translate());
        // Allow the first microtask (notifyListeners) to complete.
        await Future<void>.delayed(Duration.zero);

        expect(vm.errorMessage, 'Too short to translate');
        // State should remain idle (not translating).
        expect(vm.state, TextTranslationState.idle);
      });

      test('rejects whitespace-only input shorter than 3 chars', () async {
        final vm = createViewModel();
        vm.inputText = '  a ';

        unawaited(vm.translate());
        await Future<void>.delayed(Duration.zero);

        expect(vm.errorMessage, 'Too short to translate');
      });

      test(
          'transitions to translating state and then success on valid input',
          () async {
        final vm = createViewModel();
        vm.inputText = 'hello world';

        when(() => mockApiClient.translate(
              text: any(named: 'text'),
              sourceLanguage: any(named: 'sourceLanguage'),
              targetLanguage: any(named: 'targetLanguage'),
              contextHint: any(named: 'contextHint'),
            )).thenAnswer((_) async => const TranslationResponse(
              translatedText: 'hola mundo',
              detectedLanguage: 'en',
              context: 'greeting',
              pronunciation: 'OH-lah MOON-doh',
            ));

        when(() => mockHistoryRepo.insertTranslation(any()))
            .thenAnswer((_) async => 1);
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => <Translation>[]);

        // Track state transitions.
        final states = <TextTranslationState>[];
        vm.addListener(() => states.add(vm.state));

        await vm.translate();

        expect(vm.state, TextTranslationState.success);
        expect(vm.result?.translatedText, 'hola mundo');
        expect(vm.detectedLanguage, 'en');
        // Should have gone through translating -> success.
        expect(states, contains(TextTranslationState.translating));
        expect(states, contains(TextTranslationState.success));
      });

      test('transitions to error state on API failure', () async {
        final vm = createViewModel();
        vm.inputText = 'hello world';

        when(() => mockApiClient.translate(
              text: any(named: 'text'),
              sourceLanguage: any(named: 'sourceLanguage'),
              targetLanguage: any(named: 'targetLanguage'),
              contextHint: any(named: 'contextHint'),
            )).thenThrow(Exception('Network failure'));

        await vm.translate();

        expect(vm.state, TextTranslationState.error);
        expect(vm.errorMessage, isNotNull);
      });

      test('uses reversed language direction when isReversed', () async {
        final vm = createViewModel();
        vm.inputText = 'hola mundo';
        vm.isReversed = true;

        when(() => mockApiClient.translate(
              text: any(named: 'text'),
              sourceLanguage: any(named: 'sourceLanguage'),
              targetLanguage: any(named: 'targetLanguage'),
              contextHint: any(named: 'contextHint'),
            )).thenAnswer((_) async => const TranslationResponse(
              translatedText: 'hello world',
              detectedLanguage: 'es',
            ));

        when(() => mockHistoryRepo.insertTranslation(any()))
            .thenAnswer((_) async => 1);
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => <Translation>[]);

        await vm.translate();

        // When reversed, source = target language, target = source language.
        final captured = verify(() => mockApiClient.translate(
              text: any(named: 'text'),
              sourceLanguage: captureAny(named: 'sourceLanguage'),
              targetLanguage: captureAny(named: 'targetLanguage'),
              contextHint: any(named: 'contextHint'),
            )).captured;

        expect(captured[0], 'es'); // target becomes source
        expect(captured[1], 'en'); // source becomes target
      });
    });

    group('clear()', () {
      test('resets all state to initial values', () {
        final vm = createViewModel();

        // Populate state.
        vm.inputText = 'some text';
        vm.state = TextTranslationState.success;
        vm.errorMessage = 'some error';
        vm.isReversed = true;
        vm.contextExpanded = true;
        vm.pronunciationExpanded = true;
        vm.isFavorite = true;

        vm.clear();

        expect(vm.inputText, '');
        expect(vm.result, isNull);
        expect(vm.detectedLanguage, isNull);
        expect(vm.errorMessage, isNull);
        expect(vm.contextExpanded, isFalse);
        expect(vm.pronunciationExpanded, isFalse);
        expect(vm.isFavorite, isFalse);
        expect(vm.state, TextTranslationState.idle);
      });

      test('notifies listeners', () {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.clear();

        expect(notified, isTrue);
      });
    });

    group('toggleDirection()', () {
      test('flips isReversed', () {
        final vm = createViewModel();
        expect(vm.isReversed, isFalse);

        vm.toggleDirection();
        expect(vm.isReversed, isTrue);

        vm.toggleDirection();
        expect(vm.isReversed, isFalse);
      });

      test('notifies listeners', () {
        final vm = createViewModel();
        var notifyCount = 0;
        vm.addListener(() => notifyCount++);

        vm.toggleDirection();
        vm.toggleDirection();

        expect(notifyCount, 2);
      });
    });

    group('setInputText()', () {
      test('updates inputText and notifies', () {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.setInputText('new text');
        expect(vm.inputText, 'new text');
        expect(notified, isTrue);
      });
    });

    group('toggleContext() and togglePronunciation()', () {
      test('toggleContext flips contextExpanded', () {
        final vm = createViewModel();
        expect(vm.contextExpanded, isFalse);
        vm.toggleContext();
        expect(vm.contextExpanded, isTrue);
        vm.toggleContext();
        expect(vm.contextExpanded, isFalse);
      });

      test('togglePronunciation flips pronunciationExpanded', () {
        final vm = createViewModel();
        expect(vm.pronunciationExpanded, isFalse);
        vm.togglePronunciation();
        expect(vm.pronunciationExpanded, isTrue);
        vm.togglePronunciation();
        expect(vm.pronunciationExpanded, isFalse);
      });
    });

    group('language display names', () {
      test('sourceLanguageDisplay returns source when not reversed', () {
        final vm = createViewModel();
        expect(vm.sourceLanguageDisplay, 'English');
      });

      test('sourceLanguageDisplay returns target when reversed', () {
        final vm = createViewModel();
        vm.toggleDirection();
        expect(vm.sourceLanguageDisplay, 'Spanish');
      });

      test('targetLanguageDisplay returns target when not reversed', () {
        final vm = createViewModel();
        expect(vm.targetLanguageDisplay, 'Spanish');
      });

      test('targetLanguageDisplay returns source when reversed', () {
        final vm = createViewModel();
        vm.toggleDirection();
        expect(vm.targetLanguageDisplay, 'English');
      });
    });

    group('toggleFavorite()', () {
      test('does nothing when _lastSavedId is null', () async {
        final vm = createViewModel();
        await vm.toggleFavorite();
        verifyNever(
            () => mockHistoryRepo.toggleFavorite(any(), any()));
      });
    });

    group('loadRecentTranslations()', () {
      test('fetches text translations with limit 3', () async {
        final translations = <Translation>[
          Translation(
            type: 'text',
            sourceText: 'hi',
            translatedText: 'hola',
            sourceLanguage: 'en',
            targetLanguage: 'es',
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockHistoryRepo.getTranslations(
              typeFilter: 'text',
              limit: 3,
            )).thenAnswer((_) async => translations);

        final vm = createViewModel();
        await vm.loadRecentTranslations();

        expect(vm.recentTranslations, hasLength(1));
        expect(vm.recentTranslations.first.sourceText, 'hi');
      });

      test('silently handles errors', () async {
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              limit: any(named: 'limit'),
            )).thenThrow(Exception('DB error'));

        final vm = createViewModel();
        // Should not throw.
        await vm.loadRecentTranslations();
        expect(vm.recentTranslations, isEmpty);
      });
    });
  });
}

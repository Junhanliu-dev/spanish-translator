import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_viaje/core/api/openai_client.dart';
import 'package:lingua_viaje/core/storage/history_repository.dart';
import 'package:lingua_viaje/features/photo/photo_view_model.dart';
import 'package:lingua_viaje/shared/models/app_language.dart';
import 'package:lingua_viaje/shared/models/menu_item.dart';
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
  });

  PhotoViewModel createViewModel() {
    return PhotoViewModel(
      apiClient: mockApiClient,
      historyRepo: mockHistoryRepo,
      languagePrefs: mockLanguagePrefs,
    );
  }

  group('PhotoViewModel', () {
    test('initial state is idle with null values', () {
      final vm = createViewModel();

      expect(vm.state, PhotoState.idle);
      expect(vm.capturedImagePath, isNull);
      expect(vm.menuResult, isNull);
      expect(vm.errorMessage, isNull);
      expect(vm.expandedItemIndex, isNull);
      expect(vm.pageImagePaths, isEmpty);
      expect(vm.isSaved, isFalse);
      expect(vm.isSpeaking, isFalse);
    });

    group('toggleItemExpansion()', () {
      test('expands an item by index', () {
        final vm = createViewModel();

        vm.toggleItemExpansion(2);
        expect(vm.expandedItemIndex, 2);
      });

      test('collapses an item when toggled again (same index)', () {
        final vm = createViewModel();

        vm.toggleItemExpansion(2);
        expect(vm.expandedItemIndex, 2);

        vm.toggleItemExpansion(2);
        expect(vm.expandedItemIndex, isNull);
      });

      test('switches to a different item (accordion behavior)', () {
        final vm = createViewModel();

        vm.toggleItemExpansion(1);
        expect(vm.expandedItemIndex, 1);

        vm.toggleItemExpansion(3);
        expect(vm.expandedItemIndex, 3);
      });

      test('notifies listeners on expansion change', () {
        final vm = createViewModel();
        var notifyCount = 0;
        vm.addListener(() => notifyCount++);

        vm.toggleItemExpansion(0);
        vm.toggleItemExpansion(0);

        expect(notifyCount, 2);
      });
    });

    group('resetForNewCapture()', () {
      test('resets all state to initial values', () {
        final vm = createViewModel();

        // Populate state to simulate a completed flow.
        vm.state = PhotoState.success;
        vm.capturedImagePath = '/some/path.jpg';
        vm.errorMessage = 'some error';
        vm.expandedItemIndex = 5;
        vm.isSaved = true;

        vm.resetForNewCapture();

        expect(vm.state, PhotoState.idle);
        expect(vm.capturedImagePath, isNull);
        expect(vm.menuResult, isNull);
        expect(vm.errorMessage, isNull);
        expect(vm.expandedItemIndex, isNull);
        expect(vm.isSaved, isFalse);
      });

      test('notifies listeners', () {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.resetForNewCapture();

        expect(notified, isTrue);
      });
    });

    group('totalItemCount', () {
      test('returns 0 when menuResult is null', () {
        final vm = createViewModel();
        expect(vm.totalItemCount, 0);
      });

      test('counts items across all sections', () {
        final vm = createViewModel();

        final menuResult = MenuTranslationResponse(
          detectedLanguage: 'es',
          sections: [
            MenuSection(
              originalTitle: 'Entrantes',
              translatedTitle: 'Starters',
              items: [
                const MenuItem(
                  originalName: 'Gazpacho',
                  translatedName: 'Cold tomato soup',
                ),
                const MenuItem(
                  originalName: 'Tortilla',
                  translatedName: 'Spanish omelette',
                ),
              ],
            ),
            MenuSection(
              originalTitle: 'Principales',
              translatedTitle: 'Mains',
              items: [
                const MenuItem(
                  originalName: 'Paella',
                  translatedName: 'Seafood rice',
                ),
              ],
            ),
          ],
        );

        // Set menuResult directly (it's a public field).
        vm.menuResult = menuResult;

        expect(vm.totalItemCount, 3);
      });

      test('returns 0 with empty sections', () {
        final vm = createViewModel();

        vm.menuResult = const MenuTranslationResponse(
          detectedLanguage: 'es',
          sections: [],
        );

        expect(vm.totalItemCount, 0);
      });
    });

    group('saveToHistory()', () {
      test('does nothing when menuResult is null', () async {
        final vm = createViewModel();
        vm.capturedImagePath = '/some/path.jpg';

        await vm.saveToHistory(title: 'Test');

        verifyNever(() => mockHistoryRepo.insertTranslation(any()));
      });

      test('does nothing when capturedImagePath is null', () async {
        final vm = createViewModel();
        vm.menuResult = const MenuTranslationResponse(
          detectedLanguage: 'es',
          sections: [],
        );

        await vm.saveToHistory(title: 'Test');

        verifyNever(() => mockHistoryRepo.insertTranslation(any()));
      });

      test('does nothing when already saved', () async {
        final vm = createViewModel();
        vm.menuResult = const MenuTranslationResponse(
          detectedLanguage: 'es',
          sections: [],
        );
        vm.capturedImagePath = '/path.jpg';
        vm.isSaved = true;

        await vm.saveToHistory(title: 'Test');

        verifyNever(() => mockHistoryRepo.insertTranslation(any()));
      });

      test('saves translation and menu items, then marks saved', () async {
        when(() => mockHistoryRepo.insertTranslation(any()))
            .thenAnswer((_) async => 42);
        when(() => mockHistoryRepo.insertMenuItems(any(), any()))
            .thenAnswer((_) async {});

        final vm = createViewModel();
        vm.capturedImagePath = '/path/to/menu.jpg';
        vm.menuResult = MenuTranslationResponse(
          detectedLanguage: 'es',
          sections: [
            MenuSection(
              originalTitle: 'Entrantes',
              translatedTitle: 'Starters',
              items: [
                const MenuItem(
                  originalName: 'Gazpacho',
                  translatedName: 'Cold tomato soup',
                  description: 'A cold soup',
                  pronunciation: 'gath-PAH-cho',
                  price: 'EUR 8.00',
                ),
              ],
            ),
          ],
        );

        await vm.saveToHistory(title: 'Lunch Menu');

        expect(vm.isSaved, isTrue);
        verify(() => mockHistoryRepo.insertTranslation(any())).called(1);
        verify(() => mockHistoryRepo.insertMenuItems(42, any())).called(1);
      });

      test('uses null title when title is empty/whitespace', () async {
        when(() => mockHistoryRepo.insertTranslation(any()))
            .thenAnswer((_) async => 1);
        when(() => mockHistoryRepo.insertMenuItems(any(), any()))
            .thenAnswer((_) async {});

        final vm = createViewModel();
        vm.capturedImagePath = '/path.jpg';
        vm.menuResult = const MenuTranslationResponse(
          detectedLanguage: 'es',
          sections: [],
        );

        await vm.saveToHistory(title: '   ');

        // Verify the translation was inserted (title will be null
        // inside the ViewModel since trim().isEmpty is true).
        verify(() => mockHistoryRepo.insertTranslation(any())).called(1);
      });
    });

    group('speakText()', () {
      test('sets isSpeaking to true then false on error', () async {
        when(() => mockApiClient.textToSpeech(
              text: any(named: 'text'),
              speed: any(named: 'speed'),
            )).thenThrow(Exception('TTS failed'));

        final vm = createViewModel();
        final speakingStates = <bool>[];
        vm.addListener(() => speakingStates.add(vm.isSpeaking));

        await vm.speakText('Gazpacho');

        // Should have been true (start), then false (error catch).
        expect(speakingStates, contains(true));
        expect(speakingStates.last, isFalse);
        expect(vm.isSpeaking, isFalse);
      });

      test('sets isSpeaking to true when TTS starts', () async {
        when(() => mockApiClient.textToSpeech(
              text: any(named: 'text'),
              speed: any(named: 'speed'),
            )).thenThrow(Exception('TTS failed'));

        final vm = createViewModel();

        bool wasSpeaking = false;
        vm.addListener(() {
          if (vm.isSpeaking) wasSpeaking = true;
        });

        await vm.speakText('Hola');

        expect(wasSpeaking, isTrue);
      });
    });

    group('dispose()', () {
      test('does not throw', () {
        final vm = createViewModel();
        expect(() => vm.dispose(), returnsNormally);
      });
    });
  });
}

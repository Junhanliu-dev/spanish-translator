import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_viaje/core/api/openai_client.dart';
import 'package:lingua_viaje/core/storage/history_repository.dart';
import 'package:lingua_viaje/shared/models/app_language.dart';
import 'package:lingua_viaje/shared/models/speech_state.dart';
import 'package:lingua_viaje/shared/models/target_language.dart';
import 'package:lingua_viaje/shared/models/translation.dart';
import 'package:lingua_viaje/shared/notifiers/language_prefs_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';

import 'package:lingua_viaje/features/speech/speech_view_model.dart';

// --- Mocks ---

class MockOpenAIClient extends Mock implements OpenAIClient {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

class MockLanguagePrefsNotifier extends Mock
    implements LanguagePrefsNotifier {}

class MockAudioRecorder extends Mock implements AudioRecorder {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class FakeTranslation extends Fake implements Translation {}

void main() {
  late MockOpenAIClient mockApiClient;
  late MockHistoryRepository mockHistoryRepo;
  late MockLanguagePrefsNotifier mockLanguagePrefs;
  late MockAudioRecorder mockRecorder;
  late MockAudioPlayer mockPlayer;

  setUpAll(() {
    registerFallbackValue(FakeTranslation());
  });

  setUp(() {
    mockApiClient = MockOpenAIClient();
    mockHistoryRepo = MockHistoryRepository();
    mockLanguagePrefs = MockLanguagePrefsNotifier();
    mockRecorder = MockAudioRecorder();
    mockPlayer = MockAudioPlayer();

    // Default language stubs.
    when(() => mockLanguagePrefs.sourceLanguage)
        .thenReturn(AppLanguage.english);
    when(() => mockLanguagePrefs.targetLanguage)
        .thenReturn(TargetLanguage.spanish);

    // Stub dispose methods to avoid platform errors.
    when(() => mockRecorder.dispose()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});
    when(() => mockPlayer.stop()).thenAnswer((_) async {});
  });

  SpeechViewModel createViewModel() {
    return SpeechViewModel(
      apiClient: mockApiClient,
      historyRepo: mockHistoryRepo,
      languagePrefs: mockLanguagePrefs,
      recorder: mockRecorder,
      player: mockPlayer,
    );
  }

  group('SpeechViewModel', () {
    test('initial state is idle', () {
      final vm = createViewModel();
      expect(vm.state, SpeechState.idle);
      expect(vm.sourceText, isNull);
      expect(vm.translatedText, isNull);
      expect(vm.errorMessage, isNull);
      expect(vm.isSwapped, isFalse);
      expect(vm.isTTSPlaying, isFalse);
      expect(vm.isSaved, isFalse);
      vm.dispose();
    });

    test('swapLanguages toggles isSwapped and notifies listeners', () {
      final vm = createViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      expect(vm.isSwapped, isFalse);
      vm.swapLanguages();
      expect(vm.isSwapped, isTrue);
      expect(notified, isTrue);

      notified = false;
      vm.swapLanguages();
      expect(vm.isSwapped, isFalse);
      expect(notified, isTrue);
      vm.dispose();
    });

    test('_safeNotify does not throw after dispose', () {
      final vm = createViewModel();
      vm.dispose();

      expect(() => vm.isSwapped, returnsNormally);
    });

    test('sourceLanguageDisplay returns source when not swapped', () {
      final vm = createViewModel();
      expect(vm.sourceLanguageDisplay, 'English');
      vm.dispose();
    });

    test('sourceLanguageDisplay returns target when swapped', () {
      final vm = createViewModel();
      vm.swapLanguages();
      expect(vm.sourceLanguageDisplay, 'Spanish');
      vm.dispose();
    });

    test('targetLanguageDisplay returns target when not swapped', () {
      final vm = createViewModel();
      expect(vm.targetLanguageDisplay, 'Spanish');
      vm.dispose();
    });

    test('targetLanguageDisplay returns source when swapped', () {
      final vm = createViewModel();
      vm.swapLanguages();
      expect(vm.targetLanguageDisplay, 'English');
      vm.dispose();
    });

    test(
        'sourceLanguageDisplay uses detectedLanguage when set and not swapped',
        () {
      final vm = createViewModel();
      vm.detectedLanguage = 'es';
      expect(vm.sourceLanguageDisplay, 'Spanish');
      vm.dispose();
    });

    test('saveToHistory does nothing when sourceText is null', () async {
      final vm = createViewModel();
      await vm.saveToHistory();
      verifyNever(() => mockHistoryRepo.insertTranslation(any()));
      vm.dispose();
    });

    test('saveToHistory does nothing when already saved', () async {
      final vm = createViewModel();
      vm.sourceText = 'hello';
      vm.translatedText = 'hola';
      vm.isSaved = true;
      await vm.saveToHistory();
      verifyNever(() => mockHistoryRepo.insertTranslation(any()));
      vm.dispose();
    });

    test('saveToHistory inserts translation and marks saved', () async {
      when(() => mockHistoryRepo.insertTranslation(any()))
          .thenAnswer((_) async => 1);

      final vm = createViewModel();
      vm.sourceText = 'hello';
      vm.translatedText = 'hola';
      vm.detectedLanguage = 'en';

      await vm.saveToHistory();

      expect(vm.isSaved, isTrue);
      verify(() => mockHistoryRepo.insertTranslation(any())).called(1);
      vm.dispose();
    });

    test('stopRecording returns early if state is not recording', () async {
      final vm = createViewModel();
      expect(vm.state, SpeechState.idle);
      await vm.stopRecording();
      // Should remain idle, no crash.
      expect(vm.state, SpeechState.idle);
      vm.dispose();
    });

    test('startRecording returns early if state is not idle', () async {
      final vm = createViewModel();
      // Force state to processing.
      vm.state = SpeechState.processing;
      await vm.startRecording();
      // Should remain processing (no transition).
      expect(vm.state, SpeechState.processing);
      vm.dispose();
    });
  });
}

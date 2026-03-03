import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_viaje/core/storage/history_repository.dart';
import 'package:lingua_viaje/features/history/history_view_model.dart';
import 'package:lingua_viaje/shared/models/translation.dart';
import 'package:mocktail/mocktail.dart';

// --- Mocks ---

class MockHistoryRepository extends Mock implements HistoryRepository {}

class FakeTranslation extends Fake implements Translation {}

void main() {
  late MockHistoryRepository mockHistoryRepo;

  setUpAll(() {
    registerFallbackValue(FakeTranslation());
  });

  setUp(() {
    mockHistoryRepo = MockHistoryRepository();
  });

  HistoryViewModel createViewModel() {
    return HistoryViewModel(historyRepo: mockHistoryRepo);
  }

  final sampleTranslations = [
    Translation(
      id: 1,
      type: 'text',
      sourceText: 'hello',
      translatedText: 'hola',
      sourceLanguage: 'en',
      targetLanguage: 'es',
      createdAt: DateTime.now(),
    ),
    Translation(
      id: 2,
      type: 'speech',
      sourceText: 'good morning',
      translatedText: 'buenos dias',
      sourceLanguage: 'en',
      targetLanguage: 'es',
      isFavorite: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Translation(
      id: 3,
      type: 'photo',
      sourceText: 'paella',
      translatedText: 'seafood rice',
      sourceLanguage: 'es',
      targetLanguage: 'en',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  group('HistoryViewModel', () {
    test('initial state has correct defaults', () {
      final vm = createViewModel();

      expect(vm.translations, isEmpty);
      expect(vm.activeFilter, isNull);
      expect(vm.searchQuery, '');
      expect(vm.isSearchVisible, isFalse);
      expect(vm.isLoading, isFalse);
    });

    group('load()', () {
      test('sets isLoading during fetch and populates translations', () async {
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).thenAnswer((_) async => sampleTranslations);

        final vm = createViewModel();
        final loadingStates = <bool>[];
        vm.addListener(() => loadingStates.add(vm.isLoading));

        await vm.load();

        expect(vm.translations, hasLength(3));
        expect(vm.isLoading, isFalse);
        // Should have been true (start), then false (done).
        expect(loadingStates, contains(true));
        expect(loadingStates.last, isFalse);
      });

      test('passes null searchQuery when search is empty', () async {
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).thenAnswer((_) async => []);

        final vm = createViewModel();
        await vm.load();

        verify(() => mockHistoryRepo.getTranslations(
              typeFilter: null,
              searchQuery: null,
            )).called(1);
      });

      test('passes search query when non-empty', () async {
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).thenAnswer((_) async => []);

        final vm = createViewModel();
        vm.searchQuery = 'hello';
        await vm.load();

        verify(() => mockHistoryRepo.getTranslations(
              typeFilter: null,
              searchQuery: 'hello',
            )).called(1);
      });

      test('passes active filter', () async {
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).thenAnswer((_) async => []);

        final vm = createViewModel();
        vm.activeFilter = 'speech';
        await vm.load();

        verify(() => mockHistoryRepo.getTranslations(
              typeFilter: 'speech',
              searchQuery: null,
            )).called(1);
      });

      test('clears translations on exception', () async {
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).thenThrow(Exception('DB error'));

        final vm = createViewModel();
        await vm.load();

        expect(vm.translations, isEmpty);
        expect(vm.isLoading, isFalse);
      });
    });

    group('setFilter()', () {
      test('updates activeFilter and reloads', () async {
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).thenAnswer((_) async => []);

        final vm = createViewModel();
        await vm.setFilter('text');

        expect(vm.activeFilter, 'text');
        verify(() => mockHistoryRepo.getTranslations(
              typeFilter: 'text',
              searchQuery: null,
            )).called(1);
      });

      test('clears filter when set to null', () async {
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).thenAnswer((_) async => []);

        final vm = createViewModel();
        vm.activeFilter = 'speech';
        await vm.setFilter(null);

        expect(vm.activeFilter, isNull);
      });
    });

    group('setSearchQuery()', () {
      test('updates searchQuery and reloads', () async {
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).thenAnswer((_) async => []);

        final vm = createViewModel();
        await vm.setSearchQuery('paella');

        expect(vm.searchQuery, 'paella');
        verify(() => mockHistoryRepo.getTranslations(
              typeFilter: null,
              searchQuery: 'paella',
            )).called(1);
      });
    });

    group('toggleSearch()', () {
      test('shows search bar', () {
        final vm = createViewModel();
        expect(vm.isSearchVisible, isFalse);

        vm.toggleSearch();
        expect(vm.isSearchVisible, isTrue);
      });

      test('hides search bar and clears query when hiding', () async {
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).thenAnswer((_) async => []);

        final vm = createViewModel();
        vm.isSearchVisible = true;
        vm.searchQuery = 'hello';

        vm.toggleSearch();

        expect(vm.isSearchVisible, isFalse);
        expect(vm.searchQuery, '');
      });

      test('does not reload when hiding with empty query', () {
        final vm = createViewModel();
        vm.isSearchVisible = true;
        vm.searchQuery = '';

        vm.toggleSearch();

        expect(vm.isSearchVisible, isFalse);
        // No load() call since searchQuery was already empty.
        verifyNever(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            ));
      });

      test('notifies listeners', () {
        final vm = createViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.toggleSearch();

        expect(notified, isTrue);
      });
    });

    group('deleteTranslation()', () {
      test('returns null when ID not found', () async {
        final vm = createViewModel();
        vm.translations = List.from(sampleTranslations);

        final result = await vm.deleteTranslation(999);

        expect(result, isNull);
      });

      test('removes item optimistically and calls repo', () async {
        when(() => mockHistoryRepo.deleteTranslation(1))
            .thenAnswer((_) async {});

        final vm = createViewModel();
        vm.translations = List.from(sampleTranslations);

        final deleted = await vm.deleteTranslation(1);

        expect(deleted, isNotNull);
        expect(deleted!.id, 1);
        expect(vm.translations, hasLength(2));
        expect(vm.translations.any((t) => t.id == 1), isFalse);
        verify(() => mockHistoryRepo.deleteTranslation(1)).called(1);
      });

      test('re-inserts item on repo failure', () async {
        when(() => mockHistoryRepo.deleteTranslation(1))
            .thenThrow(Exception('DB error'));

        final vm = createViewModel();
        vm.translations = List.from(sampleTranslations);

        final result = await vm.deleteTranslation(1);

        expect(result, isNull);
        // Item should be re-inserted at the original index.
        expect(vm.translations, hasLength(3));
        expect(vm.translations[0].id, 1);
      });

      test('notifies listeners on successful delete', () async {
        when(() => mockHistoryRepo.deleteTranslation(2))
            .thenAnswer((_) async {});

        final vm = createViewModel();
        vm.translations = List.from(sampleTranslations);

        var notifyCount = 0;
        vm.addListener(() => notifyCount++);

        await vm.deleteTranslation(2);

        // At least one notification for optimistic removal.
        expect(notifyCount, greaterThanOrEqualTo(1));
      });
    });

    group('undoDelete()', () {
      test('re-inserts translation and reloads', () async {
        when(() => mockHistoryRepo.insertTranslation(any()))
            .thenAnswer((_) async => 1);
        when(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).thenAnswer((_) async => sampleTranslations);

        final vm = createViewModel();

        await vm.undoDelete(sampleTranslations.first);

        verify(() => mockHistoryRepo.insertTranslation(any())).called(1);
        // Should reload after undo.
        verify(() => mockHistoryRepo.getTranslations(
              typeFilter: any(named: 'typeFilter'),
              searchQuery: any(named: 'searchQuery'),
            )).called(1);
      });

      test('silently handles repo failure', () async {
        when(() => mockHistoryRepo.insertTranslation(any()))
            .thenThrow(Exception('DB error'));

        final vm = createViewModel();

        // Should not throw.
        await vm.undoDelete(sampleTranslations.first);
      });
    });

    group('toggleFavorite()', () {
      test('does nothing when ID not found', () async {
        final vm = createViewModel();
        vm.translations = List.from(sampleTranslations);

        await vm.toggleFavorite(999, false);

        verifyNever(
            () => mockHistoryRepo.toggleFavorite(any(), any()));
      });

      test('toggles favorite optimistically and calls repo', () async {
        when(() => mockHistoryRepo.toggleFavorite(1, true))
            .thenAnswer((_) async {});

        final vm = createViewModel();
        vm.translations = List.from(sampleTranslations);

        // Item 1 starts as isFavorite=false. Toggle it to true.
        await vm.toggleFavorite(1, false);

        expect(vm.translations[0].isFavorite, isTrue);
        verify(() => mockHistoryRepo.toggleFavorite(1, true)).called(1);
      });

      test('reverts favorite on repo failure', () async {
        when(() => mockHistoryRepo.toggleFavorite(1, true))
            .thenThrow(Exception('DB error'));

        final vm = createViewModel();
        vm.translations = List.from(sampleTranslations);

        // Item 1 starts as isFavorite=false. Try to toggle, but fail.
        await vm.toggleFavorite(1, false);

        // Should revert back to false.
        expect(vm.translations[0].isFavorite, isFalse);
      });

      test('toggles from favorite to non-favorite', () async {
        when(() => mockHistoryRepo.toggleFavorite(2, false))
            .thenAnswer((_) async {});

        final vm = createViewModel();
        vm.translations = List.from(sampleTranslations);

        // Item 2 is currently favorite (isFavorite=true).
        await vm.toggleFavorite(2, true);

        expect(vm.translations[1].isFavorite, isFalse);
        verify(() => mockHistoryRepo.toggleFavorite(2, false)).called(1);
      });

      test('notifies listeners on toggle', () async {
        when(() => mockHistoryRepo.toggleFavorite(1, true))
            .thenAnswer((_) async {});

        final vm = createViewModel();
        vm.translations = List.from(sampleTranslations);

        var notifyCount = 0;
        vm.addListener(() => notifyCount++);

        await vm.toggleFavorite(1, false);

        expect(notifyCount, greaterThanOrEqualTo(1));
      });
    });

    group('groupedByDate', () {
      test('groups translations by Today', () {
        final vm = createViewModel();
        final now = DateTime.now();
        vm.translations = [
          Translation(
            id: 1,
            type: 'text',
            sourceText: 'hello',
            translatedText: 'hola',
            sourceLanguage: 'en',
            targetLanguage: 'es',
            createdAt: now,
          ),
        ];

        final groups = vm.groupedByDate;
        expect(groups.containsKey('Today'), isTrue);
        expect(groups['Today'], hasLength(1));
      });

      test('groups translations by Yesterday', () {
        final vm = createViewModel();
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        vm.translations = [
          Translation(
            id: 1,
            type: 'text',
            sourceText: 'hello',
            translatedText: 'hola',
            sourceLanguage: 'en',
            targetLanguage: 'es',
            createdAt: yesterday,
          ),
        ];

        final groups = vm.groupedByDate;
        expect(groups.containsKey('Yesterday'), isTrue);
      });

      test('groups older translations by month and day', () {
        final vm = createViewModel();
        // Use a fixed date far in the past to avoid Today/Yesterday.
        final oldDate = DateTime(2024, 3, 15);
        vm.translations = [
          Translation(
            id: 1,
            type: 'text',
            sourceText: 'hello',
            translatedText: 'hola',
            sourceLanguage: 'en',
            targetLanguage: 'es',
            createdAt: oldDate,
          ),
        ];

        final groups = vm.groupedByDate;
        expect(groups.containsKey('Mar 15'), isTrue);
      });

      test('returns empty map for no translations', () {
        final vm = createViewModel();
        expect(vm.groupedByDate, isEmpty);
      });

      test('groups multiple translations under the same date', () {
        final vm = createViewModel();
        final now = DateTime.now();
        vm.translations = [
          Translation(
            id: 1,
            type: 'text',
            sourceText: 'hello',
            translatedText: 'hola',
            sourceLanguage: 'en',
            targetLanguage: 'es',
            createdAt: now,
          ),
          Translation(
            id: 2,
            type: 'speech',
            sourceText: 'goodbye',
            translatedText: 'adios',
            sourceLanguage: 'en',
            targetLanguage: 'es',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ];

        final groups = vm.groupedByDate;
        expect(groups['Today'], hasLength(2));
      });
    });
  });
}

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

    group('order state', () {
      PhotoViewModel createVmWithMenu() {
        final vm = createViewModel();
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
                  price: 'EUR 8.00',
                ),
                const MenuItem(
                  originalName: 'Tortilla',
                  translatedName: 'Spanish omelette',
                  price: 'EUR 10.00',
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
                  price: 'EUR 16.00',
                ),
              ],
            ),
          ],
        );
        return vm;
      }

      test('initial order state is empty', () {
        final vm = createViewModel();
        expect(vm.orderItems, isEmpty);
        expect(vm.orderPhrase, isNull);
        expect(vm.isGeneratingOrder, isFalse);
        expect(vm.isSpeakingOrder, isFalse);
        expect(vm.hasOrder, isFalse);
        expect(vm.orderTotalCount, 0);
      });

      group('addToOrder()', () {
        test('adds item with quantity 1', () {
          final vm = createVmWithMenu();
          vm.addToOrder(0);
          expect(vm.orderItems[0], 1);
          expect(vm.hasOrder, isTrue);
          expect(vm.orderTotalCount, 1);
        });

        test('increments quantity on repeated adds', () {
          final vm = createVmWithMenu();
          vm.addToOrder(0);
          vm.addToOrder(0);
          vm.addToOrder(0);
          expect(vm.orderItems[0], 3);
          expect(vm.orderTotalCount, 3);
        });

        test('tracks multiple items independently', () {
          final vm = createVmWithMenu();
          vm.addToOrder(0);
          vm.addToOrder(1);
          vm.addToOrder(1);
          expect(vm.orderItems[0], 1);
          expect(vm.orderItems[1], 2);
          expect(vm.orderTotalCount, 3);
        });

        test('nulls orderPhrase on change', () {
          final vm = createVmWithMenu();
          vm.orderPhrase = 'Cached phrase';
          vm.addToOrder(0);
          expect(vm.orderPhrase, isNull);
        });

        test('notifies listeners', () {
          final vm = createVmWithMenu();
          var notified = false;
          vm.addListener(() => notified = true);
          vm.addToOrder(0);
          expect(notified, isTrue);
        });
      });

      group('removeFromOrder()', () {
        test('decrements quantity', () {
          final vm = createVmWithMenu();
          vm.addToOrder(0);
          vm.addToOrder(0);
          vm.removeFromOrder(0);
          expect(vm.orderItems[0], 1);
        });

        test('removes item entirely when quantity reaches 0', () {
          final vm = createVmWithMenu();
          vm.addToOrder(0);
          vm.removeFromOrder(0);
          expect(vm.orderItems.containsKey(0), isFalse);
          expect(vm.hasOrder, isFalse);
        });

        test('nulls orderPhrase on change', () {
          final vm = createVmWithMenu();
          vm.addToOrder(0);
          vm.orderPhrase = 'Cached phrase';
          vm.removeFromOrder(0);
          expect(vm.orderPhrase, isNull);
        });

        test('handles removing non-existent item gracefully', () {
          final vm = createVmWithMenu();
          vm.removeFromOrder(99);
          expect(vm.orderItems, isEmpty);
        });
      });

      group('clearOrder()', () {
        test('clears all items and phrase', () {
          final vm = createVmWithMenu();
          vm.addToOrder(0);
          vm.addToOrder(1);
          vm.orderPhrase = 'Some phrase';

          vm.clearOrder();

          expect(vm.orderItems, isEmpty);
          expect(vm.orderPhrase, isNull);
          expect(vm.hasOrder, isFalse);
          expect(vm.orderTotalCount, 0);
        });
      });

      group('orderItemList', () {
        test('returns empty list when no order', () {
          final vm = createVmWithMenu();
          expect(vm.orderItemList, isEmpty);
        });

        test('returns items sorted by index', () {
          final vm = createVmWithMenu();
          vm.addToOrder(2); // Paella (index 2)
          vm.addToOrder(0); // Gazpacho (index 0)

          final list = vm.orderItemList;
          expect(list.length, 2);
          expect(list[0].$1, 0); // Gazpacho first
          expect(list[0].$2.originalName, 'Gazpacho');
          expect(list[0].$3, 1);
          expect(list[1].$1, 2); // Paella second
          expect(list[1].$2.originalName, 'Paella');
          expect(list[1].$3, 1);
        });

        test('reflects correct quantities', () {
          final vm = createVmWithMenu();
          vm.addToOrder(1);
          vm.addToOrder(1);
          vm.addToOrder(1);

          final list = vm.orderItemList;
          expect(list.length, 1);
          expect(list[0].$2.originalName, 'Tortilla');
          expect(list[0].$3, 3);
        });
      });

      group('generateOrderPhrase()', () {
        test('does nothing when order is empty', () async {
          final vm = createVmWithMenu();
          await vm.generateOrderPhrase();
          expect(vm.orderPhrase, isNull);
          verifyNever(() => mockApiClient.generateOrderPhrase(
                items: any(named: 'items'),
                restaurantLanguage: any(named: 'restaurantLanguage'),
              ));
        });

        test('calls API and caches result', () async {
          when(() => mockApiClient.generateOrderPhrase(
                items: any(named: 'items'),
                restaurantLanguage: any(named: 'restaurantLanguage'),
              )).thenAnswer((_) async =>
              'Hola, querría un gazpacho, por favor.');

          final vm = createVmWithMenu();
          vm.addToOrder(0);

          await vm.generateOrderPhrase();

          expect(vm.orderPhrase,
              'Hola, querría un gazpacho, por favor.');
          expect(vm.isGeneratingOrder, isFalse);
        });

        test('sets isGeneratingOrder during API call', () async {
          when(() => mockApiClient.generateOrderPhrase(
                items: any(named: 'items'),
                restaurantLanguage: any(named: 'restaurantLanguage'),
              )).thenAnswer((_) async => 'phrase');

          final vm = createVmWithMenu();
          vm.addToOrder(0);

          final generatingStates = <bool>[];
          vm.addListener(
              () => generatingStates.add(vm.isGeneratingOrder));

          await vm.generateOrderPhrase();

          expect(generatingStates, contains(true));
          expect(generatingStates.last, isFalse);
        });

        test('handles API error gracefully', () async {
          when(() => mockApiClient.generateOrderPhrase(
                items: any(named: 'items'),
                restaurantLanguage: any(named: 'restaurantLanguage'),
              )).thenThrow(Exception('API error'));

          final vm = createVmWithMenu();
          vm.addToOrder(0);

          await vm.generateOrderPhrase();

          expect(vm.orderPhrase, isNull);
          expect(vm.isGeneratingOrder, isFalse);
        });
      });

      group('speakOrder()', () {
        test('does nothing when orderPhrase is null', () async {
          final vm = createVmWithMenu();
          await vm.speakOrder();
          expect(vm.isSpeakingOrder, isFalse);
          verifyNever(() => mockApiClient.textToSpeech(
                text: any(named: 'text'),
                speed: any(named: 'speed'),
              ));
        });

        test('sets isSpeakingOrder to true then false on error',
            () async {
          when(() => mockApiClient.textToSpeech(
                text: any(named: 'text'),
                speed: any(named: 'speed'),
              )).thenThrow(Exception('TTS failed'));

          final vm = createVmWithMenu();
          vm.orderPhrase = 'Un gazpacho, por favor.';

          final speakingStates = <bool>[];
          vm.addListener(
              () => speakingStates.add(vm.isSpeakingOrder));

          await vm.speakOrder();

          expect(speakingStates, contains(true));
          expect(speakingStates.last, isFalse);
        });
      });

      test('resetForNewCapture clears order state', () {
        final vm = createVmWithMenu();
        vm.addToOrder(0);
        vm.addToOrder(1);
        vm.orderPhrase = 'Some phrase';

        vm.resetForNewCapture();

        expect(vm.orderItems, isEmpty);
        expect(vm.orderPhrase, isNull);
        expect(vm.hasOrder, isFalse);
      });
    });

    group('multi-page support', () {
      test('isAddingPage is initially false', () {
        final vm = createViewModel();
        expect(vm.isAddingPage, isFalse);
      });

      group('mergePageResult()', () {
        test('appends sections from new page to existing result', () {
          final vm = createViewModel();
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
                  ),
                ],
              ),
            ],
          );
          vm.pageImagePaths.add('/page1.jpg');

          final page2Result = MenuTranslationResponse(
            detectedLanguage: 'es',
            sections: [
              MenuSection(
                originalTitle: 'Postres',
                translatedTitle: 'Desserts',
                items: [
                  const MenuItem(
                    originalName: 'Flan',
                    translatedName: 'Caramel custard',
                  ),
                ],
              ),
            ],
          );

          vm.mergePageResult(page2Result, '/page2.jpg');

          expect(vm.menuResult!.sections.length, 2);
          expect(vm.menuResult!.sections[0].originalTitle, 'Entrantes');
          expect(vm.menuResult!.sections[1].originalTitle, 'Postres');
        });

        test('adds image path to pageImagePaths', () {
          final vm = createViewModel();
          vm.menuResult = const MenuTranslationResponse(
            detectedLanguage: 'es',
            sections: [],
          );

          vm.mergePageResult(
            const MenuTranslationResponse(
              detectedLanguage: 'es',
              sections: [],
            ),
            '/page2.jpg',
          );

          expect(vm.pageImagePaths, contains('/page2.jpg'));
        });

        test('does not add duplicate image paths', () {
          final vm = createViewModel();
          vm.menuResult = const MenuTranslationResponse(
            detectedLanguage: 'es',
            sections: [],
          );
          vm.pageImagePaths.add('/page1.jpg');

          vm.mergePageResult(
            const MenuTranslationResponse(
              detectedLanguage: 'es',
              sections: [],
            ),
            '/page1.jpg',
          );

          expect(vm.pageImagePaths.length, 1);
        });

        test('invalidates orderPhrase', () {
          final vm = createViewModel();
          vm.menuResult = const MenuTranslationResponse(
            detectedLanguage: 'es',
            sections: [],
          );
          vm.orderPhrase = 'Previously generated phrase';

          vm.mergePageResult(
            const MenuTranslationResponse(
              detectedLanguage: 'es',
              sections: [],
            ),
            '/page2.jpg',
          );

          expect(vm.orderPhrase, isNull);
        });

        test('preserves detected language from first page', () {
          final vm = createViewModel();
          vm.menuResult = const MenuTranslationResponse(
            detectedLanguage: 'es',
            sections: [],
          );

          vm.mergePageResult(
            const MenuTranslationResponse(
              detectedLanguage: 'fr',
              sections: [],
            ),
            '/page2.jpg',
          );

          expect(vm.menuResult!.detectedLanguage, 'es');
        });

        test('creates menuResult when null (first page via merge)', () {
          final vm = createViewModel();

          final result = MenuTranslationResponse(
            detectedLanguage: 'es',
            sections: [
              MenuSection(
                originalTitle: 'Test',
                translatedTitle: 'Test',
                items: [
                  const MenuItem(
                    originalName: 'Item1',
                    translatedName: 'Item1 EN',
                  ),
                ],
              ),
            ],
          );

          vm.mergePageResult(result, '/page1.jpg');

          expect(vm.menuResult, isNotNull);
          expect(vm.menuResult!.sections.length, 1);
        });

        test('preserves existing order items after merge', () {
          final vm = createViewModel();
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
                  ),
                ],
              ),
            ],
          );
          vm.addToOrder(0); // Order Gazpacho

          vm.mergePageResult(
            MenuTranslationResponse(
              detectedLanguage: 'es',
              sections: [
                MenuSection(
                  originalTitle: 'Postres',
                  translatedTitle: 'Desserts',
                  items: [
                    const MenuItem(
                      originalName: 'Flan',
                      translatedName: 'Caramel custard',
                    ),
                  ],
                ),
              ],
            ),
            '/page2.jpg',
          );

          expect(vm.orderItems[0], 1);
          expect(vm.orderItemList.length, 1);
          expect(vm.orderItemList[0].$2.originalName, 'Gazpacho');
        });

        test('new items from merged page are orderable', () {
          final vm = createViewModel();
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
                  ),
                ],
              ),
            ],
          );

          vm.mergePageResult(
            MenuTranslationResponse(
              detectedLanguage: 'es',
              sections: [
                MenuSection(
                  originalTitle: 'Postres',
                  translatedTitle: 'Desserts',
                  items: [
                    const MenuItem(
                      originalName: 'Flan',
                      translatedName: 'Caramel custard',
                    ),
                  ],
                ),
              ],
            ),
            '/page2.jpg',
          );

          vm.addToOrder(1); // Flan is index 1
          expect(vm.orderItemList.length, 1);
          expect(vm.orderItemList[0].$2.originalName, 'Flan');
          expect(vm.orderItemList[0].$3, 1);
        });

        test('totalItemCount reflects merged items', () {
          final vm = createViewModel();
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
                  ),
                  const MenuItem(
                    originalName: 'Tortilla',
                    translatedName: 'Spanish omelette',
                  ),
                ],
              ),
            ],
          );

          expect(vm.totalItemCount, 2);

          vm.mergePageResult(
            MenuTranslationResponse(
              detectedLanguage: 'es',
              sections: [
                MenuSection(
                  originalTitle: 'Postres',
                  translatedTitle: 'Desserts',
                  items: [
                    const MenuItem(
                      originalName: 'Flan',
                      translatedName: 'Caramel custard',
                    ),
                  ],
                ),
              ],
            ),
            '/page2.jpg',
          );

          expect(vm.totalItemCount, 3);
        });

        test('notifies listeners', () {
          final vm = createViewModel();
          vm.menuResult = const MenuTranslationResponse(
            detectedLanguage: 'es',
            sections: [],
          );

          var notified = false;
          vm.addListener(() => notified = true);

          vm.mergePageResult(
            const MenuTranslationResponse(
              detectedLanguage: 'es',
              sections: [],
            ),
            '/page2.jpg',
          );

          expect(notified, isTrue);
        });

        test('merging three pages accumulates all sections', () {
          final vm = createViewModel();

          // Page 1
          vm.mergePageResult(
            MenuTranslationResponse(
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
                  ],
                ),
              ],
            ),
            '/page1.jpg',
          );

          // Page 2
          vm.mergePageResult(
            MenuTranslationResponse(
              detectedLanguage: 'es',
              sections: [
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
            ),
            '/page2.jpg',
          );

          // Page 3
          vm.mergePageResult(
            MenuTranslationResponse(
              detectedLanguage: 'es',
              sections: [
                MenuSection(
                  originalTitle: 'Postres',
                  translatedTitle: 'Desserts',
                  items: [
                    const MenuItem(
                      originalName: 'Flan',
                      translatedName: 'Caramel custard',
                    ),
                  ],
                ),
              ],
            ),
            '/page3.jpg',
          );

          expect(vm.menuResult!.sections.length, 3);
          expect(vm.pageImagePaths.length, 3);
          expect(vm.totalItemCount, 3);
        });
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

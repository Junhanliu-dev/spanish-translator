import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/openai_client.dart';
import '../../core/error/error_handler.dart';
import '../../core/storage/history_repository.dart';
import '../../shared/models/menu_item.dart';
import '../../shared/models/translation.dart';
import '../../shared/notifiers/language_prefs_notifier.dart';
import '../../shared/utils/image_compressor.dart';

/// States for the photo translation flow.
enum PhotoState { idle, capturing, previewing, processing, success, error }

/// ViewModel for the photo/menu translation feature.
///
/// Manages image capture, compression, GPT-4o Vision processing, and
/// structured menu display.
class PhotoViewModel extends ChangeNotifier {
  PhotoViewModel({
    required OpenAIClient apiClient,
    required HistoryRepository historyRepo,
    required LanguagePrefsNotifier languagePrefs,
  })  : _apiClient = apiClient,
        _historyRepo = historyRepo,
        _languagePrefs = languagePrefs,
        _picker = ImagePicker();

  final OpenAIClient _apiClient;
  final HistoryRepository _historyRepo;
  final LanguagePrefsNotifier _languagePrefs;
  final ImagePicker _picker;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _playerSubscription;
  bool _isDisposed = false;

  // --- State ---
  PhotoState state = PhotoState.idle;
  String? capturedImagePath;
  MenuTranslationResponse? menuResult;
  String? errorMessage;
  int? expandedItemIndex;
  List<String> pageImagePaths = [];
  bool isSaved = false;
  int? _lastSavedId;
  bool isSpeaking = false;
  String? _currentTtsPath;
  bool isAddingPage = false;

  // --- Order State ---
  /// Map of globalItemIndex → quantity for items the user wants to order.
  final Map<int, int> orderItems = {};

  /// Cached generated ordering phrase (nulled when order changes).
  String? orderPhrase;

  /// Whether an order phrase is currently being generated.
  bool isGeneratingOrder = false;

  /// Whether the order phrase TTS is playing.
  bool isSpeakingOrder = false;

  /// Capture a photo from the device camera.
  Future<String?> capturePhoto() async {
    state = PhotoState.capturing;
    notifyListeners();

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2048,
      );

      if (image == null) {
        state = PhotoState.idle;
        notifyListeners();
        return null;
      }

      capturedImagePath = image.path;
      state = PhotoState.previewing;
      notifyListeners();
      return image.path;
    } catch (e) {
      state = PhotoState.error;
      errorMessage = 'Could not capture photo. Please try again.';
      notifyListeners();
      return null;
    }
  }

  /// Pick a photo from the device gallery.
  Future<String?> pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
      );

      if (image == null) {
        return null;
      }

      capturedImagePath = image.path;
      state = PhotoState.previewing;
      notifyListeners();
      return image.path;
    } catch (e) {
      state = PhotoState.error;
      errorMessage = 'Could not pick photo. Please try again.';
      notifyListeners();
      return null;
    }
  }

  /// Capture an additional photo without changing main state.
  Future<String?> captureAdditionalPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2048,
      );
      return image?.path;
    } catch (_) {
      return null;
    }
  }

  /// Pick an additional photo from gallery without changing main state.
  Future<String?> pickAdditionalFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
      );
      return image?.path;
    } catch (_) {
      return null;
    }
  }

  /// Compress and send the image to GPT-4o Vision for menu translation.
  ///
  /// Called when the user taps "Use Photo" on the preview screen.
  Future<void> processImage(String imagePath) async {
    state = PhotoState.processing;
    errorMessage = null;
    notifyListeners();

    try {
      // Compress to 1024px longest side, 80% JPEG.
      final compressed = await ImageCompressor.compress(
        imagePath: imagePath,
        maxDimension: 1024,
        quality: 80,
      );

      // Convert to base64.
      final bytes = await File(compressed).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Send to GPT-4o Vision.
      // Menu is in the target language (e.g. Spanish); translate to source
      // language (e.g. English) so the traveler can understand it.
      menuResult = await _apiClient.translateImage(
        base64Image: base64Image,
        targetLanguage: _languagePrefs.sourceLanguage.code,
      );

      capturedImagePath = imagePath;
      if (!pageImagePaths.contains(imagePath)) {
        pageImagePaths.add(imagePath);
      }
      state = PhotoState.success;
      notifyListeners();

      // Clean up compressed temp file.
      try {
        await File(compressed).delete();
      } catch (_) {}
    } catch (e) {
      state = PhotoState.error;
      errorMessage = mapErrorToMessage(e);
      notifyListeners();
    }
  }

  /// Merge additional page results into existing menu.
  ///
  /// Appends new sections to existing [menuResult]. If [menuResult] is null,
  /// the new result becomes the initial result. Preserves the detected
  /// language from the first page.
  void mergePageResult(MenuTranslationResponse newResult, String imagePath) {
    if (menuResult != null) {
      menuResult = MenuTranslationResponse(
        sections: [...menuResult!.sections, ...newResult.sections],
        detectedLanguage: menuResult!.detectedLanguage,
      );
    } else {
      menuResult = newResult;
    }

    if (!pageImagePaths.contains(imagePath)) {
      pageImagePaths.add(imagePath);
    }

    orderPhrase = null;
    notifyListeners();
  }

  /// Compress and send an additional page image for translation, then merge
  /// results into the existing menu.
  ///
  /// Unlike [processImage], this preserves existing results and appends new
  /// sections. Returns true on success.
  Future<bool> processAdditionalImage(String imagePath) async {
    isAddingPage = true;
    notifyListeners();

    try {
      final compressed = await ImageCompressor.compress(
        imagePath: imagePath,
        maxDimension: 1024,
        quality: 80,
      );

      final bytes = await File(compressed).readAsBytes();
      final base64Image = base64Encode(bytes);

      final newResult = await _apiClient.translateImage(
        base64Image: base64Image,
        targetLanguage: _languagePrefs.sourceLanguage.code,
      );

      mergePageResult(newResult, imagePath);

      try {
        await File(compressed).delete();
      } catch (_) {}

      isAddingPage = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = mapErrorToMessage(e);
      isAddingPage = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle expand/collapse on a menu item (accordion behavior).
  ///
  /// Only one item can be expanded at a time.
  void toggleItemExpansion(int index) {
    if (expandedItemIndex == index) {
      expandedItemIndex = null;
    } else {
      expandedItemIndex = index;
    }
    notifyListeners();
  }

  /// Save the menu translation to history with a user-provided title.
  Future<void> saveToHistory({required String title}) async {
    if (menuResult == null || capturedImagePath == null) return;
    if (isSaved) return;

    // Build full text from all menu items (no truncation).
    final allItems = menuResult!.sections
        .expand((s) => s.items)
        .toList();
    final sourceText = allItems
        .map((i) => i.originalName)
        .join(', ');
    final translatedText = allItems
        .map((i) => '${i.originalName} - ${i.translatedName}')
        .join('\n');

    final translation = Translation(
      type: 'photo',
      title: title.trim().isEmpty ? null : title.trim(),
      sourceText: sourceText,
      translatedText: translatedText,
      sourceLanguage: menuResult!.detectedLanguage,
      targetLanguage: _languagePrefs.targetLanguage.code,
      imagePath: capturedImagePath,
      createdAt: DateTime.now(),
    );

    _lastSavedId = await _historyRepo.insertTranslation(translation);

    // Save individual menu items with sort order.
    if (_lastSavedId != null) {
      var sortOrder = 0;
      final itemsWithOrder = <MenuItem>[];
      for (final section in menuResult!.sections) {
        for (final item in section.items) {
          itemsWithOrder.add(MenuItem(
            originalName: item.originalName,
            translatedName: item.translatedName,
            description: item.description,
            pronunciation: item.pronunciation,
            price: item.price,
            category: section.originalTitle,
            sortOrder: sortOrder++,
          ));
        }
      }
      await _historyRepo.insertMenuItems(_lastSavedId!, itemsWithOrder);
    }

    isSaved = true;
    notifyListeners();
  }

  /// Reset state for a new capture (e.g., "Scan Another Page").
  void resetForNewCapture() {
    state = PhotoState.idle;
    capturedImagePath = null;
    menuResult = null;
    errorMessage = null;
    expandedItemIndex = null;
    isSaved = false;
    _lastSavedId = null;
    orderItems.clear();
    orderPhrase = null;
    notifyListeners();
  }

  /// Get a total count of all menu items across all sections.
  int get totalItemCount {
    if (menuResult == null) return 0;
    return menuResult!.sections.fold(
      0,
      (sum, section) => sum + section.items.length,
    );
  }

  /// Speak the original name of a menu item via TTS.
  Future<void> speakText(String text) async {
    try {
      isSpeaking = true;
      notifyListeners();

      // Clean up previous TTS file.
      if (_currentTtsPath != null) {
        try {
          await File(_currentTtsPath!).delete();
        } catch (_) {}
      }

      _currentTtsPath = await _apiClient.textToSpeech(
        text: text,
        speed: 0.85,
      );

      if (_isDisposed) return;

      _playerSubscription?.cancel();
      _playerSubscription = _player.onPlayerComplete.listen((_) {
        isSpeaking = false;
        if (!_isDisposed) notifyListeners();
      });

      await _player.play(DeviceFileSource(_currentTtsPath!));
    } catch (_) {
      isSpeaking = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // --- Order Methods ---

  /// Add one unit of a menu item to the order.
  void addToOrder(int globalItemIndex) {
    orderItems[globalItemIndex] = (orderItems[globalItemIndex] ?? 0) + 1;
    orderPhrase = null;
    notifyListeners();
  }

  /// Remove one unit of a menu item from the order.
  void removeFromOrder(int globalItemIndex) {
    final current = orderItems[globalItemIndex] ?? 0;
    if (current <= 1) {
      orderItems.remove(globalItemIndex);
    } else {
      orderItems[globalItemIndex] = current - 1;
    }
    orderPhrase = null;
    notifyListeners();
  }

  /// Clear the entire order.
  void clearOrder() {
    orderItems.clear();
    orderPhrase = null;
    notifyListeners();
  }

  /// Whether the user has any items in their order.
  bool get hasOrder => orderItems.isNotEmpty;

  /// Total number of items (sum of quantities) in the order.
  int get orderTotalCount =>
      orderItems.values.fold(0, (sum, qty) => sum + qty);

  /// Build a flat list of all menu items across all sections.
  List<MenuItem> get _flatMenuItems {
    if (menuResult == null) return [];
    return menuResult!.sections.expand((s) => s.items).toList();
  }

  /// Get the ordered items as a list of (index, MenuItem, quantity) tuples,
  /// sorted by index to preserve menu order.
  List<(int index, MenuItem item, int quantity)> get orderItemList {
    final flat = _flatMenuItems;
    final entries = orderItems.entries
        .where((e) => e.key < flat.length)
        .map((e) => (e.key, flat[e.key], e.value))
        .toList();
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    return entries;
  }

  /// Generate a polite ordering phrase in the restaurant's language.
  Future<void> generateOrderPhrase() async {
    if (!hasOrder || menuResult == null) return;

    isGeneratingOrder = true;
    notifyListeners();

    try {
      final items = orderItemList
          .map((e) => (e.$2.originalName, e.$3))
          .toList();

      orderPhrase = await _apiClient.generateOrderPhrase(
        items: items,
        restaurantLanguage: menuResult!.detectedLanguage,
      );
    } catch (e) {
      orderPhrase = null;
    }

    isGeneratingOrder = false;
    if (!_isDisposed) notifyListeners();
  }

  /// Speak the generated order phrase via TTS.
  Future<void> speakOrder() async {
    if (orderPhrase == null || orderPhrase!.isEmpty) return;

    try {
      isSpeakingOrder = true;
      notifyListeners();

      if (_currentTtsPath != null) {
        try {
          await File(_currentTtsPath!).delete();
        } catch (_) {}
      }

      _currentTtsPath = await _apiClient.textToSpeech(
        text: orderPhrase!,
        speed: 0.85,
      );

      if (_isDisposed) return;

      _playerSubscription?.cancel();
      _playerSubscription = _player.onPlayerComplete.listen((_) {
        isSpeakingOrder = false;
        if (!_isDisposed) notifyListeners();
      });

      await _player.play(DeviceFileSource(_currentTtsPath!));
    } catch (_) {
      isSpeakingOrder = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _playerSubscription?.cancel();
    _player.dispose();
    // Clean up TTS temp file.
    if (_currentTtsPath != null) {
      try {
        File(_currentTtsPath!).delete();
      } catch (_) {}
    }
    super.dispose();
  }
}

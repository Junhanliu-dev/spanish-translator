import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/openai_client.dart';
import '../../core/error/error_handler.dart';
import '../../core/storage/history_repository.dart';
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

  // --- State ---
  PhotoState state = PhotoState.idle;
  String? capturedImagePath;
  MenuTranslationResponse? menuResult;
  String? errorMessage;
  int? expandedItemIndex;
  List<String> pageImagePaths = [];
  bool isSaved = false;
  int? _lastSavedId;

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
      menuResult = await _apiClient.translateImage(
        base64Image: base64Image,
        targetLanguage: _languagePrefs.targetLanguage.code,
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

  /// Save the menu translation to history.
  Future<void> saveToHistory() async {
    if (menuResult == null || capturedImagePath == null) return;
    if (isSaved) return;

    // Build summary text from menu items.
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
      sourceText: sourceText.length > 200
          ? '${sourceText.substring(0, 200)}...'
          : sourceText,
      translatedText: translatedText.length > 500
          ? '${translatedText.substring(0, 500)}...'
          : translatedText,
      sourceLanguage: menuResult!.detectedLanguage,
      targetLanguage: _languagePrefs.targetLanguage.code,
      imagePath: capturedImagePath,
      createdAt: DateTime.now(),
    );

    _lastSavedId = await _historyRepo.insertTranslation(translation);

    // Save individual menu items.
    if (_lastSavedId != null) {
      await _historyRepo.insertMenuItems(_lastSavedId!, allItems);
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
}

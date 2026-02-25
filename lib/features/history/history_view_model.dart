import 'package:flutter/foundation.dart';

import '../../core/storage/history_repository.dart';
import '../../shared/models/translation.dart';

/// ViewModel for the History screen.
///
/// Manages translation list state including filtering, search, and CRUD.
class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({required HistoryRepository historyRepo})
      : _historyRepo = historyRepo;

  final HistoryRepository _historyRepo;

  /// The current list of translations.
  List<Translation> translations = [];

  /// Active type filter: null = all, 'speech', 'photo', 'text'.
  String? activeFilter;

  /// Current search query.
  String searchQuery = '';

  /// Whether the search bar is visible.
  bool isSearchVisible = false;

  /// Whether data is currently loading.
  bool isLoading = false;

  /// Load translations with current filter and search.
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      translations = await _historyRepo.getTranslations(
        typeFilter: activeFilter,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
      );
    } catch (_) {
      translations = [];
    }

    isLoading = false;
    notifyListeners();
  }

  /// Set type filter and reload.
  Future<void> setFilter(String? filter) async {
    activeFilter = filter;
    await load();
  }

  /// Set search query and reload.
  Future<void> setSearchQuery(String query) async {
    searchQuery = query;
    await load();
  }

  /// Toggle search bar visibility.
  void toggleSearch() {
    isSearchVisible = !isSearchVisible;
    if (!isSearchVisible && searchQuery.isNotEmpty) {
      searchQuery = '';
      load();
    }
    notifyListeners();
  }

  /// Delete a translation by ID. Returns the deleted item for undo.
  Future<Translation?> deleteTranslation(int id) async {
    final index = translations.indexWhere((t) => t.id == id);
    if (index == -1) return null;

    final deleted = translations[index];
    translations.removeAt(index);
    notifyListeners();

    try {
      await _historyRepo.deleteTranslation(id);
    } catch (_) {
      // Re-insert on failure.
      translations.insert(index, deleted);
      notifyListeners();
      return null;
    }

    return deleted;
  }

  /// Undo a deletion (re-insert).
  Future<void> undoDelete(Translation translation) async {
    try {
      await _historyRepo.insertTranslation(translation);
      await load();
    } catch (_) {
      // Silent failure on undo.
    }
  }

  /// Toggle favorite on an item.
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final index = translations.indexWhere((t) => t.id == id);
    if (index == -1) return;

    translations[index] =
        translations[index].copyWith(isFavorite: !isFavorite);
    notifyListeners();

    try {
      await _historyRepo.toggleFavorite(id, !isFavorite);
    } catch (_) {
      // Revert on failure.
      translations[index] =
          translations[index].copyWith(isFavorite: isFavorite);
      notifyListeners();
    }
  }

  /// Group translations by date for display.
  Map<String, List<Translation>> get groupedByDate {
    final groups = <String, List<Translation>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final t in translations) {
      final date = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      String label;
      if (date == today) {
        label = 'Today';
      } else if (date == yesterday) {
        label = 'Yesterday';
      } else {
        label =
            '${_monthName(date.month)} ${date.day}';
      }
      groups.putIfAbsent(label, () => []).add(t);
    }
    return groups;
  }

  static String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }
}

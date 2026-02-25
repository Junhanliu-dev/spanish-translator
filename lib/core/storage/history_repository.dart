import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../shared/models/menu_item.dart';
import '../../shared/models/translation.dart';
import '../error/app_exception.dart';

/// SQLite-backed repository for translation history.
/// Enforces a 500-entry limit, auto-pruning oldest non-favorited entries.
class HistoryRepository {
  late final Database _db;

  /// Initialize the database. Must be called before any other method.
  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'linguaviaje.db'),
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        source_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        source_language TEXT NOT NULL,
        target_language TEXT NOT NULL,
        context TEXT,
        pronunciation TEXT,
        image_path TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        translation_id INTEGER NOT NULL,
        original_name TEXT NOT NULL,
        translated_name TEXT NOT NULL,
        description TEXT,
        pronunciation TEXT,
        price TEXT,
        category TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (translation_id)
          REFERENCES translations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_translations_created_at '
      'ON translations(created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_translations_type ON translations(type)',
    );
    await db.execute(
      'CREATE INDEX idx_translations_favorite '
      'ON translations(is_favorite)',
    );
  }

  /// Insert a translation. Enforces 500-entry limit by pruning.
  Future<int> insertTranslation(Translation translation) async {
    try {
      final id = await _db.insert('translations', translation.toMap());
      await _enforceLimit();
      return id;
    } catch (e) {
      throw StorageException('Failed to insert translation', cause: e);
    }
  }

  /// Insert menu items for a photo translation.
  Future<void> insertMenuItems(
    int translationId,
    List<MenuItem> items,
  ) async {
    try {
      final batch = _db.batch();
      for (final item in items) {
        final map = item.toMap();
        map['translation_id'] = translationId;
        batch.insert('menu_items', map);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw StorageException('Failed to insert menu items', cause: e);
    }
  }

  /// Query translations with optional type filter and search.
  Future<List<Translation>> getTranslations({
    String? typeFilter,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final where = <String>[];
      final whereArgs = <dynamic>[];

      if (typeFilter != null) {
        where.add('type = ?');
        whereArgs.add(typeFilter);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        where.add(
          '(source_text LIKE ? OR translated_text LIKE ?)',
        );
        final pattern = '%$searchQuery%';
        whereArgs.addAll([pattern, pattern]);
      }

      final results = await _db.query(
        'translations',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return results.map(Translation.fromMap).toList();
    } catch (e) {
      throw StorageException('Failed to query translations', cause: e);
    }
  }

  /// Get menu items for a photo translation.
  Future<List<MenuItem>> getMenuItems(int translationId) async {
    try {
      final results = await _db.query(
        'menu_items',
        where: 'translation_id = ?',
        whereArgs: [translationId],
        orderBy: 'sort_order ASC',
      );

      return results.map(MenuItem.fromMap).toList();
    } catch (e) {
      throw StorageException('Failed to query menu items', cause: e);
    }
  }

  /// Toggle favorite status.
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    try {
      await _db.update(
        'translations',
        {'is_favorite': isFavorite ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw StorageException('Failed to toggle favorite', cause: e);
    }
  }

  /// Delete a single translation (and its menu items via CASCADE).
  Future<void> deleteTranslation(int id) async {
    try {
      await _db.delete(
        'translations',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw StorageException('Failed to delete translation', cause: e);
    }
  }

  /// Enforce 500-entry limit. Deletes oldest non-favorite entries.
  Future<void> _enforceLimit() async {
    final count = Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM translations'),
        ) ??
        0;
    if (count > 500) {
      final excess = count - 500;
      await _db.rawDelete(
        '''
        DELETE FROM translations WHERE id IN (
          SELECT id FROM translations
          WHERE is_favorite = 0
          ORDER BY created_at ASC
          LIMIT ?
        )
        ''',
        [excess],
      );
    }
  }

  /// Get the most recent translations (for home screen preview).
  Future<List<Translation>> getRecentTranslations({int limit = 3}) async {
    try {
      final results = await _db.query(
        'translations',
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return results.map(Translation.fromMap).toList();
    } catch (e) {
      throw StorageException(
        'Failed to query recent translations',
        cause: e,
      );
    }
  }

  /// Search translations (source + translated text, case-insensitive).
  Future<List<Translation>> search(String query) async {
    try {
      final pattern = '%$query%';
      final results = await _db.query(
        'translations',
        where: 'source_text LIKE ? OR translated_text LIKE ?',
        whereArgs: [pattern, pattern],
        orderBy: 'created_at DESC',
        limit: 50,
      );

      return results.map(Translation.fromMap).toList();
    } catch (e) {
      throw StorageException('Failed to search translations', cause: e);
    }
  }
}

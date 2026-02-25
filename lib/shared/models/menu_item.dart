/// A single item from a translated menu.
class MenuItem {
  final int? id;
  final String originalName;
  final String translatedName;
  final String? description; // e.g., "salt cod in garlic olive oil emulsion"
  final String? pronunciation; // e.g., "bah-kah-LAH-oh al peel-PEEL"
  final String? price; // e.g., "EUR 14.00"
  final String? category; // e.g., "Starters", "Mains"
  final int sortOrder;

  const MenuItem({
    this.id,
    required this.originalName,
    required this.translatedName,
    this.description,
    this.pronunciation,
    this.price,
    this.category,
    this.sortOrder = 0,
  });

  /// Create from SQLite row.
  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as int?,
      originalName: map['original_name'] as String,
      translatedName: map['translated_name'] as String,
      description: map['description'] as String?,
      pronunciation: map['pronunciation'] as String?,
      price: map['price'] as String?,
      category: map['category'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  /// Convert to SQLite row (without translation_id, which is set externally).
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'original_name': originalName,
      'translated_name': translatedName,
      'description': description,
      'pronunciation': pronunciation,
      'price': price,
      'category': category,
      'sort_order': sortOrder,
    };
  }
}

/// A single translation record stored in history.
class Translation {
  final int? id;
  final String type; // 'speech' | 'photo' | 'text'
  final String sourceText;
  final String translatedText;
  final String sourceLanguage; // 'en' | 'zh' | 'es' | 'eu'
  final String targetLanguage;
  final String? title; // user-provided title (e.g. for saved menus)
  final String? context; // contextual explanation
  final String? pronunciation; // pronunciation guide
  final String? imagePath; // local path for photo translations
  final bool isFavorite;
  final DateTime createdAt;

  const Translation({
    this.id,
    required this.type,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.title,
    this.context,
    this.pronunciation,
    this.imagePath,
    this.isFavorite = false,
    required this.createdAt,
  });

  /// Create from SQLite row.
  factory Translation.fromMap(Map<String, dynamic> map) {
    return Translation(
      id: map['id'] as int?,
      type: map['type'] as String,
      sourceText: map['source_text'] as String,
      translatedText: map['translated_text'] as String,
      sourceLanguage: map['source_language'] as String,
      targetLanguage: map['target_language'] as String,
      title: map['title'] as String?,
      context: map['context'] as String?,
      pronunciation: map['pronunciation'] as String?,
      imagePath: map['image_path'] as String?,
      isFavorite: (map['is_favorite'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite row.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'source_text': sourceText,
      'translated_text': translatedText,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'title': title,
      'context': context,
      'pronunciation': pronunciation,
      'image_path': imagePath,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields.
  Translation copyWith({
    int? id,
    String? type,
    String? sourceText,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    String? title,
    String? context,
    String? pronunciation,
    String? imagePath,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Translation(
      id: id ?? this.id,
      type: type ?? this.type,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      title: title ?? this.title,
      context: context ?? this.context,
      pronunciation: pronunciation ?? this.pronunciation,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

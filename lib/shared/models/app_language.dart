/// Source language (what the user speaks).
enum AppLanguage {
  english('en', 'English', 'EN'),
  mandarin('zh', 'Mandarin', 'ZH');

  const AppLanguage(this.code, this.displayName, this.shortCode);

  /// ISO 639-1 language code.
  final String code;

  /// Human-readable display name.
  final String displayName;

  /// Two-letter uppercase abbreviation for badges.
  final String shortCode;

  /// Look up an [AppLanguage] by its [code]. Defaults to [english].
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Target language for translation (Spanish or Basque).
enum TargetLanguage {
  spanish('es', 'Spanish', 'ES'),
  basque('eu', 'Basque', 'EU');

  const TargetLanguage(this.code, this.displayName, this.shortCode);

  /// ISO 639-1 language code.
  final String code;

  /// Human-readable display name.
  final String displayName;

  /// Two-letter uppercase abbreviation for badges.
  final String shortCode;

  /// Look up a [TargetLanguage] by its [code]. Defaults to [spanish].
  static TargetLanguage fromCode(String code) {
    return TargetLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => TargetLanguage.spanish,
    );
  }
}

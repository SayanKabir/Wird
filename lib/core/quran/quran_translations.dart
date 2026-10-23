/// A translation available from the Quran.com API.
class TranslationOption {
  /// Quran.com translation resource id.
  final int id;
  final String language;

  /// Short name shown on chips.
  final String name;
  final bool isRtl;

  /// Edition name in the open fawazahmed0 Quran dataset, for translations
  /// Quran.com's public API no longer serves. Null means Quran.com.
  final String? cdnEdition;

  const TranslationOption({
    required this.id,
    required this.language,
    required this.name,
    this.isRtl = false,
    this.cdnEdition,
  });
}

/// Translations offered in the reader, grouped by language.
class QuranTranslations {
  const QuranTranslations._();

  static const int defaultId = 20;

  static const List<TranslationOption> all = [
    TranslationOption(id: 20, language: 'English', name: 'Saheeh International'),
    // The Clear Quran was pulled from Quran.com's public API; 131 is its
    // Quran.com id, kept so the setting reads naturally.
    TranslationOption(id: 131, language: 'English', name: 'Mustafa Khattab', cdnEdition: 'eng-mustafakhattaba'),
    TranslationOption(id: 85, language: 'English', name: 'Abdel Haleem'),
    TranslationOption(id: 84, language: 'English', name: 'Taqi Usmani'),
    TranslationOption(id: 22, language: 'English', name: 'Yusuf Ali'),
    TranslationOption(id: 19, language: 'English', name: 'Pickthall'),
    TranslationOption(id: 203, language: 'English', name: 'Hilali & Khan'),
    TranslationOption(id: 122, language: 'Hindi', name: 'Azizul Haque al-Umari'),
    TranslationOption(id: 161, language: 'Bangla', name: 'Taisirul Quran'),
    TranslationOption(id: 163, language: 'Bangla', name: 'Mujibur Rahman'),
    TranslationOption(id: 213, language: 'Bangla', name: 'Abu Bakr Zakaria'),
    TranslationOption(id: 162, language: 'Bangla', name: 'Rawai al-Bayan'),
    TranslationOption(id: 234, language: 'Urdu', name: 'Jalandhari', isRtl: true),
    TranslationOption(id: 54, language: 'Urdu', name: 'Junagarhi', isRtl: true),
    TranslationOption(id: 97, language: 'Urdu', name: 'Maududi', isRtl: true),
    TranslationOption(id: 33, language: 'Indonesian', name: 'Kemenag'),
    TranslationOption(id: 77, language: 'Turkish', name: 'Diyanet'),
    TranslationOption(id: 136, language: 'French', name: 'Montada'),
  ];

  static List<String> get languages => all.map((t) => t.language).toSet().toList();

  static List<TranslationOption> forLanguage(String language) =>
      all.where((t) => t.language == language).toList();

  static TranslationOption byId(int id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);

  /// Settings store the translation as a string. Older versions stored a
  /// display name; newer ones store the numeric id.
  static TranslationOption resolve(String? stored) {
    final id = int.tryParse(stored ?? '');
    if (id != null) return byId(id);
    switch (stored) {
      case 'Mustafa Khattab':
        return byId(131);
      case 'Yusuf Ali':
        return byId(22);
      default:
        return byId(defaultId);
    }
  }
}

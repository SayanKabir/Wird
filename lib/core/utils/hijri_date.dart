/// Hijri (Islamic) date utility
/// Uses the Umm al-Qura calendar approximation
class HijriDate {
  final int year;
  final int month;
  final int day;

  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
  });

  /// Convert Gregorian date to Hijri date
  factory HijriDate.fromGregorian(DateTime date) {
    // Julian Day Number calculation
    final jd = _gregorianToJulian(date.year, date.month, date.day);
    return _julianToHijri(jd);
  }

  /// Get the Hijri month name in Arabic
  String get monthNameArabic {
    const months = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الثاني',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    return months[month - 1];
  }

  /// Get the Hijri month name in English
  String get monthNameEnglish {
    const months = [
      'Muharram',
      'Safar',
      'Rabi\' al-Awwal',
      'Rabi\' al-Thani',
      'Jumada al-Ula',
      'Jumada al-Thani',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qi\'dah',
      'Dhu al-Hijjah',
    ];
    return months[month - 1];
  }

  /// Format as "Day MonthName Year" in Arabic
  String formatArabic() {
    return '$day $monthNameArabic $year';
  }

  /// Format as "Day MonthName Year" in English
  String formatEnglish() {
    return '$day $monthNameEnglish $year';
  }

  /// Format as "Day MonthName" (short format)
  String formatShort() {
    return '$day ${monthNameEnglish.split(' ').first}';
  }

  @override
  String toString() => formatEnglish();

  // ============================================
  // CALCULATION HELPERS
  // ============================================

  static int _gregorianToJulian(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524;
  }

  static HijriDate _julianToHijri(int jd) {
    // Adjusted calculation for better accuracy
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l2 = l - 10631 * n + 354;
    final j = ((10985 - l2) / 5316).floor() * ((50 * l2 / 17719).floor()) +
        (l2 / 5670).floor() * ((43 * l2 / 15238).floor());
    final l3 = l2 - ((30 - j) / 15).floor() * ((17719 * j / 50).floor()) -
        (j / 16).floor() * ((15238 * j / 43).floor()) + 29;
    final month = (24 * l3 / 709).floor();
    final day = l3 - (709 * month / 24).floor();
    final year = 30 * n + j - 30;

    return HijriDate(year: year, month: month, day: day);
  }
}

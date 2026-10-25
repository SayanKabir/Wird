/// Corner radii. Every rounded surface in Wird uses one of these, so cards,
/// groups and sheets read as one family.
class AppRadii {
  AppRadii._();

  /// Small controls: badges, icon buttons with a square-ish shape.
  static const double control = 12;

  /// Cards and list rows.
  static const double card = 16;

  /// Grouped lists and hero cards.
  static const double group = 20;

  /// Large glass panels and dialogs.
  static const double panel = 24;

  /// Top corners of bottom sheets.
  static const double sheet = 28;

  /// Fully rounded ends for chips and pill buttons.
  static const double pill = 999;
}

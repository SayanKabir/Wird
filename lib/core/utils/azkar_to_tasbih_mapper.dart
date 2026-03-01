import '../../models/azkar.dart';
import '../../models/tasbih_flow.dart';

class AzkarToTasbihMapper {
  /// Converts a strict list of [Azkar] directly into a dynamic [TasbihFlow]
  static TasbihFlow toTasbihFlow({
    required String flowId,
    required String flowName,
    required List<Azkar> azkarList,
  }) {
    final phases = azkarList.map((azkar) {
      return TasbihFlowPhase(
        tasbihId: azkar.id,
        label: _generateLabelFromCategory(azkar.category),
        target: azkar.repetitions,
        arabic: azkar.arabic,
        transliteration: azkar.transliteration,
        translation: azkar.translation,
        virtue: azkar.virtue,
      );
    }).toList();

    return TasbihFlow(
      id: flowId,
      name: flowName,
      phases: phases,
    );
  }

  static String _generateLabelFromCategory(AzkarCategory category) {
    switch (category) {
      case AzkarCategory.morning:
        return 'Morning Azkar';
      case AzkarCategory.evening:
        return 'Evening Azkar';
      case AzkarCategory.beforeSleep:
        return 'Before Sleep Azkar';
      case AzkarCategory.afterPrayer:
        return 'After-Prayer Azkar';
      case AzkarCategory.wakingUp:
        return 'Waking Up Azkar';
      case AzkarCategory.mosque:
        return 'Mosque Azkar';
      case AzkarCategory.wudu:
        return 'Wudu Azkar';
      case AzkarCategory.food:
        return 'Food Azkar';
      case AzkarCategory.home:
        return 'Home Azkar';
      case AzkarCategory.travel:
        return 'Travel Azkar';
      case AzkarCategory.hajjUmrah:
        return 'Hajj & Umrah Azkar';
      case AzkarCategory.nature:
        return 'Nature Azkar';
    }
  }
}

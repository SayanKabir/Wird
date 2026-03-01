/// A single phase within a multi-phase tasbih flow.
///
/// Each phase represents one dhikr to be counted a specific number of times
/// before advancing to the next phase. For example, Tasbih of Fatimah has
/// three phases: SubhanAllah ×33, Alhamdulillah ×33, Allahu Akbar ×34.
class TasbihFlowPhase {
  final String tasbihId;
  final String label;
  final int target;
  final String? arabic;
  final String? transliteration;
  final String? translation;
  final String? virtue;

  const TasbihFlowPhase({
    required this.tasbihId,
    required this.label,
    required this.target,
    this.arabic,
    this.transliteration,
    this.translation,
    this.virtue,
  });
}

/// A multi-phase tasbih flow that sequences through several dhikr phases.
///
/// The tasbih screen uses this to automatically advance through each phase
/// with the correct target count, content card text, and completion feedback.
class TasbihFlow {
  final String id;
  final String name;
  final List<TasbihFlowPhase> phases;

  const TasbihFlow({
    required this.id,
    required this.name,
    required this.phases,
  });

  int get totalCount => phases.fold(0, (sum, p) => sum + p.target);
}

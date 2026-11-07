import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/dhikr/dhikr_catalog.dart';
import '../../models/tasbih.dart';
import '../tasbih/bloc/tasbih_bloc.dart';
import 'bloc/sunnah_bloc.dart';

/// Ticks a Sunnah in the practice once its dhikr is said: when a counter
/// reaches the count the Sunnah asks for today. Only the moment it gets
/// there counts, so a tick taken back by hand stays off while counting goes
/// on. Guided sessions tick theirs when they finish (see SessionScreen).
class PracticeKeeper extends StatefulWidget {
  final Widget child;

  const PracticeKeeper({super.key, required this.child});

  @override
  State<PracticeKeeper> createState() => _PracticeKeeperState();
}

class _PracticeKeeperState extends State<PracticeKeeper> {
  /// The counters as they stood before the latest change.
  List<Tasbih>? _before;

  @override
  void initState() {
    super.initState();
    final state = context.read<TasbihBloc>().state;
    if (state is TasbihLoaded) _before = state.tasbihs;
  }

  void _onCounters(BuildContext context, TasbihState state) {
    if (state is! TasbihLoaded) return;
    final before = _before;
    _before = state.tasbihs;
    // The first load is where counting stood, not counting just done.
    if (before == null) return;

    final sunnahBloc = context.read<SunnahBloc>();
    final sunnah = sunnahBloc.state;
    if (sunnah is! SunnahLoaded || sunnah.progress.practiceIds.isEmpty) return;
    Set<String> kept(List<Tasbih> counters) => DhikrCatalog.keptByCounters(
          sunnahs: sunnah.sunnahs,
          practiceIds: sunnah.progress.practiceIds,
          counters: counters,
        );
    final newly = kept(state.tasbihs).difference(kept(before));
    if (newly.isNotEmpty) sunnahBloc.add(MarkPracticeDone(newly.toList()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TasbihBloc, TasbihState>(
      listener: _onCounters,
      child: widget.child,
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/dhikr/dhikr_catalog.dart';
import '../../models/sunnah.dart';
import '../tasbih/bloc/tasbih_bloc.dart';
import 'bloc/sunnah_bloc.dart';

/// Adds [sunnah] to the user's practice, or takes it out. A dhikr Sunnah with
/// words of its own also gets a counter on the dhikr page while it's there.
void toggleSunnahPractice(BuildContext context, Sunnah sunnah, {required bool inPractice}) {
  context.read<SunnahBloc>().add(ToggleSunnahPractice(sunnah.id));
  if (!DhikrCatalog.sunnahNeedsCounter(sunnah)) return;
  final tasbih = context.read<TasbihBloc>();
  final id = DhikrCatalog.counterIdForSunnah(sunnah.id);
  if (inPractice) {
    tasbih.add(UnlinkSunnahCounter(id));
  } else {
    tasbih.add(LinkSunnahCounter(id, DhikrCatalog.counterNameForSunnah(sunnah), DhikrCatalog.counterTargetForSunnah(sunnah)));
  }
}

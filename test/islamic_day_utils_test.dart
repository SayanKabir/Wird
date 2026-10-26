import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/utils/islamic_day_utils.dart';
import 'package:wird2/widgets/common/festive_canopy.dart';

void main() {
  test('the lanterns come out for Ramadan, the Eids and Arafah only', () {
    final start = DateTime(2027, 1, 1);
    final decorated = <DateTime, CanopyMood>{
      for (var i = 0; i < 365; i++)
        if (IslamicDayUtils.canopyFor(start.add(Duration(days: i))) case final mood?)
          start.add(Duration(days: i)): mood,
    };
    // Ramadan (29 or 30 days), Eid al-Fitr, Arafah and Eid al-Adha.
    expect(decorated.length, inInclusiveRange(32, 33));
    expect(decorated[DateTime(2027, 2, 20)], CanopyMood.night);
    expect(decorated[DateTime(2027, 3, 11)], CanopyMood.celebration);
    // Fridays and the White Days stay plain.
    expect(IslamicDayUtils.canopyFor(DateTime(2027, 1, 1)), isNull);
  });

  test('daytime occasions match the Hijri day the calendar shows', () {
    // The calendar labels 9 Feb 2027 as 1 Ramadan.
    final first = IslamicDayUtils.messageForDaytime(DateTime(2027, 2, 9));
    final eve = IslamicDayUtils.messageForDaytime(DateTime(2027, 2, 8));
    expect(first?.type, IslamicEventType.ramadan);
    expect(eve?.type, isNot(IslamicEventType.ramadan));
  });
}

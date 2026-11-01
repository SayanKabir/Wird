import 'dart:math' as math;

/// Geometry behind the Qibla screen, kept apart from the widgets so it can be
/// tested without a compass.
class QiblaMath {
  const QiblaMath._();

  /// The Kaaba, Masjid al-Haram.
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  static const double _earthRadiusKm = 6371.0;

  /// Great-circle distance to the Kaaba in kilometres.
  static double distanceToKaabaKm(double latitude, double longitude) {
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(kaabaLatitude - latitude);
    final dLng = rad(kaabaLongitude - longitude);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(latitude)) * math.cos(rad(kaabaLatitude)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
  }

  /// How far to turn from [heading] to face [qibla], in -180..180 degrees.
  /// Positive means turn right (clockwise).
  static double turn(double heading, double qibla) {
    final d = (qibla - heading) % 360;
    return d > 180 ? d - 360 : d;
  }
}

/// Decides when the phone counts as facing the Qibla. It locks on within
/// [lockAt] degrees and lets go only past [releaseAt], so a hand that wavers
/// on the boundary doesn't flicker the colour or repeat the haptic.
class QiblaLock {
  final double lockAt;
  final double releaseAt;
  bool _locked = false;

  QiblaLock({this.lockAt = 3, this.releaseAt = 6}) : assert(releaseAt >= lockAt);

  bool get locked => _locked;

  /// Feeds the latest turn (from [QiblaMath.turn]); returns whether it is
  /// locked now.
  bool update(double turn) {
    final off = turn.abs();
    if (_locked) {
      if (off > releaseAt) _locked = false;
    } else if (off <= lockAt) {
      _locked = true;
    }
    return _locked;
  }
}

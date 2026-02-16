/// Input validation utilities
class Validators {
  Validators._();

  /// Validate latitude (-90 to 90)
  static bool isValidLatitude(double lat) {
    return lat >= -90 && lat <= 90;
  }

  /// Validate longitude (-180 to 180)
  static bool isValidLongitude(double lng) {
    return lng >= -180 && lng <= 180;
  }

  /// Validate coordinates (not 0,0 and within valid ranges)
  static bool isValidCoordinates(double lat, double lng) {
    if (lat == 0 && lng == 0) return false; // Invalid null island
    return isValidLatitude(lat) && isValidLongitude(lng);
  }

  /// Check if location is high latitude (>48°)
  static bool isHighLatitude(double lat) {
    return lat.abs() > 48;
  }

  /// Check if location is extreme latitude (>65°)
  static bool isExtremeLatitude(double lat) {
    return lat.abs() > 65;
  }

  /// Validate city name (not empty, reasonable length)
  static bool isValidCityName(String city) {
    final trimmed = city.trim();
    return trimmed.isNotEmpty && trimmed.length >= 2 && trimmed.length <= 100;
  }

  /// Validate snooze duration
  static bool isValidSnoozeDuration(int minutes) {
    return minutes > 0 && minutes <= 30;
  }

  /// Validate end-time warning minutes
  static bool isValidEndWarningMinutes(int minutes) {
    return [5, 10, 15, 20, 30].contains(minutes);
  }

  /// Validate text size multiplier
  static bool isValidTextSizeMultiplier(double multiplier) {
    return multiplier >= 0.8 && multiplier <= 2.0;
  }

  /// Format validation error for coordinates
  static String? validateCoordinatesError(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return 'Location coordinates are required';
    }
    if (!isValidLatitude(lat)) {
      return 'Invalid latitude: must be between -90 and 90';
    }
    if (!isValidLongitude(lng)) {
      return 'Invalid longitude: must be between -180 and 180';
    }
    if (lat == 0 && lng == 0) {
      return 'Location appears invalid. Please refresh your location.';
    }
    return null; // Valid
  }

  /// Get high latitude warning if applicable
  static String? getHighLatitudeWarning(double lat) {
    if (isExtremeLatitude(lat)) {
      return 'Prayer times may be approximate in polar regions. Please verify with local mosque.';
    } else if (isHighLatitude(lat)) {
      return 'You are in a high latitude region. Some prayer times may need adjustment.';
    }
    return null;
  }
}

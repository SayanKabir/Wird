import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/settings.dart';
import 'storage_service.dart';

/// Result of a location operation
class LocationResult {
  final LocationData? data;
  final String? error;
  final bool permissionDenied;

  const LocationResult({
    this.data,
    this.error,
    this.permissionDenied = false,
  });

  bool get isSuccess => data != null && error == null;
}

/// Service for handling location operations
class LocationService {
  final StorageService _storageService;

  /// Singleton instance
  static LocationService? _instance;
  
  factory LocationService({StorageService? storageService}) {
    _instance ??= LocationService._internal(
      storageService ?? StorageService(),
    );
    return _instance!;
  }
  
  LocationService._internal(this._storageService);

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location from GPS
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Check if service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          error: 'Location services are disabled. Please enable GPS.',
        );
      }

      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            error: 'Location permission denied.',
            permissionDenied: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          error: 'Location permission permanently denied. Please enable in Settings.',
          permissionDenied: true,
        );
      }

      // Get position (coarse accuracy is sufficient)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 15),
      );

      // Validate coordinates
      if (position.latitude == 0 && position.longitude == 0) {
        return const LocationResult(
          error: 'Invalid location received. Please try again.',
        );
      }

      // Reverse geocode to get city/country
      final locationData = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );

      return LocationResult(data: locationData);
    } catch (e) {
      return LocationResult(
        error: 'Unable to get location: ${e.toString()}',
      );
    }
  }

  /// Reverse geocode coordinates to get city and country
  Future<LocationData> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return LocationData(
          latitude: lat,
          longitude: lng,
          city: place.locality ?? place.subAdministrativeArea,
          country: place.country,
        );
      }
    } catch (e) {
      // Geocoding failed, return coordinates only
    }

    return LocationData(
      latitude: lat,
      longitude: lng,
    );
  }

  /// Geocode a city name to coordinates
  Future<LocationResult> geocodeCity(String city, String? country) async {
    try {
      final query = country != null ? '$city, $country' : city;
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        return const LocationResult(
          error: 'City not found. Try format: "City, Country"',
        );
      }

      final location = locations.first;
      
      // Get full location data with reverse geocode
      final locationData = await _reverseGeocode(
        location.latitude,
        location.longitude,
      );

      return LocationResult(data: locationData);
    } catch (e) {
      if (e.toString().contains('No results found')) {
        return const LocationResult(
          error: 'City not found. Please check spelling.',
        );
      }
      return LocationResult(
        error: 'Unable to find location: ${e.toString()}',
      );
    }
  }

  /// Get stored location from settings
  LocationData? getStoredLocation() {
    return _storageService.getSettings().location;
  }

  /// Save location to settings
  Future<void> saveLocation(LocationData location) async {
    final settings = _storageService.getSettings();
    final updated = settings.copyWith(location: location);
    await _storageService.saveSettings(updated);
  }

  /// Check if we have a valid stored location
  bool hasValidLocation() {
    final location = getStoredLocation();
    return location != null && location.isValid;
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Check if location has changed significantly (>50km)
  bool hasLocationChangedSignificantly(LocationData newLocation) {
    final stored = getStoredLocation();
    if (stored == null) return true;

    final distance = calculateDistance(
      stored.latitude, stored.longitude,
      newLocation.latitude, newLocation.longitude,
    );

    return distance > 50000; // 50km
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permission)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

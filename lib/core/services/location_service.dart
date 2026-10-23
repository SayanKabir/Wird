import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/settings.dart';
import 'storage_service.dart';

/// Result of a location operation
class LocationResult {
  final LocationData? data;
  final String? error;
  final bool permissionDenied;

  /// Device location (GPS) is switched off and the user didn't turn it on
  /// from the system prompt. The UI offers to open location settings.
  final bool serviceDisabled;

  const LocationResult({
    this.data,
    this.error,
    this.permissionDenied = false,
    this.serviceDisabled = false,
  });

  bool get isSuccess => data != null && error == null;
}

/// Service for handling location operations
class LocationService {
  static const MethodChannel _channel = MethodChannel('com.SayanKabir.wird2/location');

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

  /// Ask the user to switch device location on.
  ///
  /// On Android this shows the system "Turn on location" dialog in-app and
  /// returns true once location is on. iOS has no equivalent prompt, so this
  /// returns false there and the caller offers to open Settings instead.
  Future<bool> requestLocationService() async {
    if (!Platform.isAndroid) return false;
    try {
      final accepted = await _channel.invokeMethod<bool>('requestLocationService') ?? false;
      if (!accepted) return false;
      // The provider can take a moment to report enabled after the dialog closes.
      for (var i = 0; i < 10; i++) {
        if (await Geolocator.isLocationServiceEnabled()) return true;
        await Future.delayed(const Duration(milliseconds: 300));
      }
      return Geolocator.isLocationServiceEnabled();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled() ||
          await requestLocationService();
      if (!serviceEnabled) {
        return const LocationResult(
          error: 'Location is turned off. Turn it on to detect your city.',
          serviceDisabled: true,
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

  /// How far the user must move before prayer times are recalculated.
  /// Prayer times shift by roughly a minute per 15–25 km, so anything less
  /// makes no practical difference and isn't worth a geocoding call.
  static const double significantMoveMeters = 15000;

  /// Minimum gap between silent auto-detect checks.
  static const Duration _autoDetectInterval = Duration(minutes: 30);

  DateTime? _lastAutoDetect;

  /// Check if location has changed significantly (see [significantMoveMeters])
  bool hasLocationChangedSignificantly(LocationData newLocation) {
    final stored = getStoredLocation();
    if (stored == null) return true;

    final distance = calculateDistance(
      stored.latitude, stored.longitude,
      newLocation.latitude, newLocation.longitude,
    );

    return distance > significantMoveMeters;
  }

  /// Quietly picks up a new city when the user has travelled, like weather
  /// apps do. Returns the new location if it changed, otherwise null.
  ///
  /// Never prompts: if location is off or permission isn't already granted it
  /// does nothing. Runs at most every [_autoDetectInterval], prefers the
  /// phone's last known fix, and only reverse-geocodes (the one network
  /// call) once the user has moved more than [significantMoveMeters].
  Future<LocationData?> autoDetectIfMoved() async {
    final now = DateTime.now();
    if (_lastAutoDetect != null && now.difference(_lastAutoDetect!) < _autoDetectInterval) {
      return null;
    }
    _lastAutoDetect = now;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      final stale = position == null ||
          now.difference(position.timestamp) > _autoDetectInterval;
      if (stale) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );
      }
      if (position.latitude == 0 && position.longitude == 0) return null;

      final stored = getStoredLocation();
      final moved = stored == null
          ? double.infinity
          : calculateDistance(stored.latitude, stored.longitude, position.latitude, position.longitude);
      if (moved <= significantMoveMeters) {
        debugPrint('[Location] auto-detect: ${(moved / 1000).toStringAsFixed(1)} km from saved, keeping it');
        return null;
      }

      final location = await _reverseGeocode(position.latitude, position.longitude);
      await saveLocation(location);
      debugPrint('[Location] auto-detect: moved, updated to ${location.displayName}');
      return location;
    } catch (e) {
      // Timeouts, no fix indoors, etc. — try again on the next check.
      debugPrint('[Location] auto-detect skipped: $e');
      return null;
    }
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

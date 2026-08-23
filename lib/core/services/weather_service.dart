import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Weather conditions mapped from WMO weather codes
enum WeatherCondition {
  clear,
  cloudy,
  rain,
  snow,
  thunderstorm,
  fog,
  drizzle,
}

/// Cached weather data
class WeatherData {
  final WeatherCondition condition;
  final double temperature; // Celsius
  final int cloudCoverage; // 0-100%
  final double windSpeed; // km/h
  final DateTime fetchedAt;

  const WeatherData({
    required this.condition,
    required this.temperature,
    required this.cloudCoverage,
    required this.windSpeed,
    required this.fetchedAt,
  });

  bool get isStale =>
      DateTime.now().difference(fetchedAt).inMinutes > 30;
}

/// Service to fetch current weather conditions
/// Uses Open-Meteo free API (no API key required)
/// https://open-meteo.com/en/docs
class WeatherService {
  static WeatherService? _instance;
  factory WeatherService() {
    _instance ??= WeatherService._internal();
    return _instance!;
  }
  WeatherService._internal();

  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  WeatherData? _cachedWeather;

  /// Get current weather, using cache if fresh (< 30 min old)
  Future<WeatherData> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Return cache if still fresh
    if (_cachedWeather != null && !_cachedWeather!.isStale) {
      return _cachedWeather!;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude'
        '&current=temperature_2m,weather_code,cloud_cover,wind_speed_10m',
      );

      debugPrint('[Weather] Requesting: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final weather = _parseWeather(data);
        _cachedWeather = weather;
        debugPrint('[Weather] Fetched: ${weather.condition.name}, '
            '${weather.temperature}°C, clouds: ${weather.cloudCoverage}%');
        return weather;
      } else {
        debugPrint('[Weather] API error: ${response.statusCode}');
        debugPrint('[Weather] Response: ${response.body}');
        return _cachedWeather ?? _fallbackWeather();
      }
    } catch (e) {
      debugPrint('[Weather] Fetch error: $e');
      return _cachedWeather ?? _fallbackWeather();
    }
  }

  /// Parse Open-Meteo response
  /// Response format:
  /// {
  ///   "current": {
  ///     "temperature_2m": 25.9,
  ///     "weather_code": 2,
  ///     "cloud_cover": 66,
  ///     "wind_speed_10m": 3.6
  ///   }
  /// }
  WeatherData _parseWeather(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>? ?? {};
    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 20.0;
    final clouds = (current['cloud_cover'] as num?)?.toInt() ?? 0;
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;

    return WeatherData(
      condition: _mapWmoCodeToCondition(weatherCode),
      temperature: temp,
      cloudCoverage: clouds,
      windSpeed: wind,
      fetchedAt: DateTime.now(),
    );
  }

  /// Map WMO Weather interpretation codes to our condition enum
  /// See: https://open-meteo.com/en/docs
  /// WMO Code | Description
  /// 0        | Clear sky
  /// 1, 2, 3  | Mainly clear, partly cloudy, overcast
  /// 45, 48   | Fog, depositing rime fog
  /// 51, 53, 55 | Drizzle: light, moderate, dense
  /// 56, 57   | Freezing drizzle
  /// 61, 63, 65 | Rain: slight, moderate, heavy
  /// 66, 67   | Freezing rain
  /// 71, 73, 75 | Snow fall: slight, moderate, heavy
  /// 77       | Snow grains
  /// 80, 81, 82 | Rain showers
  /// 85, 86   | Snow showers
  /// 95       | Thunderstorm
  /// 96, 99   | Thunderstorm with hail
  WeatherCondition _mapWmoCodeToCondition(int code) {
    if (code == 0 || code == 1) return WeatherCondition.clear;
    if (code == 2 || code == 3) return WeatherCondition.cloudy;
    if (code == 45 || code == 48) return WeatherCondition.fog;
    if (code >= 51 && code <= 57) return WeatherCondition.drizzle;
    if (code >= 61 && code <= 67) return WeatherCondition.rain;
    if (code >= 71 && code <= 77) return WeatherCondition.snow;
    if (code >= 80 && code <= 82) return WeatherCondition.rain;
    if (code >= 85 && code <= 86) return WeatherCondition.snow;
    if (code >= 95) return WeatherCondition.thunderstorm;
    return WeatherCondition.clear;
  }

  /// Fallback when API is unavailable
  WeatherData _fallbackWeather() {
    return WeatherData(
      condition: WeatherCondition.clear,
      temperature: 25.0,
      cloudCoverage: 0,
      windSpeed: 0,
      fetchedAt: DateTime.now(),
    );
  }
}

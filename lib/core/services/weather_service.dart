import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Weather conditions mapped from OpenWeatherMap
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
  final double windSpeed; // m/s
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
/// Uses OpenWeatherMap free tier (1000 calls/day)
class WeatherService {
  static WeatherService? _instance;
  factory WeatherService() {
    _instance ??= WeatherService._internal();
    return _instance!;
  }
  WeatherService._internal();

  // OpenWeatherMap free API key — register at openweathermap.org
  // Pass via --dart-define=OPENWEATHER_API_KEY=your_key
  static const String _apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

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

    // If no API key configured, return clear weather
    if (_apiKey.isEmpty) {
      debugPrint('[Weather] No API key configured, defaulting to clear');
      return _fallbackWeather();
    }

    try {
      final url = Uri.parse(
        '$_baseUrl?lat=$latitude&lon=$longitude&units=metric&appid=$_apiKey',
      );
      
      // Log URL with masked key for debugging
      debugPrint('[Weather] Requesting: $_baseUrl?lat=$latitude&lon=$longitude&...&appid=${_apiKey.substring(0, 4)}...');

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

  /// Parse OpenWeatherMap response (API 2.5)
  WeatherData _parseWeather(Map<String, dynamic> data) {
    // API 2.5 structure: { weather: [...], main: { temp: ... }, clouds: { all: ... }, wind: { speed: ... } }
    final weatherId = data['weather']?[0]?['id'] as int? ?? 800;
    final temp = (data['main']?['temp'] as num?)?.toDouble() ?? 20.0;
    final clouds = data['clouds']?['all'] as int? ?? 0;
    final wind = (data['wind']?['speed'] as num?)?.toDouble() ?? 0.0;

    return WeatherData(
      condition: _mapCondition(weatherId),
      temperature: temp,
      cloudCoverage: clouds,
      windSpeed: wind,
      fetchedAt: DateTime.now(),
    );
  }

  /// Map OWM weather ID to our condition enum
  /// See: https://openweathermap.org/weather-conditions
  WeatherCondition _mapCondition(int id) {
    if (id >= 200 && id < 300) return WeatherCondition.thunderstorm;
    if (id >= 300 && id < 400) return WeatherCondition.drizzle;
    if (id >= 500 && id < 600) return WeatherCondition.rain;
    if (id >= 600 && id < 700) return WeatherCondition.snow;
    if (id >= 700 && id < 800) return WeatherCondition.fog;
    if (id == 800) return WeatherCondition.clear;
    if (id > 800) return WeatherCondition.cloudy;
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

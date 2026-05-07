import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:smart_crop_assistant/core/config/app_secrets.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();

  factory WeatherService() {
    return _instance;
  }

  WeatherService._internal();

  // Loaded from app_secrets.dart
  static const String openWeatherApiKey = AppSecrets.openWeatherApiKey;

  bool hasFetched = false;
  bool isFetching = false;
  String errorMessage = '';

  // Weather Data
  String locationName = 'Locating...';
  double currentTemp = 0.0;
  double minTemp = 0.0;
  double maxTemp = 0.0;
  String weatherCondition = '--';
  int humidity = 0;
  double windSpeed = 0.0;
  double uvIndex = 0.0;
  List<double> dailyRainfall = List.filled(7, 0.0);
  List<String> dailyLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void updateWeatherCondition(String condition, double temp) {
    weatherCondition = condition;
    currentTemp = temp;
  }

  Future<void> fetchWeather(double lat, double lon, {bool forceRefresh = false}) async {
    if (hasFetched && !forceRefresh) return;
    if (isFetching) return;

    isFetching = true;

    final currentUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$openWeatherApiKey');

    final forecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=$openWeatherApiKey');

    try {
      // 🌍 Location
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon)
            .timeout(const Duration(seconds: 5));
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          locationName =
              '${place.locality ?? place.subAdministrativeArea}, ${place.administrativeArea}';
        }
      } catch (e) {
        locationName = 'Unknown Location';
        debugPrint("Geocoding Error: $e");
      }

      // 🌡️ CURRENT WEATHER
      final currentRes = await http.get(currentUrl);

      if (currentRes.statusCode != 200) {
        throw Exception("Current weather API failed");
      }

      final currentData = jsonDecode(currentRes.body);

      currentTemp = (currentData['main']['temp'] ?? 0).toDouble();
      minTemp = (currentData['main']['temp_min'] ?? 0).toDouble();
      maxTemp = (currentData['main']['temp_max'] ?? 0).toDouble();
      weatherCondition = currentData['weather'][0]['main'] ?? '--';
      humidity = currentData['main']['humidity'] ?? 0;
      windSpeed = (currentData['wind']['speed'] ?? 0) * 3.6;

      uvIndex = await _fetchUV(lat, lon);

      // 🌧️ FORECAST
      final forecastRes = await http.get(forecastUrl);

      if (forecastRes.statusCode != 200) {
        throw Exception("Forecast API failed");
      }

      final forecastData = jsonDecode(forecastRes.body);
      List list = forecastData['list'];

      Map<String, double> dailyRainMap = {};

      for (var item in list) {
        String date = item['dt_txt'].split(" ")[0];

        double rain = (item['rain']?['3h'] ?? 0).toDouble();

        dailyRainMap[date] = (dailyRainMap[date] ?? 0) + rain;
      }

      // ✅ SORT DATES (IMPORTANT FIX)
      List<String> sortedDates = dailyRainMap.keys.toList()..sort();

      List<double> rainList = [];
      List<String> labels = [];

      for (var date in sortedDates) {
        rainList.add(dailyRainMap[date]!);

        DateTime d = DateTime.parse(date);
        labels.add(_getWeekdayShort(d.weekday));
      }

      // Ensure 7 days
      while (rainList.length < 7) {
        rainList.add(0.0);
        labels.add('N/A');
      }

      dailyRainfall = rainList.take(7).toList();
      dailyLabels = labels.take(7).toList();

      hasFetched = true;
      errorMessage = '';
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("Weather API Error: $e");
      throw Exception("Failed to fetch weather");
    } finally {
      isFetching = false;
    }
  }
static IconData getWeatherIcon(String condition) {
  final lower = condition.toLowerCase();

  if (lower.contains('clear') || lower.contains('sun')) {
    return Icons.wb_sunny;
  }
  if (lower.contains('cloud')) {
    return Icons.cloud;
  }
  if (lower.contains('rain') || lower.contains('drizzle')) {
    return Icons.grain;
  }
  if (lower.contains('thunder') || lower.contains('storm')) {
    return Icons.flash_on;
  }
  if (lower.contains('snow')) {
    return Icons.ac_unit;
  }
  if (lower.contains('haze') || lower.contains('mist') || lower.contains('fog')) {
    return Icons.blur_on; // 🔥 better for haze
  }

  return Icons.wb_cloudy;
}
  Future<double> _fetchUV(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=uv_index');

    try {
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['current']['uv_index'] ?? 0).toDouble();
      } else {
        throw Exception("UV API failed");
      }
    } catch (e) {
      debugPrint("UV Fetch Error: $e");
      return 0;
    }
  }

  String _getWeekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}

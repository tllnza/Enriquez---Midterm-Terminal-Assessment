import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherData {
  final String summary;
  final String details;

  WeatherData({required this.summary, required this.details});
}

class RestService {
  Future<WeatherData> fetchWeather() async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '40.71',
      'longitude': '-74.01',
      'current_weather': 'true',
      'timezone': 'auto',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'Weather request failed with status ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final currentWeather = body['current_weather'] as Map<String, dynamic>?;
    if (currentWeather == null) {
      throw Exception('Weather API returned no current weather data.');
    }

    final temperature = currentWeather['temperature']?.toString() ?? 'N/A';
    final windspeed = currentWeather['windspeed']?.toString() ?? 'N/A';
    final weatherCode = currentWeather['weathercode']?.toString() ?? 'N/A';

    return WeatherData(
      summary: 'NYC current temperature: $temperature°C',
      details: 'Windspeed $windspeed km/h • Weather code $weatherCode',
    );
  }
}

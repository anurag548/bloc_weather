import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:open_meteo_api/src/models/models.dart';

/// {@template open_api_meteo_client}

/// Dart API client which wraps the [Open Meteo Api](https://open-meteo.com)

/// {@endtemplate}

class OpenMeteoApiClient {
  //{@macro open_meteo_api_client}
  OpenMeteoApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const _baseUrlWeather = 'api.open-meteo.com';
  static const _baseUrlGeocoding = 'geocoding-api.open-meteo.com';

  final http.Client _httpClient;

  /// Finds a [Weather] for given [Latitude] & [Longitude]
  Future<Weather> getWeather(String latitude, String longitude) async {
    final weatherRequest = Uri.https(
      _baseUrlWeather,
      'v1/forecase',
      {
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    final weatherResponse = await _httpClient.get(weatherRequest);

    if (weatherResponse.statusCode != 200) throw WeatherRequestFailure();

    final weatherJson = jsonDecode(weatherResponse.body) as Map;

    if (!weatherJson.containsKey('current_weather')) {
      throw WeatherNotFoundFailure();
    }

    final result = weatherJson['current_weather'] as Map<String, dynamic>;

    if (result.isEmpty) throw WeatherNotFoundFailure();

    return Weather.fromJson(result);
  }

  /// Finds a [Location] for given [String]
  Future<Location> locationSearch(String query) async {
    final locatonRequest = Uri.https(
      _baseUrlGeocoding,
      '/v1/search',
      {'name:': query, 'count': '1'},
    );

    final locationResponse = await _httpClient.get(locatonRequest);

    if (locationResponse.statusCode != 200) {
      throw LocationRequestFailure();
    }
    final locationJson = jsonDecode(locationResponse.body) as Map;

    if (!locationJson.containsKey('results')) throw LocationNotFoundFailure();

    final results = locationJson['results'] as List;

    if (results.isEmpty) throw LocationNotFoundFailure();

    return Location.fromJson(results.first as Map<String, dynamic>);
  }
}

//Exception thrown when weather request fails
class WeatherRequestFailure implements Exception {}

//Exceotion thrown when weather not found
class WeatherNotFoundFailure implements Exception {}

//Exception thrown when location not found
class LocationNotFoundFailure implements Exception {}

//Exception thrown when location request fails
class LocationRequestFailure implements Exception {}

import 'package:test/test.dart';

import 'package:http/http.dart' as http;
import 'package:open_meteo_api/open_meteo_api.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockHttpResponse extends Mock implements http.Response {}

class FakeUri extends Fake implements Uri {}

void main() {
  group('OpenMeteoApiClient', () {
    late http.Client httpClient;
    late OpenMeteoApiClient apiClient;

    setUpAll(
      () {
        registerFallbackValue(FakeUri());
      },
    );

    setUp(() {
      httpClient = MockHttpClient();
      apiClient = OpenMeteoApiClient(httpClient: httpClient);
    });

    group('constructor', () {
      test('does not require an httpClient', () {
        expect(OpenMeteoApiClient(), isNotNull);
      });
    });

    group(
      'locationSearch',
      () {
        const query = 'mock-query';
        test(
          'makes correct http request',
          () async {
            final response = MockHttpResponse();
            when(
              () => response.statusCode,
            ).thenReturn(200);
            when(
              () => response.body,
            ).thenReturn('{}');
            when(
              () => httpClient.get(any()),
            ).thenAnswer((_) async => response);
            try {
              await apiClient.locationSearch(query);
            } catch (_) {}
            verify(
              () => httpClient.get(Uri.https(
                'geocoding-api.open-meteo.com',
                'v1/search',
                {'name': query, 'count': '1'},
              )),
            ).called(1);
          },
        );
      },
    );
  });

  group(
    'Location',
    () {
      group(
        'fromJson',
        () {
          test(
            'returns correct Location object',
            () {
              expect(
                Location.fromJson(
                  <String, dynamic>{
                    'id': 488769,
                    'name': 'chicago',
                    'latitude': 41.85003,
                    'longitude': -85.3315
                  },
                ),
                isA<Location>()
                    .having((w) => w.id, 'id', 488769)
                    .having((w) => w.name, 'name', 'chicago')
                    .having((w) => w.latitude, 'latitude', 41.85003)
                    .having((w) => w.longitude, 'longitude', -85.3315),
              );
            },
          );
        },
      );
    },
  );
  group(
    'Weather',
    () {
      group(
        'fromJson',
        () {
          test(
            'returns correct Weather object',
            () {
              expect(
                  Weather.fromJson(
                    <String, dynamic>{
                      'temperature': 15.3,
                      'weathercode': 63,
                    },
                  ),
                  isA<Weather>()
                      .having((w) => w.temperature, 'id', 15.3)
                      .having((w) => w.weatherCode, 'name', 63));
            },
          );
        },
      );
    },
  );
}

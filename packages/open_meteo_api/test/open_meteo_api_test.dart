import 'dart:developer' show log;
import 'package:test/test.dart';

import 'package:http/http.dart' as http;
import 'package:open_meteo_api/open_meteo_api.dart';
import 'package:mocktail/mocktail.dart';

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
            final response = MockResponse();
            when(() => response.statusCode).thenReturn(200);
            when(() => response.body).thenReturn('{}');
            when(() => httpClient.get(any())).thenAnswer((_) async => response);
            try {
              await apiClient.locationSearch(query);
            } catch (_) {}
            verify(
              () => httpClient.get(
                  Uri.https(
                    'geocoding-api.open-meteo.com',
                    '/v1/search',
                    {'name': query, 'count': '1'},
                  ),
                  headers: null),
            ).called(1);
          },
        );

        test('throws LocationRequestFailure on non-200 response', () async {
          final response = MockResponse();
          when(
            () => response.statusCode,
          ).thenReturn(400);
          // when(
          //   () => response.body,
          // ).thenReturn('{}');
          when(() => httpClient.get(any())).thenAnswer(
            (_) async => response,
          );
          expect(() async => apiClient.locationSearch(query),
              throwsA(isA<LocationRequestFailure>()));
        });

        test('returns Location on sucessful resquest', () async {
          final response = MockResponse();

          when(
            () => response.statusCode,
          ).thenReturn(200);
          when(() => response.body).thenReturn(
            '''
            {
              "results":[
                {
                  "id":4887398,
                  "name":"Chicago",
                  "latitude":41.85003,
                  "longitude":-87.65005
                }
              ]
            }''',
          );
          when(
            () => httpClient.get(any()),
          ).thenAnswer((invocation) async => response);
          // try{

          // }catch(_){}
          final actual = await apiClient.locationSearch(query);
          expect(
            actual,
            isA<Location>()
                .having((p) => p.name, 'name', 'Chicago')
                .having((p) => p.id, 'id', 4887398)
                .having((p) => p.latitude, 'latitude', 41.85003)
                .having((p) => p.longitude, 'longitude', -87.65005),
          );
        });
        test('throws LocationNotFoundFailure on error response', () async {
          final response = MockResponse();
          when(
            () => response.statusCode,
          ).thenReturn(200);
          when(
            () => response.body,
          ).thenReturn('{}');
          when(
            () => httpClient.get(any()),
          ).thenAnswer((invocation) async => response);
          await expectLater(apiClient.locationSearch(query),
              throwsA(isA<LocationNotFoundFailure>()));
        });
      },
    );

    group('getWeather', () {
      const latitude = 41.85003;
      const longitude = -87.6500;

      test(
        'makes correct http request',
        () async {
          final response = MockResponse();
          when(() => response.statusCode).thenReturn(200);
          when(() => response.body).thenReturn('{}');
          when(() => httpClient.get(any())).thenAnswer(
            (_) async => response,
          );

          try {
            await apiClient.getWeather(
              latitude: latitude,
              longitude: longitude,
            );
          } catch (e) {
            //

            log(e.toString());
          }
          verify(() => httpClient.get(
                Uri.https('api.open-meteo.com', 'v1/forecast', {
                  'latitude': '$latitude',
                  'longitude': '$longitude',
                  'current_weather': 'true'
                }),
              )).called(1);
        },
      );
      test('returns WeatherRequestFailure on non-200 response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(400);
        when(
          () => httpClient.get(any()),
        ).thenAnswer((invocation) async => response);

        // final actual = await apiClient.getWeather(
        //   latitude: latitude,
        //   longitude: longitude,
        // );

        expect(
            () async => await apiClient.getWeather(
                latitude: latitude, longitude: longitude),
            throwsA(isA<WeatherRequestFailure>()));
      });
      test(
        'returns WeatherNotFoundFailure on not finding current_weather in response ',
        () async {
          final response = MockResponse();
          when(
            () => response.statusCode,
          ).thenReturn(200);
          when(
            () => response.body,
          ).thenReturn('{}');
          when(
            () => httpClient.get(any()),
          ).thenAnswer((_) async => response);

          expect(
              () async => await apiClient.getWeather(
                  latitude: latitude, longitude: longitude),
              throwsA(isA<WeatherNotFoundFailure>()));
        },
      );
    });
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

class MockHttpClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

class FakeUri extends Fake implements Uri {}

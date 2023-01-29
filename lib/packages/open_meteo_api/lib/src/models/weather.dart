import 'package:json_annotation/json_annotation.dart';

part 'weather.g.dart';

@JsonSerializable()
class Weather {
  final double temperature;
  @JsonKey(name: 'weathercode')
  final double weatherCode;

  factory Weather.fromJson(Map<String, dynamic> json) =>
      _$WeatherFromJson(json);

  Weather({
    required this.temperature,
    required this.weatherCode,
  });
}

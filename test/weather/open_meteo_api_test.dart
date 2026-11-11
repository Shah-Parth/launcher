import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/weather/open_meteo_api.dart';
import 'package:flauncher/weather/weather_api.dart';
import 'package:flutter_test/flutter_test.dart';

const String forecastFixture = '''
{
  "latitude": 38.9, "longitude": -77.6, "timezone": "America/New_York",
  "current": {
    "time": "2026-11-11T14:30",
    "temperature_2m": 12.6,
    "relative_humidity_2m": 61,
    "weather_code": 2,
    "wind_speed_10m": 3.4
  },
  "daily": {
    "time": ["2026-11-11","2026-11-12","2026-11-13"],
    "weather_code": [2, 61, 71],
    "temperature_2m_max": [15.2, 11.0, 4.4],
    "temperature_2m_min": [6.8, 7.1, -1.2],
    "precipitation_probability_max": [10, 80, 65]
  }
}
''';

const String geocodingFixture = '''
{"results":[
  {"name":"Chantilly","latitude":38.8942,"longitude":-77.4311,"country_code":"US","admin1":"Virginia"},
  {"name":"Chantilly","latitude":49.1943,"longitude":2.4713,"country_code":"FR","admin1":"Hauts-de-France"}
]}
''';

void main() {
  group('OpenMeteoApi.parseForecast', () {
    test('converts an Open-Meteo payload into the app weather schema', () {
      final json = OpenMeteoApi.parseForecast(forecastFixture);
      expect(json['currentTemp'], 13);
      expect(json['currentConditionCode'], 802);
      expect(json['currentCondition'], 'Partly cloudy');
      expect(json['currentHumidity'], 61);
      expect(json['windSpeed'], 3.4);
      expect(json['todayMaxTemp'], 15);
      expect(json['todayMinTemp'], 7);
      expect(json['timestamp'], isA<int>());
      final forecasts = json['forecasts'] as List;
      expect(forecasts.length, 3);
      expect(forecasts[1], {'conditionCode': 500, 'minTemp': 7, 'maxTemp': 11, 'precipProbability': 80});
      expect(forecasts[2]['conditionCode'], 600);
    });

    test('result round-trips through WeatherData with a rain warning for tomorrow', () {
      final weather = WeatherData.fromJson(OpenMeteoApi.parseForecast(forecastFixture));
      expect(weather.currentTemp, 13);
      expect(weather.formatTemperature(useFahrenheit: true), '55°F');
      expect(weather.hasWarning, true);
      expect(weather.warningType, WeatherWarningType.rain);
      expect(weather.warningDayIndex, 1);
      expect(weather.warningText, '80% Rain tomorrow');
    });

    test('throws WeatherApiException on malformed or error payloads', () {
      expect(() => OpenMeteoApi.parseForecast('not json'), throwsA(isA<WeatherApiException>()));
      expect(() => OpenMeteoApi.parseForecast('{"error":true,"reason":"Latitude must be in range"}'),
          throwsA(isA<WeatherApiException>()));
      expect(() => OpenMeteoApi.parseForecast('{"current":{}}'), throwsA(isA<WeatherApiException>()));
    });
  });

  group('OpenMeteoApi.parseGeocoding', () {
    test('builds labelled locations from results', () {
      final places = OpenMeteoApi.parseGeocoding(geocodingFixture);
      expect(places.length, 2);
      expect(places.first.name, 'Chantilly, Virginia, US');
      expect(places.first.latitude, closeTo(38.8942, 1e-6));
      expect(places.last.name, 'Chantilly, Hauts-de-France, FR');
    });

    test('returns empty list when there are no results', () {
      expect(OpenMeteoApi.parseGeocoding('{"generationtime_ms":0.1}'), isEmpty);
    });
  });

  group('OpenMeteoApi requests', () {
    test('fetchWeather calls the forecast endpoint with Celsius and 7 days', () async {
      Uri? requested;
      final api = OpenMeteoApi(httpGet: (uri) async {
        requested = uri;
        return forecastFixture;
      });
      final json = await api.fetchWeather(38.8942, -77.4311);
      expect(requested!.host, OpenMeteoApi.forecastHost);
      expect(requested!.path, '/v1/forecast');
      expect(requested!.queryParameters['latitude'], '38.8942');
      expect(requested!.queryParameters['temperature_unit'], 'celsius');
      expect(requested!.queryParameters['forecast_days'], '7');
      expect(json['currentConditionCode'], 802);
    });

    test('searchLocations skips the network for very short queries', () async {
      int calls = 0;
      final api = OpenMeteoApi(httpGet: (uri) async {
        calls++;
        return geocodingFixture;
      });
      expect(await api.searchLocations('a'), isEmpty);
      expect(calls, 0);
      expect((await api.searchLocations('20152')).length, 2);
      expect(calls, 1);
    });

    test('transport failures surface as WeatherApiException', () async {
      final api = OpenMeteoApi(httpGet: (_) async => throw const WeatherApiException('boom'));
      expect(() => api.fetchWeather(0, 0), throwsA(isA<WeatherApiException>()));
    });
  });
}

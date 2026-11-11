import 'package:flauncher/models/weather_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeatherLocation', () {
    test('serialises to and from JSON', () {
      const loc = WeatherLocation(latitude: 38.89, longitude: -77.43, name: 'Chantilly, Virginia, US');
      final restored = WeatherLocation.fromJsonString(loc.toJsonString());
      expect(restored, loc);
      expect(restored.hashCode, loc.hashCode);
    });

    test('rejects missing, NaN and out-of-range coordinates', () {
      expect(WeatherLocation.fromJson(null), isNull);
      expect(WeatherLocation.fromJson({'latitude': 91.0, 'longitude': 0.0}), isNull);
      expect(WeatherLocation.fromJson({'latitude': 0.0, 'longitude': -181.0}), isNull);
      expect(WeatherLocation.fromJson({'latitude': 'x', 'longitude': 1}), isNull);
      expect(WeatherLocation.fromJsonString('garbage'), isNull);
      expect(WeatherLocation.fromJsonString(''), isNull);
    });

    test('accepts platform maps with integer and extra fields', () {
      final loc = WeatherLocation.fromJson({'latitude': 38, 'longitude': -77, 'accuracy': 1200.0, 'time': 1});
      expect(loc, isNotNull);
      expect(loc!.latitude, 38.0);
      expect(loc.name, isNull);
    });

    test('computes haversine distance', () {
      const dulles = WeatherLocation(latitude: 38.9531, longitude: -77.4565);
      const dca = WeatherLocation(latitude: 38.8512, longitude: -77.0402);
      expect(dulles.distanceKmTo(dca), closeTo(37.8, 1.0));
      expect(dulles.distanceKmTo(dulles), 0);
    });
  });
}

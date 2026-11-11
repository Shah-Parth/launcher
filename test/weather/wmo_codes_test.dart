import 'package:flauncher/weather/wmo_codes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WmoCodes', () {
    test('maps clear and cloud codes to OpenWeatherMap 80x family', () {
      expect(WmoCodes.toOwmCode(0), 800);
      expect(WmoCodes.toOwmCode(1), 801);
      expect(WmoCodes.toOwmCode(2), 802);
      expect(WmoCodes.toOwmCode(3), 804);
    });

    test('maps rain, showers and freezing precipitation into WeatherData.rainCodes', () {
      for (final c in [61, 63, 65, 66, 67, 56, 57, 80, 81, 82]) {
        expect([500, 501, 502, 511, 520, 521, 522], contains(WmoCodes.toOwmCode(c)), reason: 'WMO $c');
      }
    });

    test('maps snow codes into WeatherData.snowCodes', () {
      for (final c in [71, 73, 75, 77, 85, 86]) {
        expect([600, 601, 602, 620, 622], contains(WmoCodes.toOwmCode(c)), reason: 'WMO $c');
      }
    });

    test('maps thunderstorms into WeatherData.stormCodes', () {
      expect(WmoCodes.toOwmCode(95), 211);
      expect(WmoCodes.toOwmCode(96), 211);
      expect(WmoCodes.toOwmCode(99), 212);
    });

    test('maps fog to 741 and drizzle to the 30x family (no rain warning)', () {
      expect(WmoCodes.toOwmCode(45), 741);
      expect(WmoCodes.toOwmCode(48), 741);
      expect(WmoCodes.toOwmCode(51), 300);
      expect(WmoCodes.toOwmCode(55), 302);
    });

    test('degrades gracefully for unknown or null codes', () {
      expect(WmoCodes.toOwmCode(null), 804);
      expect(WmoCodes.toOwmCode(1234), 804);
      expect(WmoCodes.describe(null), 'Cloudy');
      expect(WmoCodes.describe(0), 'Clear');
      expect(WmoCodes.describe(95), 'Thunderstorm');
    });
  });
}

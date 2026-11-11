/*
 * LTvLauncher fork — built-in weather
 * Copyright (C) 2026 Parth Shah
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:convert';
import 'dart:io';

import 'package:flauncher/models/weather_location.dart';
import 'package:flauncher/weather/weather_api.dart';
import 'package:flauncher/weather/wmo_codes.dart';

/// Signature of the HTTP GET used by [OpenMeteoApi]; injectable for tests.
typedef HttpGet = Future<String> Function(Uri uri);

/// Open-Meteo client. Free, no API key, no account, CC BY 4.0 data.
/// https://open-meteo.com/en/docs and https://open-meteo.com/en/docs/geocoding-api
///
/// The class is deliberately free of Flutter imports so it is unit-testable
/// with plain `dart test` semantics.
class OpenMeteoApi implements WeatherApi {
  static const String forecastHost = "api.open-meteo.com";
  static const String geocodingHost = "geocoding-api.open-meteo.com";
  static const Duration _timeout = Duration(seconds: 10);
  static const String _userAgent = "LTvLauncher-fork/1.0 (+https://github.com/leanbitlab-org/LtvLauncher)";

  final HttpGet _get;

  OpenMeteoApi({HttpGet? httpGet}) : _get = httpGet ?? _defaultGet;

  static Future<String> _defaultGet(Uri uri) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(uri).timeout(_timeout);
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      request.headers.set(HttpHeaders.acceptHeader, "application/json");
      final response = await request.close().timeout(_timeout);
      final body = await response.transform(utf8.decoder).join().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WeatherApiException("HTTP ${response.statusCode} from ${uri.host}");
      }
      return body;
    } on WeatherApiException {
      rethrow;
    } catch (e) {
      throw WeatherApiException("Request to ${uri.host} failed", e);
    } finally {
      client.close(force: true);
    }
  }

  Uri forecastUri(double latitude, double longitude) => Uri.https(forecastHost, "/v1/forecast", {
        "latitude": latitude.toStringAsFixed(4),
        "longitude": longitude.toStringAsFixed(4),
        "current": "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m",
        "daily": "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max",
        "forecast_days": "7",
        "timezone": "auto",
        "wind_speed_unit": "ms",
        "temperature_unit": "celsius",
      });

  Uri geocodingUri(String query, String language) => Uri.https(geocodingHost, "/v1/search", {
        "name": query.trim(),
        "count": "8",
        "language": language,
        "format": "json",
      });

  @override
  Future<Map<String, dynamic>> fetchWeather(double latitude, double longitude) async {
    final body = await _get(forecastUri(latitude, longitude));
    return parseForecast(body);
  }

  /// Converts an Open-Meteo forecast response into the app's weather schema.
  /// Pure function; exposed for tests.
  static Map<String, dynamic> parseForecast(String body) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw WeatherApiException("Malformed forecast payload", e);
    }
    if (json["error"] == true) {
      throw WeatherApiException(json["reason"]?.toString() ?? "Open-Meteo returned an error");
    }
    final current = json["current"];
    final daily = json["daily"];
    if (current is! Map<String, dynamic> || daily is! Map<String, dynamic>) {
      throw const WeatherApiException("Forecast payload is missing 'current' or 'daily'");
    }

    final int? wmo = (current["weather_code"] as num?)?.toInt();
    final List<dynamic> dailyCodes = (daily["weather_code"] as List<dynamic>?) ?? const [];
    final List<dynamic> dailyMax = (daily["temperature_2m_max"] as List<dynamic>?) ?? const [];
    final List<dynamic> dailyMin = (daily["temperature_2m_min"] as List<dynamic>?) ?? const [];
    final List<dynamic> dailyPrecip = (daily["precipitation_probability_max"] as List<dynamic>?) ?? const [];

    num? at(List<dynamic> list, int i) => i < list.length ? list[i] as num? : null;

    final forecasts = <Map<String, dynamic>>[];
    for (int i = 0; i < dailyCodes.length; i++) {
      forecasts.add({
        "conditionCode": WmoCodes.toOwmCode((dailyCodes[i] as num?)?.toInt()),
        "minTemp": at(dailyMin, i)?.round(),
        "maxTemp": at(dailyMax, i)?.round(),
        "precipProbability": at(dailyPrecip, i)?.round(),
      });
    }

    final String? currentTime = current["time"] as String?;
    final int timestamp = currentTime != null
        ? (DateTime.tryParse(currentTime)?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000
        : DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return {
      "timestamp": timestamp,
      "currentTemp": (current["temperature_2m"] as num?)?.round(),
      "currentConditionCode": WmoCodes.toOwmCode(wmo),
      "currentCondition": WmoCodes.describe(wmo),
      "currentHumidity": (current["relative_humidity_2m"] as num?)?.round(),
      "windSpeed": (current["wind_speed_10m"] as num?)?.toDouble(),
      "todayMaxTemp": at(dailyMax, 0)?.round(),
      "todayMinTemp": at(dailyMin, 0)?.round(),
      "forecasts": forecasts,
    };
  }

  @override
  Future<List<WeatherLocation>> searchLocations(String query, {String language = "en"}) async {
    if (query.trim().length < 2) return const [];
    final body = await _get(geocodingUri(query, language));
    return parseGeocoding(body);
  }

  /// Pure function; exposed for tests.
  static List<WeatherLocation> parseGeocoding(String body) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw WeatherApiException("Malformed geocoding payload", e);
    }
    final results = json["results"];
    if (results is! List) return const [];
    return results.whereType<Map<String, dynamic>>().map((r) {
      final parts = [r["name"], r["admin1"], r["country_code"]]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      return WeatherLocation(
        latitude: (r["latitude"] as num).toDouble(),
        longitude: (r["longitude"] as num).toDouble(),
        name: parts.join(", "),
      );
    }).toList();
  }
}

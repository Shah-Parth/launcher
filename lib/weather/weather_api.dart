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

import 'package:flauncher/models/weather_location.dart';

/// Thrown for any transport, HTTP or payload problem while talking to a
/// weather backend. Callers treat it as "temporarily unavailable".
class WeatherApiException implements Exception {
  final String message;
  final Object? cause;

  const WeatherApiException(this.message, [this.cause]);

  @override
  String toString() => "WeatherApiException: $message${cause != null ? " ($cause)" : ""}";
}

/// Abstraction over a weather backend so the service and UI can be tested
/// without network access. The only production implementation is
/// [OpenMeteoApi]; a fake is used in tests.
abstract class WeatherApi {
  /// Returns a weather payload in the JSON schema understood by
  /// `WeatherData.fromJson` (the same schema Breezy Weather broadcasts), with
  /// temperatures in Celsius.
  Future<Map<String, dynamic>> fetchWeather(double latitude, double longitude);

  /// Resolves a free-text query (city name or postal code) to candidate places.
  Future<List<WeatherLocation>> searchLocations(String query, {String language = "en"});
}

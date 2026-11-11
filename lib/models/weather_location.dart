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
import 'dart:math';

/// A resolved place used to request a forecast. Immutable and JSON-serialisable
/// so it can be cached in SharedPreferences and included in backups.
class WeatherLocation {
  final double latitude;
  final double longitude;

  /// Human readable label (e.g. "Chantilly, Virginia, US"); may be null when
  /// reverse geocoding was unavailable.
  final String? name;

  const WeatherLocation({required this.latitude, required this.longitude, this.name});

  Map<String, dynamic> toJson() => {"latitude": latitude, "longitude": longitude, if (name != null) "name": name};

  String toJsonString() => jsonEncode(toJson());

  static WeatherLocation? fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return null;
    final lat = (json["latitude"] as num?)?.toDouble();
    final lon = (json["longitude"] as num?)?.toDouble();
    if (lat == null || lon == null || lat.isNaN || lon.isNaN) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return WeatherLocation(latitude: lat, longitude: lon, name: json["name"] as String?);
  }

  static WeatherLocation? fromJsonString(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Great-circle distance in kilometres (haversine). Used to decide whether a
  /// device move is big enough to warrant a new forecast.
  double distanceKmTo(WeatherLocation other) {
    const r = 6371.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(other.latitude - latitude);
    final dLon = rad(other.longitude - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(rad(latitude)) * cos(rad(other.latitude)) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  bool operator ==(Object other) =>
      other is WeatherLocation && other.latitude == latitude && other.longitude == longitude && other.name == name;

  @override
  int get hashCode => Object.hash(latitude, longitude, name);

  @override
  String toString() => "WeatherLocation(${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}, $name)";
}

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

/// Maps WMO weather interpretation codes (used by Open-Meteo) to the
/// OpenWeatherMap-style condition codes that [WeatherData] already understands
/// (800 clear, 80x clouds, 5xx rain, 6xx snow, 2xx thunderstorm, 741 fog, ...).
///
/// Reference: https://open-meteo.com/en/docs#weather_variable_documentation
class WmoCodes {
  WmoCodes._();

  static const Map<int, int> _toOwm = {
    0: 800, // Clear sky
    1: 801, // Mainly clear
    2: 802, // Partly cloudy
    3: 804, // Overcast
    45: 741, // Fog
    48: 741, // Depositing rime fog
    51: 300, // Light drizzle
    53: 301, // Moderate drizzle
    55: 302, // Dense drizzle
    56: 511, // Light freezing drizzle
    57: 511, // Dense freezing drizzle
    61: 500, // Slight rain
    63: 501, // Moderate rain
    65: 502, // Heavy rain
    66: 511, // Light freezing rain
    67: 511, // Heavy freezing rain
    71: 600, // Slight snow fall
    73: 601, // Moderate snow fall
    75: 602, // Heavy snow fall
    77: 601, // Snow grains
    80: 520, // Slight rain showers
    81: 521, // Moderate rain showers
    82: 522, // Violent rain showers
    85: 620, // Slight snow showers
    86: 622, // Heavy snow showers
    95: 211, // Thunderstorm
    96: 211, // Thunderstorm with slight hail
    99: 212, // Thunderstorm with heavy hail
  };

  static const Map<int, String> _descriptions = {
    0: "Clear",
    1: "Mostly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Fog",
    51: "Light drizzle",
    53: "Drizzle",
    55: "Heavy drizzle",
    56: "Freezing drizzle",
    57: "Freezing drizzle",
    61: "Light rain",
    63: "Rain",
    65: "Heavy rain",
    66: "Freezing rain",
    67: "Freezing rain",
    71: "Light snow",
    73: "Snow",
    75: "Heavy snow",
    77: "Snow grains",
    80: "Light showers",
    81: "Showers",
    82: "Heavy showers",
    85: "Snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm with hail",
    99: "Thunderstorm with heavy hail",
  };

  /// Unknown codes degrade to "overcast" rather than throwing, so a new WMO
  /// code introduced upstream never breaks the status bar.
  static int toOwmCode(int? wmoCode) => _toOwm[wmoCode] ?? 804;

  static String describe(int? wmoCode) => _descriptions[wmoCode] ?? "Cloudy";
}

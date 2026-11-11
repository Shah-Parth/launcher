## Unreleased (fork)

### Added
- Built-in weather sources: **Device location** (Android runtime permission, `ACCESS_COARSE_LOCATION` only,
  re-resolved on resume so a travelling device stays correct) and **Manual location** (Open-Meteo geocoding
  search by city or postal code). Breezy Weather remains available as a third source.
- `OpenMeteoApi` client with WMO→OpenWeatherMap condition-code mapping, 7-day forecast and rain/snow/storm
  warnings fed into the existing `WeatherData` model.
- Forecast cache (6 h), 30-minute refresh with exponential backoff on failures, 10-minute network throttle,
  and a 5 km "significant move" rule.
- Settings UI: weather source picker, permission prompt with rationale, "Open app settings" for permanently
  denied permission, manual location page, status line and Open-Meteo attribution. Strings in all 16 locales.
- Tests: `test/weather/`, `test/models/weather_location_test.dart`, and built-in source coverage in
  `test/providers/weather_service_test.dart`.

### Changed
- Release manifest now declares `INTERNET` (Open-Meteo only) and `ACCESS_COARSE_LOCATION`.

# Changes from the original

### Features
* Allow users to customize the date widget format, making it possible to display the [date, time](https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html), and any arbitrary text, or to hide it completely.
* Choose what the back button does while being in the launcher: Nothing, Show a fullscreen clock, Show screensaver (a.k.a Ambient Mode).
* Show the active network status next to the date widget.
* Allow users to hide the application category titles.
* Clicking or tapping on an application card now opens it.
* Ability to disable the navigation keys sound.
* The app bar can now hide automatically while not focused.
* Map "Escape" key to the "Back" action.
* Translate to Spanish.

### Removals
* Firebase analytics and crashlytics services.
* Unsplash integration.

### Misc
* Upgrade Flutter version from 3.7.5 to 3.24.5.
* Replace Kotlin code with Java.
* Set new language versions: Java (17), Dart (greater than or equal to 3.4.3).
* Change versioning scheme to \<year>.\<month>.\<monthly release number>

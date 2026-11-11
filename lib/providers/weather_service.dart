/*
 * FLauncher / LTvLauncher
 * Copyright (C) 2024 Oscar Rojas
 * Built-in weather sources (device location, manual, Open-Meteo):
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

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/models/weather_location.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/weather/open_meteo_api.dart';
import 'package:flauncher/weather/weather_api.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the status-bar weather comes from. Persisted via [SettingsService].
enum WeatherSource { device, manual, breezy }

/// Why there is (or isn't) weather to show; drives the settings page copy.
enum WeatherStatus {
  idle,
  ok,
  disabled,
  permissionDenied,
  locationUnavailable,
  locationNotSet,
  networkError,
}

const String _cacheJsonKey = "weather_cache_json";
const String _cacheTimeKey = "weather_cache_time_ms";
const String _cacheLocationKey = "weather_cache_location";

class WeatherService extends ChangeNotifier with WidgetsBindingObserver {
  /// Normal refresh cadence while the launcher is visible.
  static const Duration refreshInterval = Duration(minutes: 30);

  /// Do not hit the network more often than this, even on repeated resumes.
  static const Duration minFetchInterval = Duration(minutes: 10);

  /// Cached forecasts older than this are not shown on startup.
  static const Duration cacheMaxAge = Duration(hours: 6);

  /// Exponential backoff ceiling after consecutive failures.
  static const Duration maxBackoff = Duration(hours: 2);

  /// Device moves smaller than this reuse the previous forecast location.
  static const double significantMoveKm = 5.0;

  final FLauncherChannel _channel;
  final SettingsService? _settings;
  final WeatherApi _api;
  final SharedPreferences? _prefs;
  final DateTime Function() _now;

  StreamSubscription<dynamic>? _subscription;
  Timer? _refreshTimer;
  DateTime? _lastResumeCheck;
  DateTime? _lastFetchAttempt;
  String? _lastJson;
  int _consecutiveFailures = 0;
  Future<void>? _inFlight;

  WeatherData? _weatherData;
  WeatherLocation? _resolvedLocation;
  DateTime? _lastUpdated;
  WeatherStatus _status = WeatherStatus.idle;
  bool _isBreezyInstalled = false;
  bool? _locationPermissionGranted;
  bool _initialized = false;

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  WeatherService(
    this._channel, {
    SettingsService? settingsService,
    WeatherApi? api,
    SharedPreferences? preferences,
    DateTime Function()? clock,
  })  : _settings = settingsService,
        _api = api ?? OpenMeteoApi(),
        _prefs = preferences,
        _now = clock ?? DateTime.now {
    if (!_isTest) {
      WidgetsBinding.instance.addObserver(this);
    }
    _settings?.addListener(_onSettingsChanged);
    _init();
  }

  // ---------------------------------------------------------------- getters

  WeatherData? get weatherData => _weatherData;
  bool get isBreezyInstalled => _isBreezyInstalled;
  bool get initialized => _initialized;
  bool get hasWeather => _weatherData != null;
  WeatherStatus get status => _status;
  WeatherLocation? get resolvedLocation => _resolvedLocation;
  DateTime? get lastUpdated => _lastUpdated;

  /// null until checked; false means the user has not granted (or has revoked) it.
  bool? get locationPermissionGranted => _locationPermissionGranted;

  WeatherSource get source {
    switch (_settings?.weatherSource) {
      case WEATHER_SOURCE_DEVICE:
        return WeatherSource.device;
      case WEATHER_SOURCE_MANUAL:
        return WeatherSource.manual;
      case WEATHER_SOURCE_BREEZY:
        return WeatherSource.breezy;
      default:
        // Without a SettingsService (legacy construction / tests) keep the
        // original Breezy-only behaviour.
        return _settings == null ? WeatherSource.breezy : WeatherSource.device;
    }
  }

  // ------------------------------------------------------------- lifecycle

  Future<void> _init() async {
    try {
      _restoreCache();
      _subscription = _channel.addWeatherChangedListener((event) {
        if (source == WeatherSource.breezy && event is String && event.isNotEmpty) {
          _processWeatherJson(event);
        }
      });
      await refresh();
      _startPeriodicTimer();
    } catch (e, stack) {
      developer.log("Error initializing WeatherService", error: e, stackTrace: stack);
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  void _startPeriodicTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_currentInterval(), (_) => refresh());
  }

  Duration _currentInterval() {
    if (_consecutiveFailures == 0) return source == WeatherSource.breezy ? const Duration(minutes: 15) : refreshInterval;
    final backoff = refreshInterval * pow(2, _consecutiveFailures).toInt();
    return backoff > maxBackoff ? maxBackoff : backoff;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _checkWeatherOnResume();
      _startPeriodicTimer();
    }
  }

  Future<void> _checkWeatherOnResume() async {
    final now = _now();
    if (_lastResumeCheck != null && now.difference(_lastResumeCheck!).inSeconds < 60) {
      return;
    }
    _lastResumeCheck = now;
    // The device may have moved (e.g. travelling with a Chromecast), so a
    // resume re-resolves the location; the fetch itself is still throttled.
    await refresh();
  }

  void _onSettingsChanged() {
    final s = _settings;
    if (s == null) return;
    final signature = "${s.weatherSource}|${s.weatherManualLocation}|${s.showWeatherInStatusBar}";
    if (signature == _settingsSignature) return;
    _settingsSignature = signature;
    _consecutiveFailures = 0;
    refresh(force: true).then((_) => _startPeriodicTimer());
  }

  String? _settingsSignature;

  // --------------------------------------------------------------- actions

  /// Refreshes according to the configured [source]. Safe to call often:
  /// concurrent calls share one request and network calls are rate limited
  /// unless [force] is set.
  Future<void> refresh({bool force = false}) {
    final pending = _inFlight;
    if (pending != null) return pending;
    final run = _refresh(force: force).whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<void> _refresh({required bool force}) async {
    switch (source) {
      case WeatherSource.breezy:
        await _fetchLatestBreezy();
        return;
      case WeatherSource.device:
      case WeatherSource.manual:
        await _fetchBuiltIn(force: force);
        return;
    }
  }

  /// Asks the OS for coarse location permission (shows the system dialog).
  /// Returns the resulting grant state and refreshes on success.
  Future<bool> requestLocationPermission() async {
    try {
      final granted = await _channel.requestLocationPermission();
      _locationPermissionGranted = granted;
      notifyListeners();
      if (granted) await refresh(force: true);
      return granted;
    } catch (e) {
      developer.log("requestLocationPermission failed", error: e);
      return false;
    }
  }

  /// Called when the user turns the weather status bar on.
  Future<void> onWeatherEnabled() async {
    if (source == WeatherSource.device) {
      final has = await _channel.checkLocationPermission();
      _locationPermissionGranted = has;
      if (!has) {
        await requestLocationPermission();
        return;
      }
    }
    await refresh(force: true);
  }

  /// Status-bar click: Breezy opens its app, built-in sources refresh.
  Future<void> onStatusBarActivated() async {
    if (source == WeatherSource.breezy) {
      await openBreezyWeather();
    } else {
      await refresh(force: true);
    }
  }

  /// Resolves a city or postal code to candidate places. The device's own
  /// geocoder is tried first because it understands postal codes (e.g. US ZIPs)
  /// and small places that Open-Meteo's gazetteer lacks; Open-Meteo is the
  /// fallback for devices without a geocoder backend.
  Future<List<WeatherLocation>> searchLocations(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final fromDevice = await _channel.geocodeLocationName(q);
    if (fromDevice.isNotEmpty) return fromDevice;
    try {
      return await _api.searchLocations(q, language: _settings?.appLanguage.isNotEmpty == true ? _settings!.appLanguage : "en");
    } on WeatherApiException catch (e) {
      developer.log("searchLocations failed", error: e);
      return const [];
    }
  }

  /// Opens this launcher's system "App info" page so the user can grant a
  /// location permission that was permanently denied.
  Future<void> openOwnAppInfo() async {
    try {
      final pkg = await _channel.getPackageName();
      if (pkg != null && pkg.isNotEmpty) await _channel.openAppInfo(pkg);
    } catch (e) {
      developer.log("openOwnAppInfo failed", error: e);
    }
  }

  Future<bool> openBreezyWeather() async {
    try {
      return await _channel.openBreezyWeather();
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------- breezy

  Future<void> _fetchLatestBreezy() async {
    try {
      _isBreezyInstalled = await _channel.isBreezyWeatherInstalled();
      final latestJson = await _channel.getLatestWeatherData();
      if (latestJson != null && latestJson.isNotEmpty) {
        _processWeatherJson(latestJson);
        _setStatus(WeatherStatus.ok);
      }
    } catch (e, stack) {
      developer.log("Failed to fetch latest weather data", error: e, stackTrace: stack);
    }
  }

  // -------------------------------------------------------------- built-in

  Future<void> _fetchBuiltIn({required bool force}) async {
    final settings = _settings;
    if (settings == null) return;
    if (!settings.showWeatherInStatusBar) {
      // Never do network or location work for a feature that is turned off.
      _setStatus(WeatherStatus.disabled);
      return;
    }

    final location = await _resolveLocation();
    if (location == null) return; // status already set by _resolveLocation

    final now = _now();
    final movedFar = _resolvedLocation != null && _resolvedLocation!.distanceKmTo(location) >= significantMoveKm;
    final throttled = _lastFetchAttempt != null && now.difference(_lastFetchAttempt!) < minFetchInterval;
    if (!force && throttled && !movedFar && _weatherData != null) {
      return;
    }

    _lastFetchAttempt = now;
    try {
      final payload = await _api.fetchWeather(location.latitude, location.longitude);
      payload["location"] = location.name ?? _resolvedLocation?.name;
      final json = jsonEncode(payload);
      _resolvedLocation = location;
      _lastUpdated = now;
      _consecutiveFailures = 0;
      _processWeatherJson(json);
      _persistCache(json, location, now);
      _setStatus(WeatherStatus.ok);
    } on WeatherApiException catch (e) {
      _consecutiveFailures++;
      developer.log("Weather fetch failed (${_consecutiveFailures}x)", error: e);
      _setStatus(WeatherStatus.networkError);
      _startPeriodicTimer(); // apply backoff
    } catch (e, stack) {
      _consecutiveFailures++;
      developer.log("Unexpected weather error", error: e, stackTrace: stack);
      _setStatus(WeatherStatus.networkError);
      _startPeriodicTimer();
    }
  }

  Future<WeatherLocation?> _resolveLocation() async {
    if (source == WeatherSource.manual) {
      final manual = _settings?.weatherManualLocation;
      if (manual == null) {
        _setStatus(WeatherStatus.locationNotSet);
        return null;
      }
      return manual;
    }

    // Device location through the Android runtime-permission model.
    bool granted;
    try {
      granted = await _channel.checkLocationPermission();
    } catch (_) {
      granted = false;
    }
    if (_locationPermissionGranted != granted) {
      _locationPermissionGranted = granted;
      notifyListeners();
    }
    if (!granted) {
      _setStatus(WeatherStatus.permissionDenied);
      return null;
    }

    try {
      final loc = await _channel.getDeviceLocation();
      if (loc != null) {
        // Keep the previous label if the platform could not reverse-geocode.
        if (loc.name == null && _resolvedLocation != null && _resolvedLocation!.distanceKmTo(loc) < significantMoveKm) {
          return WeatherLocation(latitude: loc.latitude, longitude: loc.longitude, name: _resolvedLocation!.name);
        }
        return loc;
      }
    } catch (e) {
      developer.log("getDeviceLocation failed", error: e);
    }

    // No fix right now (TV just booted, Wi-Fi scan pending): reuse the last
    // known forecast location rather than showing nothing.
    if (_resolvedLocation != null) return _resolvedLocation;
    _setStatus(WeatherStatus.locationUnavailable);
    return null;
  }

  // ----------------------------------------------------------------- cache

  void _restoreCache() {
    final prefs = _prefs;
    if (prefs == null || source == WeatherSource.breezy) return;
    final json = prefs.getString(_cacheJsonKey);
    final timeMs = prefs.getInt(_cacheTimeKey);
    if (json == null || timeMs == null) return;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timeMs);
    if (_now().difference(cachedAt) > cacheMaxAge) return;
    _resolvedLocation = WeatherLocation.fromJsonString(prefs.getString(_cacheLocationKey));
    _lastUpdated = cachedAt;
    _processWeatherJson(json);
  }

  void _persistCache(String json, WeatherLocation location, DateTime at) {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(_cacheJsonKey, json);
    prefs.setInt(_cacheTimeKey, at.millisecondsSinceEpoch);
    prefs.setString(_cacheLocationKey, location.toJsonString());
  }

  // --------------------------------------------------------------- helpers

  void _setStatus(WeatherStatus s) {
    if (_status == s) return;
    _status = s;
    notifyListeners();
  }

  void _processWeatherJson(String jsonString) {
    if (jsonString == _lastJson && _weatherData != null) {
      return;
    }
    try {
      _weatherData = WeatherData.fromJsonString(jsonString);
      _lastJson = jsonString;
      notifyListeners();
    } catch (e, stack) {
      developer.log("Failed to parse weather JSON", error: e, stackTrace: stack);
    }
  }

  @override
  void dispose() {
    if (!_isTest) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _settings?.removeListener(_onSettingsChanged);
    _refreshTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

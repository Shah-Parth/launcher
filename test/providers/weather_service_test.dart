import 'dart:async';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/models/weather_location.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/weather/weather_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  builtInSourceTests();

  late MockFLauncherChannel mockChannel;
  late StreamController<dynamic> weatherStreamController;
  late WeatherService weatherService;

  const validWeatherJson = '''
  {
    "timestamp": 1690000000,
    "location": "Berlin",
    "currentTemp": 18,
    "currentConditionCode": 800,
    "currentCondition": "Sunny",
    "forecasts": [
      {
        "conditionCode": 500,
        "precipProbability": 70,
        "minTemp": 14,
        "maxTemp": 20
      }
    ]
  }
  ''';

  setUp(() {
    mockChannel = MockFLauncherChannel();
    weatherStreamController = StreamController<dynamic>.broadcast();

    when(mockChannel.isBreezyWeatherInstalled()).thenAnswer((_) async => true);
    when(mockChannel.getLatestWeatherData()).thenAnswer((_) async => validWeatherJson);
    when(mockChannel.addWeatherChangedListener(any)).thenAnswer((invocation) {
      final void Function(dynamic) listener = invocation.positionalArguments[0];
      return weatherStreamController.stream.listen(listener);
    });
    when(mockChannel.openBreezyWeather()).thenAnswer((_) async => true);
  });

  tearDown(() {
    weatherStreamController.close();
  });

  group('WeatherService', () {
    test('initializes with cached data and Breezy installed status', () async {
      weatherService = WeatherService(mockChannel);
      while (!weatherService.initialized) {
        await Future.delayed(Duration.zero);
      }

      expect(weatherService.isBreezyInstalled, true);
      expect(weatherService.hasWeather, true);
      expect(weatherService.weatherData?.location, "Berlin");
      expect(weatherService.weatherData?.currentTemp, 18);
      expect(weatherService.weatherData?.hasWarning, true);
      expect(weatherService.weatherData?.warningType, WeatherWarningType.rain);
      expect(weatherService.weatherData?.warningText, "70% Rain today");
    });

    test('updates weather data when stream emits new json', () async {
      weatherService = WeatherService(mockChannel);
      while (!weatherService.initialized) {
        await Future.delayed(Duration.zero);
      }

      int notifyCount = 0;
      weatherService.addListener(() {
        notifyCount++;
      });

      const updatedJson = '''
      {
        "location": "Munich",
        "currentTemp": 24,
        "currentConditionCode": 800,
        "currentCondition": "Clear",
        "forecasts": []
      }
      ''';

      weatherStreamController.add(updatedJson);
      await Future.delayed(Duration.zero);

      expect(notifyCount, greaterThanOrEqualTo(1));
      expect(weatherService.weatherData?.location, "Munich");
      expect(weatherService.weatherData?.currentTemp, 24);
      expect(weatherService.weatherData?.hasWarning, false);
    });

    test('openBreezyWeather calls channel method', () async {
      weatherService = WeatherService(mockChannel);
      while (!weatherService.initialized) {
        await Future.delayed(Duration.zero);
      }

      final success = await weatherService.openBreezyWeather();
      expect(success, true);
      verify(mockChannel.openBreezyWeather()).called(1);
    });

    test('deduplicates identical weather json without notifying listeners', () async {
      weatherService = WeatherService(mockChannel);
      while (!weatherService.initialized) {
        await Future.delayed(Duration.zero);
      }

      int notifyCount = 0;
      weatherService.addListener(() {
        notifyCount++;
      });

      // Emitting the exact same JSON that was loaded on init
      weatherStreamController.add(validWeatherJson);
      await Future.delayed(Duration.zero);

      expect(notifyCount, 0);
    });

    test('refreshes weather on app lifecycle resumed', () async {
      weatherService = WeatherService(mockChannel);
      while (!weatherService.initialized) {
        await Future.delayed(Duration.zero);
      }

      const updatedJson = '''
      {
        "location": "Hamburg",
        "currentTemp": 15,
        "currentConditionCode": 800,
        "currentCondition": "Clear",
        "forecasts": []
      }
      ''';
      when(mockChannel.getLatestWeatherData()).thenAnswer((_) async => updatedJson);

      weatherService.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(weatherService.weatherData?.location, "Hamburg");
      expect(weatherService.weatherData?.currentTemp, 15);
    });
  });
}

// ---------------------------------------------------------------------------
// Built-in sources (device location / manual) added in this fork.
// ---------------------------------------------------------------------------

class _FakeWeatherApi implements WeatherApi {
  int fetchCalls = 0;
  int searchCalls = 0;
  List<(double, double)> requested = [];
  Object? failWith;
  Map<String, dynamic> Function(double lat, double lon)? payload;

  @override
  Future<Map<String, dynamic>> fetchWeather(double latitude, double longitude) async {
    fetchCalls++;
    requested.add((latitude, longitude));
    if (failWith != null) throw failWith!;
    return payload?.call(latitude, longitude) ??
        {
          "currentTemp": 11,
          "currentConditionCode": 800,
          "currentCondition": "Clear",
          "forecasts": [],
        };
  }

  @override
  Future<List<WeatherLocation>> searchLocations(String query, {String language = "en"}) async {
    searchCalls++;
    if (failWith != null) throw failWith!;
    return [WeatherLocation(latitude: 1, longitude: 2, name: "Result for $query")];
  }
}

void builtInSourceTests() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFLauncherChannel channel;
  late MockSettingsService settings;
  late _FakeWeatherApi api;
  late SharedPreferences prefs;
  late StreamController<dynamic> stream;

  const dulles = WeatherLocation(latitude: 38.9531, longitude: -77.4565, name: "Dulles, Virginia");
  const seattle = WeatherLocation(latitude: 47.6062, longitude: -122.3321, name: "Seattle, Washington");

  Future<WeatherService> start({DateTime Function()? clock}) async {
    final service = WeatherService(channel, settingsService: settings, api: api, preferences: prefs, clock: clock);
    while (!service.initialized) {
      await Future.delayed(Duration.zero);
    }
    return service;
  }

  group('WeatherService built-in sources', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      channel = MockFLauncherChannel();
      settings = MockSettingsService();
      api = _FakeWeatherApi();
      stream = StreamController<dynamic>.broadcast();

      when(settings.weatherSource).thenReturn(WEATHER_SOURCE_DEVICE);
      when(settings.weatherManualLocation).thenReturn(null);
      when(settings.showWeatherInStatusBar).thenReturn(true);
      when(settings.appLanguage).thenReturn("");
      when(channel.addWeatherChangedListener(any)).thenAnswer((inv) {
        final void Function(dynamic) listener = inv.positionalArguments[0];
        return stream.stream.listen(listener);
      });
      when(channel.isBreezyWeatherInstalled()).thenAnswer((_) async => false);
      when(channel.getLatestWeatherData()).thenAnswer((_) async => null);
      when(channel.checkLocationPermission()).thenAnswer((_) async => true);
      when(channel.requestLocationPermission()).thenAnswer((_) async => true);
      when(channel.getDeviceLocation()).thenAnswer((_) async => dulles);
    });

    tearDown(() => stream.close());

    test('device source: fetches for the device position when permission is granted', () async {
      final service = await start();
      expect(service.source, WeatherSource.device);
      expect(service.locationPermissionGranted, true);
      expect(api.fetchCalls, 1);
      expect(api.requested.single, (dulles.latitude, dulles.longitude));
      expect(service.hasWeather, true);
      expect(service.weatherData!.currentTemp, 11);
      expect(service.weatherData!.location, "Dulles, Virginia");
      expect(service.status, WeatherStatus.ok);
      expect(service.lastUpdated, isNotNull);
      verifyNever(channel.requestLocationPermission());
    });

    test('device source: never touches location or network without permission, and never prompts on its own', () async {
      when(channel.checkLocationPermission()).thenAnswer((_) async => false);
      final service = await start();
      expect(service.locationPermissionGranted, false);
      expect(service.status, WeatherStatus.permissionDenied);
      expect(service.hasWeather, false);
      expect(api.fetchCalls, 0);
      verifyNever(channel.getDeviceLocation());
      verifyNever(channel.requestLocationPermission());
    });

    test('requestLocationPermission goes through the channel and fetches once granted', () async {
      bool granted = false;
      when(channel.checkLocationPermission()).thenAnswer((_) async => granted);
      when(channel.requestLocationPermission()).thenAnswer((_) async {
        granted = true;
        return true;
      });
      final service = await start();
      expect(api.fetchCalls, 0);

      expect(await service.requestLocationPermission(), true);
      expect(service.locationPermissionGranted, true);
      expect(api.fetchCalls, 1);
      expect(service.status, WeatherStatus.ok);
    });

    test('does no work at all while the weather status bar is turned off', () async {
      when(settings.showWeatherInStatusBar).thenReturn(false);
      final service = await start();
      expect(service.status, WeatherStatus.disabled);
      expect(api.fetchCalls, 0);
      verifyNever(channel.checkLocationPermission());
      verifyNever(channel.getDeviceLocation());
    });

    test('manual source: uses the stored location and reports when none is set', () async {
      when(settings.weatherSource).thenReturn(WEATHER_SOURCE_MANUAL);
      final service = await start();
      expect(service.status, WeatherStatus.locationNotSet);
      expect(api.fetchCalls, 0);
      verifyNever(channel.checkLocationPermission());

      when(settings.weatherManualLocation).thenReturn(seattle);
      await service.refresh(force: true);
      expect(api.requested.single, (seattle.latitude, seattle.longitude));
      expect(service.weatherData!.location, "Seattle, Washington");
    });

    test('throttles repeated refreshes but re-fetches after a significant move', () async {
      var now = DateTime(2026, 11, 11, 12);
      final service = await start(clock: () => now);
      expect(api.fetchCalls, 1);

      await service.refresh(); // same place, 0 minutes later
      expect(api.fetchCalls, 1);

      when(channel.getDeviceLocation()).thenAnswer((_) async => seattle); // travelled
      await service.refresh();
      expect(api.fetchCalls, 2);
      expect(service.resolvedLocation, seattle);

      now = now.add(const Duration(minutes: 31));
      await service.refresh();
      expect(api.fetchCalls, 3);
    });

    test('falls back to the last known forecast location when no fix is available', () async {
      final service = await start();
      when(channel.getDeviceLocation()).thenAnswer((_) async => null);
      await service.refresh(force: true);
      expect(api.fetchCalls, 2);
      expect(api.requested.last, (dulles.latitude, dulles.longitude));
      expect(service.status, WeatherStatus.ok);
    });

    test('reports locationUnavailable when there has never been a fix', () async {
      when(channel.getDeviceLocation()).thenAnswer((_) async => null);
      final service = await start();
      expect(service.status, WeatherStatus.locationUnavailable);
      expect(api.fetchCalls, 0);
    });

    test('network failure keeps the previous forecast and reports networkError', () async {
      final service = await start();
      api.failWith = const WeatherApiException("offline");
      await service.refresh(force: true);
      expect(service.status, WeatherStatus.networkError);
      expect(service.hasWeather, true);
      expect(service.weatherData!.currentTemp, 11);
    });

    test('persists the forecast and restores it on next start while fresh', () async {
      final first = await start();
      expect(first.hasWeather, true);
      first.dispose();

      api = _FakeWeatherApi()..failWith = const WeatherApiException("offline at boot");
      final second = await start();
      expect(second.hasWeather, true, reason: "cached forecast should be shown before/without network");
      expect(second.weatherData!.currentTemp, 11);
      expect(second.resolvedLocation, dulles);
    });

    test('ignores a stale cache', () async {
      final first = await start();
      first.dispose();

      api = _FakeWeatherApi()..failWith = const WeatherApiException("offline");
      final later = DateTime.now().add(const Duration(hours: 7));
      final second = await start(clock: () => later);
      expect(second.hasWeather, false);
    });

    test('Breezy broadcasts are ignored unless Breezy is the selected source', () async {
      final service = await start();
      stream.add('{"currentTemp": 99, "currentConditionCode": 800, "forecasts": []}');
      await pumpEventQueue();
      expect(service.weatherData!.currentTemp, 11);
    });

    test('status bar activation refreshes built-in sources instead of opening Breezy', () async {
      final service = await start();
      when(channel.openBreezyWeather()).thenAnswer((_) async => true);
      await service.onStatusBarActivated();
      expect(api.fetchCalls, 2);
      verifyNever(channel.openBreezyWeather());
    });

    test('searchLocations delegates to the API and swallows failures', () async {
      final service = await start();
      final results = await service.searchLocations("20152");
      expect(results.single.name, "Result for 20152");
      api.failWith = const WeatherApiException("down");
      expect(await service.searchLocations("20152"), isEmpty);
    });
  });
}

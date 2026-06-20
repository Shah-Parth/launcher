/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
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

import 'package:flutter/services.dart';

class FLauncherChannel {
  static const _methodChannel = MethodChannel('me.efesser.flauncher/method');
  static const _appsEventChannel = EventChannel('me.efesser.flauncher/event_apps');
  static const _networkEventChannel = EventChannel('me.efesser.flauncher/event_network');
  static const _notificationsEventChannel = EventChannel('me.efesser.flauncher/event_notifications');

  Future<List<Map<dynamic, dynamic>>> getApplications() async {
    List<Map<dynamic, dynamic>>? applications = await _methodChannel.invokeListMethod("getApplications");
    return applications!;
  }

  Future<Uint8List> getApplicationBanner(String packageName) async {
    Uint8List bytes = await _methodChannel.invokeMethod("getApplicationBanner", packageName);
    return bytes;
  }

  Future<Uint8List> getApplicationIcon(String packageName) async {
    Uint8List bytes = await _methodChannel.invokeMethod("getApplicationIcon", packageName);
    return bytes;
  }

  Future<void> launchActivityFromAction(String action) async => await _methodChannel.invokeMethod('launchActivityFromAction', action);

  Future<void> launchApp(String packageName) async => await _methodChannel.invokeMethod('launchApp', packageName);

  Future<void> openSettings() async => await _methodChannel.invokeMethod('openSettings');

  Future<void> openAppInfo(String packageName) async => await _methodChannel.invokeMethod('openAppInfo', packageName);

  Future<void> uninstallApp(String packageName) async => await _methodChannel.invokeMethod('uninstallApp', packageName);

  Future<bool> isDefaultLauncher() async => await _methodChannel.invokeMethod('isDefaultLauncher');

  Future<bool> checkForGetContentAvailability() async =>
      await _methodChannel.invokeMethod("checkForGetContentAvailability");

  Future<Map<String, dynamic>> getActiveNetworkInformation() async {
    Map<dynamic, dynamic> map = await _methodChannel.invokeMethod("getActiveNetworkInformation");
    return map.cast<String, dynamic>();
  }

  Future<int> getDailyDataUsage() async {
    try {
      final int usage = await _methodChannel.invokeMethod("getDailyDataUsage");
      return usage;
    } on PlatformException catch (_) {
      return -1;
    }
  }

  Future<int> getWeeklyDataUsage() async {
    try {
      final int usage = await _methodChannel.invokeMethod("getWeeklyDataUsage");
      return usage;
    } on PlatformException catch (_) {
      return -1;
    }
  }

  Future<int> getMonthlyDataUsage() async {
    try {
      final int usage = await _methodChannel.invokeMethod("getMonthlyDataUsage");
      return usage;
    } on PlatformException catch (_) {
      return -1;
    }
  }

  Future<bool> checkUsageStatsPermission() async =>
      await _methodChannel.invokeMethod("checkUsageStatsPermission");

  Future<void> requestUsageStatsPermission() async =>
      await _methodChannel.invokeMethod("requestUsageStatsPermission");

  Future<void> openWifiSettings() async =>
      await _methodChannel.invokeMethod("openWifiSettings");

  Future<void> openDefaultLauncherSettings() async =>
      await _methodChannel.invokeMethod("openDefaultLauncherSettings");

  Future<void> startAmbientMode() async => await _methodChannel.invokeMethod("startAmbientMode");

  void addAppsChangedListener(void Function(Map<String, dynamic>) listener) =>
      _appsEventChannel.receiveBroadcastStream().listen((event) {
        Map<dynamic, dynamic> eventMap = event;
        listener(eventMap.cast<String, dynamic>());
      });

  void addNetworkChangedListener(void Function(Map<String, dynamic>) listener) =>
      _networkEventChannel.receiveBroadcastStream().listen((event) {
        Map<dynamic, dynamic> eventMap = event;
        listener(eventMap.cast<String, dynamic>());
      });

  Future<List<Map<dynamic, dynamic>>> getTvInputs() async {
    try {
      final List<dynamic> inputs = await _methodChannel.invokeMethod("getTvInputs");
      return inputs.cast<Map<dynamic, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> launchTvInput(String inputId) async {
    try {
      final bool success = await _methodChannel.invokeMethod("launchTvInput", inputId);
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkNotificationListenerPermission() async =>
      await _methodChannel.invokeMethod("checkNotificationListenerPermission");

  Future<void> requestNotificationListenerPermission() async =>
      await _methodChannel.invokeMethod("requestNotificationListenerPermission");

  Future<bool> checkOverlayPermission() async =>
      await _methodChannel.invokeMethod("checkOverlayPermission");

  Future<void> requestOverlayPermission() async =>
      await _methodChannel.invokeMethod("requestOverlayPermission");

  Future<List<Map<dynamic, dynamic>>> getActiveNotifications() async {
    try {
      final List<dynamic> list = await _methodChannel.invokeMethod("getActiveNotifications");
      return list.cast<Map<dynamic, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  StreamSubscription addNotificationsChangedListener(void Function(List<Map<dynamic, dynamic>>) listener) =>
      _notificationsEventChannel.receiveBroadcastStream().listen((event) {
        final List<dynamic> eventList = event;
        listener(eventList.cast<Map<dynamic, dynamic>>());
      });

  Future<bool> dismissNotification(String key) async {
    try {
      final bool success = await _methodChannel.invokeMethod("dismissNotification", {"key": key});
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dismissAllNotifications() async {
    try {
      final bool success = await _methodChannel.invokeMethod("dismissAllNotifications");
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<dynamic, dynamic>>> getWatchNextPrograms() async {
    try {
      final List<dynamic>? list = await _methodChannel.invokeMethod("getWatchNextPrograms");
      return list?.cast<Map<dynamic, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Uint8List?> getWatchNextPoster(String posterArtUri) async {
    try {
      final Uint8List? bytes = await _methodChannel.invokeMethod("getWatchNextPoster", {"posterArtUri": posterArtUri});
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<bool> launchWatchNextProgram(String intentUri) async {
    try {
      final bool success = await _methodChannel.invokeMethod("launchWatchNextProgram", {"intentUri": intentUri});
      return success;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsService extends ChangeNotifier {
  final FLauncherChannel _channel;
  Map<String, int> _notificationCounts = {};
  bool _hasPermission = false;
  bool _hasOverlayPermission = false;
  bool _systemPopupEnabled = false;
  bool _initialized = false;
  StreamSubscription? _subscription;
  int _callCount = 0;
  SharedPreferences? _prefs;

  NotificationsService(this._channel) {
    _init();
  }

  Map<String, int> get notificationCounts => Map.unmodifiable(_notificationCounts);
  bool get hasPermission => _hasPermission;
  bool get hasOverlayPermission => _hasOverlayPermission;
  bool get systemPopupEnabled => _systemPopupEnabled;
  bool get initialized => _initialized;

  int getNotificationCount(String packageName) {
    return _notificationCounts[packageName] ?? 0;
  }

  Future<void> _init() async {
    final localCallCount = ++_callCount;
    _prefs = await SharedPreferences.getInstance();
    if (localCallCount != _callCount) return;

    _systemPopupEnabled = _prefs?.getBool('system_notifications_popup') ?? false;

    final bool allowed = await _channel.checkNotificationListenerPermission();
    if (localCallCount != _callCount) return;

    _hasPermission = allowed;

    final bool overlayAllowed = await _channel.checkOverlayPermission();
    if (localCallCount != _callCount) return;

    _hasOverlayPermission = overlayAllowed;

    if (_hasPermission) {
      final List<Map<dynamic, dynamic>> list = await _channel.getActiveNotifications();
      if (localCallCount != _callCount) return;

      _updateNotificationCounts(list);

      _subscription = _channel.addNotificationsChangedListener((eventList) {
        _updateNotificationCounts(eventList);
      });
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> checkPermission() async {
    final localCallCount = ++_callCount;
    final bool allowed = await _channel.checkNotificationListenerPermission();
    if (localCallCount != _callCount) return;

    if (_hasPermission != allowed) {
      _hasPermission = allowed;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    if (!_hasPermission) return;

    final localCallCount = ++_callCount;
    final List<Map<dynamic, dynamic>> list = await _channel.getActiveNotifications();
    if (localCallCount != _callCount) return;

    _updateNotificationCounts(list);
  }

  void _updateNotificationCounts(List<Map<dynamic, dynamic>> list) {
    final Map<String, int> newCounts = {};
    for (final item in list) {
      final String? pkg = item['packageName'] as String?;
      final int? count = item['count'] as int?;
      if (pkg != null && count != null) {
        newCounts[pkg] = count;
      }
    }

    // Direct comparison to avoid unnecessary notifies
    bool changed = false;
    if (_notificationCounts.length != newCounts.length) {
      changed = true;
    } else {
      for (final key in newCounts.keys) {
        if (_notificationCounts[key] != newCounts[key]) {
          changed = true;
          break;
        }
      }
    }

    if (changed) {
      _notificationCounts = newCounts;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    await _channel.requestNotificationListenerPermission();
    // Re-check after returning from settings (handled externally or via polling/resume)
  }

  Future<void> checkOverlayPermission() async {
    final localCallCount = ++_callCount;
    final bool allowed = await _channel.checkOverlayPermission();
    if (localCallCount != _callCount) return;

    if (_hasOverlayPermission != allowed) {
      _hasOverlayPermission = allowed;
      notifyListeners();
    }
  }

  Future<void> requestOverlayPermission() async {
    await _channel.requestOverlayPermission();
  }

  Future<void> setSystemPopupEnabled(bool enabled) async {
    _systemPopupEnabled = enabled;
    await _prefs?.setBool('system_notifications_popup', enabled);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

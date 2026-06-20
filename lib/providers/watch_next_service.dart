import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flauncher/flauncher_channel.dart';
import '../models/watch_next_program.dart';

class WatchNextService extends ChangeNotifier {
  final FLauncherChannel _channel;
  List<WatchNextProgram> _programs = [];
  bool _initialized = false;
  Timer? _refreshTimer;

  WatchNextService(this._channel) {
    _init();
  }

  List<WatchNextProgram> get programs => List.unmodifiable(_programs);
  bool get initialized => _initialized;

  Future<void> _init() async {
    await refresh();
    _initialized = true;
    notifyListeners();

    // Refresh every 30 seconds to keep EPG/Playback progress up to date
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      final List<Map<dynamic, dynamic>> list = await _channel.getWatchNextPrograms();
      final List<WatchNextProgram> newPrograms = [];
      for (final map in list) {
        final program = WatchNextProgram.fromMap(map);
        if (program.posterArtUri.isNotEmpty) {
          // Find existing bytes if already loaded to avoid refetching
          WatchNextProgram? existing;
          for (final p in _programs) {
            if (p.id == program.id) {
              existing = p;
              break;
            }
          }
          if (existing != null && existing.posterBytes != null) {
            program.posterBytes = existing.posterBytes;
          } else {
            program.posterBytes = await _channel.getWatchNextPoster(program.posterArtUri);
          }
        }
        newPrograms.add(program);
      }
      _programs = newPrograms;
      notifyListeners();
    } catch (e) {
      // Log or ignore
    }
  }

  Future<bool> launch(WatchNextProgram program) async {
    if (program.intentUri.isNotEmpty) {
      return await _channel.launchWatchNextProgram(program.intentUri);
    } else if (program.packageName.isNotEmpty) {
      await _channel.launchApp(program.packageName);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

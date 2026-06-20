import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/models/watch_next_program.dart';
import '../mocks.mocks.dart';

void main() {
  late MockFLauncherChannel mockChannel;
  late WatchNextService watchNextService;

  setUp(() {
    mockChannel = MockFLauncherChannel();
    // Default stubs
    when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => []);
  });

  group('WatchNextService Initialization', () {
    test('initializes with empty programs list', () async {
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      expect(watchNextService.programs, isEmpty);
      verify(mockChannel.getWatchNextPrograms()).called(1);
    });

    test('fetches watch next programs and poster art on init', () async {
      final fakePrograms = [
        {
          'id': 1,
          'packageName': 'com.netflix.mediaclient',
          'title': 'Stranger Things',
          'description': 'S1:E1 Chapter One',
          'watchNextType': 1,
          'lastEngagementTime': 1600000000,
          'playbackPosition': 500,
          'duration': 3000,
          'intentUri': 'intent://netflix_uri',
          'posterArtUri': 'content://netflix/poster/1'
        }
      ];

      final mockPosterBytes = Uint8List.fromList([1, 2, 3]);

      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => fakePrograms);
      when(mockChannel.getWatchNextPoster('content://netflix/poster/1'))
          .thenAnswer((_) async => mockPosterBytes);

      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      expect(watchNextService.programs.length, 1);
      expect(watchNextService.programs[0].title, 'Stranger Things');
      expect(watchNextService.programs[0].posterBytes, mockPosterBytes);

      verify(mockChannel.getWatchNextPrograms()).called(1);
      verify(mockChannel.getWatchNextPoster('content://netflix/poster/1')).called(1);
    });
  });

  group('WatchNextService launch', () {
    test('launches program via channel intentUri', () async {
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      final program = WatchNextProgram(
        id: 1,
        packageName: 'com.netflix.mediaclient',
        title: 'Stranger Things',
        description: 'S1:E1',
        watchNextType: 1,
        lastEngagementTime: 1600000000,
        playbackPosition: 500,
        duration: 3000,
        intentUri: 'intent://netflix_uri',
        posterArtUri: 'content://netflix/poster/1',
      );

      when(mockChannel.launchWatchNextProgram(any)).thenAnswer((_) async => true);

      final success = await watchNextService.launch(program);

      expect(success, isTrue);
      verify(mockChannel.launchWatchNextProgram('intent://netflix_uri')).called(1);
    });

    test('fallback launches app packageName when intentUri empty', () async {
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      final program = WatchNextProgram(
        id: 1,
        packageName: 'com.netflix.mediaclient',
        title: 'Stranger Things',
        description: 'S1:E1',
        watchNextType: 1,
        lastEngagementTime: 1600000000,
        playbackPosition: 500,
        duration: 3000,
        intentUri: '',
        posterArtUri: '',
      );

      when(mockChannel.launchApp(any)).thenAnswer((_) async => null);

      final success = await watchNextService.launch(program);

      expect(success, isTrue);
      verify(mockChannel.launchApp('com.netflix.mediaclient')).called(1);
    });
  });
}

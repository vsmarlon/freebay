import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/components/app_video_viewer.dart';
import 'package:freebay/core/components/app_video_viewer/video_viewer_controls.dart';
import 'package:freebay/features/chat/presentation/widgets/video_message_bubble.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  final previousPlatform = VideoPlayerPlatform.instance;
  tearDown(() => VideoPlayerPlatform.instance = previousPlatform);

  testWidgets('chat preview stays paused and is handed to fullscreen', (
    tester,
  ) async {
    final platform = _FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VideoMessageBubble(
            videoUrl: 'https://media.example/video.mp4',
            isMe: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(platform.createCount, 1);
    expect(platform.playCount, 0);
    expect(
      tester
          .widget<VideoPlayer>(find.byType(VideoPlayer))
          .controller
          .value
          .isInitialized,
      isTrue,
    );
    final videoTopLeft = tester.getTopLeft(find.byType(VideoPlayer));
    await tester.tapAt(videoTopLeft + const Offset(12, 12));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(platform.createCount, 1);
    expect(find.byType(VideoViewerControls), findsOneWidget);
    expect(platform.playCount, 1);
    expect(find.text('00:00 / 00:10'), findsOneWidget);
  });

  testWidgets('fullscreen controls expose position, playback, mute and retry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final platform = _FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showFullScreenVideo(context, 'file:///fixture/video.mp4'),
            child: const Text('Open video'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open video'));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('00:00 / 00:10'), findsOneWidget);
    expect(find.bySemanticsLabel('Posição do vídeo'), findsOneWidget);
    expect(find.bySemanticsLabel('Pausar vídeo'), findsOneWidget);
    expect(find.bySemanticsLabel('Desativar som'), findsOneWidget);

    platform.position = const Duration(seconds: 3);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('00:03 / 00:10'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Pausar vídeo'));
    await tester.pump();
    expect(platform.pauseCount, greaterThan(0));
    await tester.tap(find.bySemanticsLabel('Desativar som'));
    await tester.pump();
    expect(platform.volumes.last, 0);
    await tester.tap(find.bySemanticsLabel('Ativar som'));
    await tester.pump();
    expect(platform.volumes.last, 1);

    await tester.drag(
      find.byType(VideoProgressIndicator),
      const Offset(160, 0),
    );
    await tester.pump();
    expect(platform.seeks, isNotEmpty);
    expect(platform.seeks.last, greaterThan(Duration.zero));

    await tester.tap(find.bySemanticsLabel('Reproduzir vídeo').last);
    await tester.pump();
    platform.position = const Duration(seconds: 10);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.bySemanticsLabel('Reproduzir novamente'), findsNWidgets(2));
    semantics.dispose();
  });

  testWidgets('failed media offers an accessible retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoViewerError(
            message: 'Vídeo indisponível',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tentar novamente'));
    expect(retried, isTrue);
  });
}

class _FakeVideoPlatform extends VideoPlayerPlatform {
  int createCount = 0;
  int playCount = 0;
  int pauseCount = 0;
  Duration position = Duration.zero;
  final volumes = <double>[];
  final seeks = <Duration>[];

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    createCount++;
    return createCount;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return Stream<VideoEvent>.value(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 10),
        size: const Size(640, 360),
      ),
    );
  }

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async =>
      volumes.add(volume);

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> play(int playerId) async => playCount++;

  @override
  Future<void> pause(int playerId) async => pauseCount++;

  @override
  Future<void> seekTo(int playerId, Duration value) async {
    position = value;
    seeks.add(value);
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand();
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mercury/features/playback/application/playback_controller.dart';
import 'package:mercury/integrations/youtube_playback/youtube_embed_engine.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('the hidden video layer lets the app go idle', (tester) async {
    final pages = Directory.systemTemp.createTempSync('mercury_yt_');
    addTearDown(() => pages.deleteSync(recursive: true));
    // Nothing from YouTube plays, so the player is never readied: its
    // spinner, offstage, must not keep the app drawing frames.
    await TestApp.pump(
      tester,
      overrides: [
        youTubeEngineProvider.overrideWithValue(
          YouTubeEmbedEngine(pageDir: pages),
        ),
      ],
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}

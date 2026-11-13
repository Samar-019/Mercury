import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercury/core/widgets/dialogs.dart';
import 'package:mercury/core/widgets/menus.dart';
import 'package:mercury/features/accounts/domain/account_connection.dart';
import 'package:mercury/features/analysis/application/analysis_providers.dart';
import 'package:mercury/features/analysis/presentation/track_analysis_dialog.dart';
import 'package:mercury/features/discover/presentation/dislike_actions.dart';
import 'package:mercury/features/library/application/library_providers.dart';
import 'package:mercury/features/playback/application/playback_controller.dart';
import 'package:mercury/features/playlists/presentation/add_to_playlist.dart';
import 'package:mercury/features/youtube/application/youtube_providers.dart';
import 'package:mercury/features/youtube/presentation/add_to_youtube_playlist.dart';
import 'package:mercury/shared/models/media.dart';
import 'package:url_launcher/url_launcher.dart';

/// The context menu for [track] at [position] (global): queue, radio,
/// playlists, favorites and "Not interested". [onPlay] adds "Play" first;
/// [onRemove] adds a remove action named [removeLabel].
Future<void> showTrackMenu(
  BuildContext context,
  WidgetRef ref,
  Track track,
  Offset position, {
  VoidCallback? onPlay,
  VoidCallback? onRemove,
  String removeLabel = 'Remove from playlist',
}) async {
  final playback = ref.read(playbackProvider.notifier);
  final youTube =
      track.source == MediaSource.youtube &&
      ref.read(accountServiceProvider).current.isConnected;
  final favorite = track.localId != null
      ? track.isFavorite
      : ref.read(isFavoriteSongProvider(track.id));
  final action = await showMercuryMenu<String>(
    context,
    anchor: position & Size.zero,
    items: [
      if (onPlay != null)
        const MercuryMenuItem('play', 'Play', icon: Icons.play_arrow_rounded),
      const MercuryMenuItem(
        'next',
        'Play next',
        icon: Icons.playlist_play_rounded,
      ),
      const MercuryMenuItem(
        'queue',
        'Add to queue',
        icon: Icons.queue_music_rounded,
      ),
      const MercuryMenuItem('radio', 'Start radio', icon: Icons.radio_rounded),
      const MercuryMenuItem(
        'playlist',
        'Add to playlist…',
        icon: Icons.playlist_add_rounded,
      ),
      // With an account the heart saves to YouTube instead (see
      // YouTubeSaveButton).
      if (!youTube)
        MercuryMenuItem(
          'favorite',
          favorite ? 'Remove from favorites' : 'Add to favorites',
          icon: favorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
        ),
      if (track.source == MediaSource.youtube)
        const MercuryMenuItem(
          'open',
          'Open in YouTube Music',
          icon: Icons.open_in_new_rounded,
        ),
      if (ref.read(analysisRunnerProvider) != null)
        const MercuryMenuItem(
          'analysis',
          'Show analysis',
          icon: Icons.graphic_eq_rounded,
        ),
      ...dislikeMenuItems(track),
      if (onRemove != null)
        MercuryMenuItem('remove', removeLabel, icon: Icons.remove_circle_outline),
    ],
  );
  if (!context.mounted) return;
  switch (action) {
    case 'play':
      onPlay?.call();
    case 'next':
      playback.playNext(track);
      showToast(context, 'Playing next: ${track.title}');
    case 'queue':
      playback.addToQueue([track]);
      showToast(context, 'Added to queue');
    case 'radio':
      unawaited(playback.startRadio(track));
    case 'playlist' when youTube:
      await addToYouTubePlaylist(context, ref, track);
    case 'playlist':
      await addToPlaylist(context, ref, [track]);
    case 'favorite':
      unawaited(playback.toggleFavorite(track));
    case 'open':
      unawaited(
        launchUrl(
          youTubeMusicUrl(videoId: track.uri),
          mode: LaunchMode.externalApplication,
        ),
      );
    case 'analysis':
      unawaited(showTrackAnalysis(context, track));
    case 'remove':
      onRemove?.call();
    default:
      await runDislikeAction(context, ref, action, track);
  }
}

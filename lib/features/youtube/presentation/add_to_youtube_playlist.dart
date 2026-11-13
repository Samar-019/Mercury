import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercury/app/theme/design_tokens.dart';
import 'package:mercury/core/widgets/dialogs.dart';
import 'package:mercury/features/youtube/application/youtube_providers.dart';
import 'package:mercury/features/youtube/application/youtube_save.dart';
import 'package:mercury/features/youtube/presentation/save_button.dart';
import 'package:mercury/integrations/youtube_data/youtube_api.dart';
import 'package:mercury/shared/models/media.dart';

/// "Add to playlist…" for a YouTube song: the user's YouTube playlists with
/// a check on those that contain it. Tapping one adds or removes the song
/// on YouTube right away; the dialog stays open, as on YouTube.
Future<void> addToYouTubePlaylist(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  if (!await ensureWriteAccess(context, ref) || !context.mounted) return;
  final create = await showGlassDialog<bool>(
    context,
    builder: (_) => _Body(track),
  );
  if (create != true || !context.mounted) return;

  final name = await promptText(
    context,
    title: 'New YouTube playlist',
    confirmLabel: 'Create',
    hint: 'Playlist name',
  );
  if (name == null || !context.mounted) return;
  final ctrl = ref.read(youTubeSaveProvider.notifier);
  try {
    final playlist = await ctrl.createPlaylist(name);
    final outcome = await ctrl.addTo(playlist.id, track);
    if (context.mounted) {
      showToast(
        context,
        outcome.result == SaveResult.saved
            ? 'Created "${playlist.title}" (private) with this song'
            : outcome.message ?? 'Created "${playlist.title}" (private)',
      );
    }
  } on YouTubeApiException catch (e) {
    if (context.mounted) {
      showToast(context, "Couldn't create the playlist. ${e.message}");
    }
  }
}

/// Pops true for "New playlist…".
class _Body extends ConsumerWidget {
  const _Body(this.track);

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final c = context.mercury;
    final playlists = ref.watch(youTubePlaylistsProvider).value ?? const [];
    final containing =
        ref.watch(youTubePlaylistsWithVideoProvider(track.uri)).value ??
        const <String>{};
    final busy = ref.watch(youTubeSaveProvider.select((s) => s.inFlight));
    final liked =
        ref.watch(youTubeLikedVideoIdsProvider).value?.contains(track.uri) ??
        false;

    Future<void> toggle(String playlistId, {required bool contains}) async {
      final ctrl = ref.read(youTubeSaveProvider.notifier);
      final outcome = contains
          ? await ctrl.removeFrom(playlistId, track)
          : await ctrl.addTo(playlistId, track);
      if (outcome.result == SaveResult.failed && context.mounted) {
        showToast(context, outcome.message!);
      }
    }

    Widget row({
      required Widget leading,
      required String title,
      required VoidCallback? onTap,
      String? subtitle,
    }) => InkWell(
      onTap: onTap,
      borderRadius: MercuryRadii.mdAll,
      hoverColor: c.hover,
      focusColor: c.selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MercurySpacing.sm,
          vertical: MercurySpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox.square(dimension: 20, child: Center(child: leading)),
            const SizedBox(width: MercurySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium,
                  ),
                  if (subtitle != null) Text(subtitle, style: t.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    Widget entry({
      required String id,
      required String title,
      required String subtitle,
      required bool contains,
    }) {
      final working = busy.contains('$id/${track.uri}');
      return row(
        leading: working
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                contains
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: contains ? c.textPrimary : c.textSecondary,
              ),
        title: title,
        subtitle: subtitle,
        onTap: working ? null : () => unawaited(toggle(id, contains: contains)),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Save to playlist', style: t.titleMedium),
        const SizedBox(height: MercurySpacing.sm),
        Text(
          'Changes go straight to your YouTube account.',
          style: t.bodySmall,
        ),
        const SizedBox(height: MercurySpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView(
            shrinkWrap: true,
            children: [
              entry(
                id: likedVideosId,
                title: 'Liked music',
                subtitle: 'Likes the song on YouTube',
                contains: liked,
              ),
              for (final p in playlists)
                entry(
                  id: p.id,
                  title: p.title,
                  subtitle: p.trackCount == 1
                      ? '1 song'
                      : '${p.trackCount} songs',
                  contains: containing.contains(p.id),
                ),
            ],
          ),
        ),
        row(
          leading: Icon(Icons.add_rounded, size: 20, color: c.textSecondary),
          title: 'New playlist…',
          subtitle: 'Private',
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: MercurySpacing.lg),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: c.textSecondary),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

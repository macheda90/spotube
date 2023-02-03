import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/components/shared/shimmers/shimmer_lyrics.dart';
import 'package:spotube/hooks/use_breakpoints.dart';
import 'package:spotube/provider/playlist_queue_provider.dart';

import 'package:spotube/provider/user_preferences_provider.dart';
import 'package:spotube/services/queries/queries.dart';
import 'package:spotube/utils/type_conversion_utils.dart';
import 'package:tuple/tuple.dart';

class GeniusLyrics extends HookConsumerWidget {
  final PaletteColor palette;
  final bool? isModal;
  const GeniusLyrics({
    required this.palette,
    this.isModal,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final playlist = ref.watch(PlaylistQueueNotifier.provider);
    final geniusLyricsQuery = useQuery(
      job: Queries.lyrics.static(playlist?.activeTrack.id ?? ""),
      externalData: Tuple2(
        playlist?.activeTrack,
        ref.watch(userPreferencesProvider).geniusAccessToken,
      ),
    );
    final breakpoint = useBreakpoints();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isModal != true) ...[
          Center(
            child: Text(
              playlist?.activeTrack.name ?? "",
              style: breakpoint >= Breakpoints.md
                  ? textTheme.headline3
                  : textTheme.headline4?.copyWith(
                      fontSize: 25,
                      color: palette.titleTextColor,
                    ),
            ),
          ),
          Center(
            child: Text(
              TypeConversionUtils.artists_X_String<Artist>(
                  playlist?.activeTrack.artists ?? []),
              style: (breakpoint >= Breakpoints.md
                      ? textTheme.headline5
                      : textTheme.headline6)
                  ?.copyWith(color: palette.bodyTextColor),
            ),
          )
        ],
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(
                  builder: (context) {
                    if (geniusLyricsQuery.isLoading ||
                        geniusLyricsQuery.isRefetching) {
                      return const ShimmerLyrics();
                    } else if (geniusLyricsQuery.hasError) {
                      return Text(
                        "Sorry, no Lyrics were found for `${playlist?.activeTrack.name}` :'(\n${geniusLyricsQuery.error.toString()}",
                        style: textTheme.bodyText1?.copyWith(
                          color: palette.bodyTextColor,
                        ),
                      );
                    }

                    final lyrics = geniusLyricsQuery.data;

                    return Text(
                      lyrics == null && playlist?.activeTrack == null
                          ? "No Track being played currently"
                          : lyrics ?? "",
                      style:
                          TextStyle(color: palette.bodyTextColor, fontSize: 18),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Powered by genius.com"),
          ),
        )
      ],
    );
  }
}
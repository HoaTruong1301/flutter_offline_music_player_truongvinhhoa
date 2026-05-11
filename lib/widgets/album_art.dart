import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../utils/constants.dart';

class AlbumArt extends StatelessWidget {
  final String songId;
  final double size;
  final double borderRadius;

  const AlbumArt({
    super.key,
    required this.songId,
    this.size = 50,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(
      id: int.parse(songId),
      type: ArtworkType.AUDIO,
      artworkWidth: size,
      artworkHeight: size,
      artworkBorder: BorderRadius.circular(borderRadius),
      keepOldArtwork: true,
    );
  }
}

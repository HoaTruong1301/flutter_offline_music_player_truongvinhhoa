import 'package:just_audio/just_audio.dart';

class PlaybackStateModel {
  final PlayerState playerState;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;
  final LoopMode loopMode;
  final bool shuffleModeEnabled;

  PlaybackStateModel({
    required this.playerState,
    required this.position,
    required this.bufferedPosition,
    this.duration,
    required this.loopMode,
    required this.shuffleModeEnabled,
  });
}

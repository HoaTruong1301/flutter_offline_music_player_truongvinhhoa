import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'audio_handler.dart';

class AudioPlayerService {
  late MyAudioHandler _handler;

  // Khởi tạo service với handler từ audio_service
  void init(MyAudioHandler handler) {
    _handler = handler;
  }

  // Streams lấy từ player của handler
  Stream<Duration> get positionStream => _handler.player.positionStream;
  Stream<Duration?> get durationStream => _handler.player.durationStream;
  Stream<Duration> get bufferedPositionStream => _handler.player.bufferedPositionStream;
  Stream<PlayerState> get playerStateStream => _handler.player.playerStateStream;
  Stream<bool> get playingStream => _handler.player.playingStream;
  Stream<LoopMode> get loopModeStream => _handler.player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _handler.player.shuffleModeEnabledStream;

  // Getters
  Duration get currentPosition => _handler.player.position;
  bool get isPlaying => _handler.player.playing;

  // Stream tổng hợp cho UI
  Stream<PlaybackStateModel> get playbackStateStream {
    return Rx.combineLatest3<Duration, Duration?, bool, PlaybackStateModel>(
      positionStream,
      durationStream,
      playingStream,
      (position, duration, isPlaying) => PlaybackStateModel(
        position: position,
        duration: duration ?? Duration.zero,
        isPlaying: isPlaying,
      ),
    );
  }

  Future<void> loadAudio(String filePath, {MediaItem? item}) async {
    if (item != null) {
      await _handler.updateMediaItem(item);
    } else {
       if (filePath.startsWith('asset:')) {
        await _handler.player.setAsset(filePath.replaceFirst('asset:', ''));
      } else {
        await _handler.player.setFilePath(filePath);
      }
    }
  }

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> stop() => _handler.stop();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> setVolume(double volume) => _handler.player.setVolume(volume);
  Future<void> setLoopMode(LoopMode mode) => _handler.player.setLoopMode(mode);
  Future<void> setShuffleModeEnabled(bool enabled) => _handler.player.setShuffleModeEnabled(enabled);

  void dispose() {
    // Handler do hệ thống quản lý
  }
}

class PlaybackStateModel {
  final Duration position;
  final Duration duration;
  final bool isPlaying;

  PlaybackStateModel({
    required this.position,
    required this.duration,
    required this.isPlaying,
  });

  double get progress {
    if (duration.inMilliseconds > 0) {
      return position.inMilliseconds / duration.inMilliseconds;
    }
    return 0.0;
  }
}

// lib/providers/audio_provider.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayerService _audioService;
  final StorageService _storageService;

  List<SongModel> _playlist = [];
  int _currentIndex = 0;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  AudioProvider(this._audioService, this._storageService) {
    _init();
  }

  // Getters
  List<SongModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  SongModel? get currentSong => _playlist.isEmpty ? null : _playlist[_currentIndex];
  bool get isShuffleEnabled => _isShuffleEnabled;
  LoopMode get loopMode => _loopMode;

  Stream<Duration> get positionStream => _audioService.positionStream;
  Stream<Duration?> get durationStream => _audioService.durationStream;
  Stream<Duration> get bufferedPositionStream => _audioService.bufferedPositionStream;
  Stream<bool> get playingStream => _audioService.playingStream;
  Stream<PlaybackState> get playbackStateStream => _audioService.playbackStateStream;
  Stream<PlayerState> get playerStateStream => _audioService.playerStateStream;
  Stream<LoopMode> get loopModeStream => _audioService.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _audioService.shuffleModeEnabledStream;

  // Initialize
  Future<void> _init() async {
    _isShuffleEnabled = await _storageService.getShuffleState();
    final repeatMode = await _storageService.getRepeatMode();
    _loopMode = LoopMode.values[repeatMode];
    await _audioService.setLoopMode(_loopMode);

    final volume = await _storageService.getVolume();
    await _audioService.setVolume(volume);
  }

  // Set playlist
  Future<void> setPlaylist(List<SongModel> songs, int startIndex) async {
    _playlist = songs;
    _currentIndex = startIndex;
    await _playSongAtIndex(_currentIndex);
    notifyListeners();
  }

  // Play song at index
  Future<void> _playSongAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    final song = _playlist[index];

    await _audioService.loadAudio(song.filePath);
    await _audioService.play();
    
    // Persistence
    await _storageService.saveLastPlayed(song.id);
    await _storageService.saveRecentlyPlayed(song.id);

    notifyListeners();
  }

  // Play/Pause
  Future<void> playPause() async {
    if (_audioService.isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.play();
    }
    notifyListeners();
  }

  // Pause
  Future<void> pause() async {
    try {
      await _audioService.pause();
      notifyListeners();
    } catch (e) {
      debugPrint("Error pausing audio: $e");
    }
  }

  // Next song
  Future<void> next() async {
    if (_isShuffleEnabled) {
      _currentIndex = _getRandomIndex();
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }
    await _playSongAtIndex(_currentIndex);
  }

  // Previous song
  Future<void> previous() async {
    if (_audioService.currentPosition.inSeconds > 3) {
      await _audioService.seek(Duration.zero);
    } else {
      if (_isShuffleEnabled) {
        _currentIndex = _getRandomIndex();
      } else {
        _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      }
      await _playSongAtIndex(_currentIndex);
    }
  }

  // Seek
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  // Toggle shuffle
  Future<void> setShuffleModeEnabled(bool enabled) async {
    await _audioService.setShuffleModeEnabled(enabled);
    _isShuffleEnabled = enabled;
    await _storageService.saveShuffleState(_isShuffleEnabled);
    notifyListeners();
  }

  // Toggle repeat
  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    await _audioService.setLoopMode(_loopMode);
    await _storageService.saveRepeatMode(_loopMode.index);
    notifyListeners();
  }

  // Next song
  Future<void> skipToNext() async {
    await next();
  }

  // Previous song
  Future<void> skipToPrevious() async {
    await previous();
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    await _audioService.setVolume(volume);
    await _storageService.saveVolume(volume);
    notifyListeners();
  }

  // Get random index
  int _getRandomIndex() {
    final random = DateTime.now().millisecondsSinceEpoch % _playlist.length;
    return random;
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}

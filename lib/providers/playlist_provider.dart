import 'package:flutter/foundation.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/playlist_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistService _playlistService;
  List<PlaylistModel> _playlists = [];
  List<SongModel> _recentSongs = [];
  List<SongModel> _allSongs = [];
  bool _isLoading = false;

  List<PlaylistModel> get playlists => _playlists;
  List<SongModel> get recentSongs => _recentSongs;
  List<SongModel> get allSongs => _allSongs;
  bool get isLoading => _isLoading;

  PlaylistProvider(this._playlistService) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    await loadAllSongs();
    await loadPlaylists();
    await loadRecentSongs();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllSongs() async {
    final result = await _playlistService.getAllSongs();
    _allSongs = List<SongModel>.from(result);
    notifyListeners();
  }

  Future<void> loadPlaylists() async {
    final result = await _playlistService.getPlaylists();
    _playlists = List<PlaylistModel>.from(result);
    notifyListeners();
  }

  Future<void> loadRecentSongs() async {
    final result = await _playlistService.getRecentlyPlayedSongs();
    _recentSongs = List<SongModel>.from(result);
    notifyListeners();
  }

  Future<void> addToRecent(SongModel song) async {
    await _playlistService.addToRecentlyPlayed(song.id);
    await loadRecentSongs();
  }

  Future<void> createPlaylist(String name) async {
    final now = DateTime.now();
    final newPlaylist = PlaylistModel(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      songIds: [],
      createdAt: now,
      updatedAt: now,
    );
    _playlists.add(newPlaylist);
    await _playlistService.savePlaylists(_playlists);
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1 && !_playlists[index].songIds.contains(songId)) {
      final updatedPlaylist = _playlists[index].copyWith(
        songIds: [..._playlists[index].songIds, songId],
      );
      _playlists[index] = updatedPlaylist;
      await _playlistService.savePlaylists(_playlists);
      notifyListeners();
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final updatedSongIds = List<String>.from(_playlists[index].songIds)..remove(songId);
      final updatedPlaylist = _playlists[index].copyWith(
        songIds: updatedSongIds,
      );
      _playlists[index] = updatedPlaylist;
      await _playlistService.savePlaylists(_playlists);
      notifyListeners();
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _playlistService.savePlaylists(_playlists);
    notifyListeners();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(name: newName);
      await _playlistService.savePlaylists(_playlists);
      notifyListeners();
    }
  }
}

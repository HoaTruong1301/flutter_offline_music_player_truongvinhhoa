import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio_query;
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import 'storage_service.dart';

class PlaylistService {
  final audio_query.OnAudioQuery _audioQuery = audio_query.OnAudioQuery();
  final StorageService _storageService;

  PlaylistService(this._storageService);

  Future<List<SongModel>> getAllSongs() async {
    // 1. Thêm nhạc mẫu từ Assets (Luôn có sẵn)
    final List<SongModel> assetSongs = [
      SongModel(
        id: 'asset_khong_buong',
        title: 'Không Buông',
        artist: 'Hangle, Ari',
        album: 'NhacCuaTui',
        filePath: 'asset:assets/audio/sample_songs/Không Buông.mp3',
        duration: const Duration(minutes: 4, seconds: 15),
      ),
      SongModel(
        id: 'asset_1',
        title: 'Beauty And A Beat',
        artist: 'Justin Bieber',
        album: 'Sample Album',
        filePath: 'asset:assets/audio/sample_songs/Beauty And A Beat (Lyric Video).mp3',
        duration: const Duration(minutes: 15, seconds: 21),
      ),
    ];

    try {
      // 2. Lấy nhạc từ thiết bị
      final List<audio_query.SongModel> deviceSongs = await _audioQuery.querySongs(
        sortType: audio_query.SongSortType.TITLE,
        orderType: audio_query.OrderType.ASC_OR_SMALLER,
        uriType: audio_query.UriType.EXTERNAL,
        ignoreCase: true,
      );
      
      List<SongModel> songs = deviceSongs.map((audio) => SongModel.fromAudioQuery(audio)).toList();

      // Gộp cả hai danh sách
      return [...assetSongs, ...songs];
    } catch (e) {
      // Nếu lỗi quét nhạc thiết bị, vẫn trả về nhạc mẫu
      debugPrint('Error loading device songs: $e');
      return assetSongs;
    }
  }

  Future<List<SongModel>> getSongsByArtist(String artist) async {
    final allSongs = await getAllSongs();
    return allSongs.where((song) => song.artist == artist).toList();
  }

  Future<List<SongModel>> getSongsByAlbum(String album) async {
    final allSongs = await getAllSongs();
    return allSongs.where((song) => song.album == album).toList();
  }

  Future<List<SongModel>> searchSongs(String query) async {
    final allSongs = await getAllSongs();
    final lowerQuery = query.toLowerCase();

    return allSongs.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          (song.album?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Future<List<PlaylistModel>> getPlaylists() async {
    final playlists = await _storageService.getPlaylists();
    return List<PlaylistModel>.from(playlists);
  }

  Future<void> savePlaylists(List<PlaylistModel> playlists) async {
    await _storageService.savePlaylists(playlists);
  }

  Future<List<SongModel>> getRecentlyPlayedSongs() async {
    final recentIds = await _storageService.getRecentlyPlayed();
    if (recentIds.isEmpty) return [];

    final allSongs = await getAllSongs();
    final List<SongModel> recentSongs = [];

    for (var id in recentIds) {
      try {
        final song = allSongs.firstWhere((s) => s.id == id);
        recentSongs.add(song);
      } catch (e) {
        // Song might have been deleted
      }
    }
    return recentSongs;
  }

  Future<void> addToRecentlyPlayed(String songId) async {
    await _storageService.saveRecentlyPlayed(songId);
  }
}

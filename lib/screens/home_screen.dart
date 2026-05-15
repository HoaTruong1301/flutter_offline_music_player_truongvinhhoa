import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';
import '../services/playlist_service.dart';
import '../services/permission_service.dart';
import '../providers/audio_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import 'search_screen.dart';
import 'playlist_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PermissionService _permissionService = PermissionService();

  List<SongModel> _songs = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Request permissions using the updated service
    _hasPermission = await _permissionService.requestPermissions();

    if (_hasPermission) {
      await _loadSongs();
      if (mounted) {
        final playlistProvider = context.read<PlaylistProvider>();
        await playlistProvider.loadAllSongs();
        await playlistProvider.loadPlaylists(); 
        
        // Khôi phục phiên làm việc cũ
        final audioProvider = context.read<AudioProvider>();
        if (audioProvider.currentSong == null) {
          await audioProvider.restoreLastSession(_songs);
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSongs() async {
    try {
      final playlistService = context.read<PlaylistService>();
      final songs = await playlistService.getAllSongs();
      if (mounted) {
        setState(() {
          _songs = List<SongModel>.from(songs);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading songs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasPermission
                      ? _buildPermissionDenied()
                      : SingleChildScrollView(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPlaylistsSection(), // Đưa Playlist lên trên cho dễ thấy
                              _buildRecentSection(),
                              _buildAllSongsSection(),
                            ],
                          ),
                        ),
            ),

            // Mini Player
            Consumer<AudioProvider>(
              builder: (context, provider, child) {
                if (provider.currentSong == null) return const SizedBox.shrink();
                return const MiniPlayer();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Music',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, child) {
        if (provider.recentSongs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Recently Played',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: provider.recentSongs.length,
                itemBuilder: (context, index) {
                  final song = provider.recentSongs[index];
                  return GestureDetector(
                    onTap: () {
                      context.read<AudioProvider>().setPlaylist(provider.recentSongs, index);
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: song.albumArt != null
                                ? Image.file(
                                    File(song.albumArt!),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.music_note, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.title,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            song.artist,
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistsSection() {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, child) {
        // Nếu không có playlist nào, hiện một gợi ý nhỏ thay vì để trống
        if (provider.playlists.isEmpty) return const SizedBox.shrink();

        final displayPlaylists = provider.playlists.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.2,
              ),
              itemCount: displayPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = displayPlaylists[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(playlist: playlist),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(2, 0),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.playlist_play, color: Colors.green, size: 30),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            playlist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAllSongsSection() {
    if (_songs.isEmpty) return _buildNoSongs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'All Songs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _songs.length,
          itemBuilder: (context, index) {
            final song = _songs[index];
            return SongTile(
              song: song,
              onTap: () {
                context.read<AudioProvider>().setPlaylist(_songs, index);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Storage Permission Required',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please grant storage permission to access music',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSongs() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No Music Found',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add some music files to your device',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

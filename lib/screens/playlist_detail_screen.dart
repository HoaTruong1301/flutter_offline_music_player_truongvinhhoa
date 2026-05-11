import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/playlist_service.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final PlaylistModel playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      appBar: AppBar(
        title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showRenameDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirm(context),
          ),
        ],
      ),
      body: Consumer2<AudioProvider, PlaylistService>(
        builder: (context, audioProvider, playlistService, child) {
          return FutureBuilder<List<SongModel>>(
            future: playlistService.getAllSongs(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final playlistSongs = snapshot.data!
                  .where((song) => playlist.songIds.contains(song.id))
                  .toList();

              if (playlistSongs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                itemCount: playlistSongs.length,
                itemBuilder: (context, index) {
                  final song = playlistSongs[index];
                  return SongTile(
                    song: song,
                    onTap: () {
                      audioProvider.setPlaylist(playlistSongs, index);
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer2<AudioProvider, PlaylistService>(
        builder: (context, audioProvider, playlistService, child) {
          return FutureBuilder<List<SongModel>>(
            future: playlistService.getAllSongs(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
              
              final playlistSongs = snapshot.data!
                  .where((song) => playlist.songIds.contains(song.id))
                  .toList();
              
              if (playlistSongs.isEmpty) return const SizedBox.shrink();
              
              return FloatingActionButton(
                backgroundColor: const Color(0xFF1DB954),
                onPressed: () => audioProvider.setPlaylist(playlistSongs, 0),
                child: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_outlined, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            'Playlist is empty',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Rename Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1DB954))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<PlaylistProvider>().renamePlaylist(playlist.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename', style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${playlist.name}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<PlaylistProvider>().deletePlaylist(playlist.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to playlists screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

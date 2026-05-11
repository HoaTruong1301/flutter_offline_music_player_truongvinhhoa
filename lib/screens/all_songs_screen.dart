import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';

class AllSongsScreen extends StatelessWidget {
  const AllSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      appBar: AppBar(
        title: const Text('All Songs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer2<PlaylistProvider, AudioProvider>(
        builder: (context, playlistProvider, audioProvider, child) {
          if (playlistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (playlistProvider.allSongs.isEmpty) {
            return const Center(child: Text('No songs found', style: TextStyle(color: Colors.white)));
          }
          return ListView.builder(
            itemCount: playlistProvider.allSongs.length,
            itemBuilder: (context, index) {
              return SongTile(
                song: playlistProvider.allSongs[index],
                onTap: () => audioProvider.setPlaylist(playlistProvider.allSongs, index),
              );
            },
          );
        },
      ),
    );
  }
}

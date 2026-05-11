import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/audio_player_service.dart';
import '../widgets/player_controls.dart';
import '../widgets/progress_bar.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  PaletteGenerator? _palette;
  String? _lastArtPath;
  Timer? _sleepTimer;
  int _remainingMinutes = 0;

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }

  void _startSleepTimer(int minutes, AudioProvider audioProvider) {
    _sleepTimer?.cancel();
    setState(() {
      _remainingMinutes = minutes;
    });

    _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_remainingMinutes > 0) {
        if (mounted) {
          setState(() {
            _remainingMinutes--;
          });
        }
      } else {
        timer.cancel();
        audioProvider.pause(); // Gọi dừng nhạc ngoài setState
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sleep timer finished. Music paused.')),
          );
        }
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Music will stop in $minutes minutes')),
    );
  }

  void _showMoreOptions(BuildContext context, SongModel song, AudioProvider audioProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.white),
              title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
              subtitle: _remainingMinutes > 0 
                  ? Text('Active: $_remainingMinutes mins left', style: const TextStyle(color: Colors.green))
                  : null,
              onTap: () {
                Navigator.pop(context);
                _showSleepTimerDialog(context, audioProvider);
              },
            ),
            if (_remainingMinutes > 0)
              ListTile(
                leading: const Icon(Icons.timer_off, color: Colors.red),
                title: const Text('Cancel Sleep Timer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  _sleepTimer?.cancel();
                  setState(() => _remainingMinutes = 0);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('Song Info', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showSongInfoDialog(context, song);
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (context) => Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) => AlertDialog(
          backgroundColor: const Color(0xFF282828),
          title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Luôn hiện nút tạo mới ở trên cùng
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.green),
                  title: const Text('Create New Playlist', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreatePlaylistDialog(context);
                  },
                ),
                if (playlistProvider.playlists.isNotEmpty) const Divider(color: Colors.grey),
                
                // Danh sách các playlist đã có
                if (playlistProvider.playlists.isNotEmpty)
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlistProvider.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlistProvider.playlists[index];
                        return ListTile(
                          leading: const Icon(Icons.playlist_play, color: Colors.white70),
                          title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            playlistProvider.addSongToPlaylist(playlist.id, song.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added to ${playlist.name}')),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter playlist name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<PlaylistProvider>(context, listen: false).createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, AudioProvider audioProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Set Sleep Timer', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 15, 30, 60].map((mins) => ListTile(
            title: Text('$mins Minutes', style: const TextStyle(color: Colors.white)),
            onTap: () {
              _startSleepTimer(mins, audioProvider);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showSongInfoDialog(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Song Info', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${song.title}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Artist: ${song.artist}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Album: ${song.album}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Duration: ${song.duration}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Format: .mp3', style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    final song = provider.currentSong;

    if (song?.albumArt != null && song?.albumArt != _lastArtPath) {
      _lastArtPath = song!.albumArt;
      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(File(song.albumArt!)),
      );
      if (mounted) {
        setState(() {
          _palette = palette;
        });
      }
    } else if (song?.albumArt == null) {
      if (mounted) {
        setState(() {
          _palette = null;
          _lastArtPath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, provider, child) {
        final song = provider.currentSong;
        if (song?.albumArt != _lastArtPath) {
          _updatePalette();
        }

        if (song == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF191414),
            body: Center(child: Text('No song playing', style: TextStyle(color: Colors.white))),
          );
        }

        final bgColor = _palette?.dominantColor?.color.withValues(alpha: 0.5) ?? const Color(0xFF191414);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bgColor,
                  const Color(0xFF191414),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // App Bar
                  _buildAppBar(context, song, provider),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Album Art
                          _buildAlbumArt(song),

                          const SizedBox(height: 40),

                          // Song Info
                          _buildSongInfo(song),

                          const SizedBox(height: 40),

                          // Progress Bar
                          StreamBuilder<PlaybackState>(
                            stream: provider.playbackStateStream,
                            builder: (context, snapshot) {
                              final state = snapshot.data;
                              return ProgressBar(
                                position: state?.position ?? Duration.zero,
                                duration: state?.duration ?? Duration.zero,
                                onSeek: (position) {
                                  provider.seek(position);
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // Player Controls
                          PlayerControls(provider: provider),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, SongModel song, AudioProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              const Text(
                'PLAYING FROM LIBRARY',
                style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5),
              ),
              if (_remainingMinutes > 0)
                Text(
                  'Timer: $_remainingMinutes min',
                  style: const TextStyle(color: Colors.green, fontSize: 10),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showMoreOptions(context, song, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(SongModel song) {
    return Hero(
      tag: 'albumArt_${song.id}',
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: song.albumArt != null
              ? Image.file(File(song.albumArt!), fit: BoxFit.cover)
              : Container(
                  color: const Color(0xFF282828),
                  child: const Icon(Icons.music_note, size: 100, color: Colors.grey),
                ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(SongModel song) {
    return Column(
      children: [
        Text(
          song.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          song.artist,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

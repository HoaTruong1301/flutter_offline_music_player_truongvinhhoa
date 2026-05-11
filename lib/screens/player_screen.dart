import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/album_art.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final currentSong = audioProvider.currentSong;

    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: Text('No song playing', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing', style: TextStyle(fontSize: 14, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album Art
            Center(
              child: AlbumArt(
                songId: currentSong.id,
                size: 300,
                borderRadius: 12,
              ),
            ),
            const SizedBox(height: 48),
            // Title and Artist
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        currentSong.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Progress Bar
            StreamBuilder<Duration>(
              stream: audioProvider.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: audioProvider.durationStream,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: audioProvider.bufferedPositionStream,
                      builder: (context, snapshot) {
                        final bufferedPosition = snapshot.data ?? Duration.zero;
                        return ProgressBar(
                          progress: position,
                          total: duration,
                          buffered: bufferedPosition,
                          onSeek: audioProvider.seek,
                          progressBarColor: Colors.white,
                          baseBarColor: Colors.white24,
                          bufferedBarColor: Colors.white12,
                          thumbColor: Colors.white,
                          barHeight: 4,
                          thumbRadius: 6,
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StreamBuilder<bool>(
                  stream: audioProvider.shuffleModeEnabledStream,
                  builder: (context, snapshot) {
                    final shuffleEnabled = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: shuffleEnabled ? Theme.of(context).primaryColor : Colors.white,
                      ),
                      onPressed: () => audioProvider.setShuffleModeEnabled(!shuffleEnabled),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 36, color: Colors.white),
                  onPressed: audioProvider.skipToPrevious,
                ),
                StreamBuilder<PlayerState>(
                  stream: audioProvider.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return GestureDetector(
                      onTap: audioProvider.playPause,
                      child: Container(
                        height: 72,
                        width: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          size: 48,
                          color: Colors.black,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 36, color: Colors.white),
                  onPressed: audioProvider.skipToNext,
                ),
                StreamBuilder<LoopMode>(
                  stream: audioProvider.loopModeStream,
                  builder: (context, snapshot) {
                    final loopMode = snapshot.data ?? LoopMode.off;
                    IconData iconData = Icons.repeat;
                    Color color = Colors.white;
                    if (loopMode == LoopMode.one) {
                      iconData = Icons.repeat_one;
                      color = Theme.of(context).primaryColor;
                    } else if (loopMode == LoopMode.all) {
                      iconData = Icons.repeat;
                      color = Theme.of(context).primaryColor;
                    }
                    return IconButton(
                      icon: Icon(iconData, color: color),
                      onPressed: () {
                        if (loopMode == LoopMode.off) {
                          audioProvider.setLoopMode(LoopMode.all);
                        } else if (loopMode == LoopMode.all) {
                          audioProvider.setLoopMode(LoopMode.one);
                        } else {
                          audioProvider.setLoopMode(LoopMode.off);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

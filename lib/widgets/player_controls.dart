import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/audio_provider.dart';

class PlayerControls extends StatelessWidget {
  final AudioProvider provider;

  const PlayerControls({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Secondary controls (shuffle, repeat)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle,
                color: provider.isShuffleEnabled
                    ? const Color(0xFF1DB954)
                    : Colors.grey,
              ),
              onPressed: () => provider.setShuffleModeEnabled(!provider.isShuffleEnabled),
            ),
            const SizedBox(width: 40),
            _buildRepeatButton(),
          ],
        ),

        const SizedBox(height: 20),

        // Main controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
              onPressed: () => provider.previous(),
            ),

            StreamBuilder<bool>(
              stream: provider.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1DB954),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () => provider.playPause(),
                  ),
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
              onPressed: () => provider.next(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeatButton() {
    IconData icon;
    Color color;

    switch (provider.loopMode) {
      case LoopMode.off:
        icon = Icons.repeat;
        color = Colors.grey;
        break;
      case LoopMode.all:
        icon = Icons.repeat;
        color = const Color(0xFF1DB954);
        break;
      case LoopMode.one:
        icon = Icons.repeat_one;
        color = const Color(0xFF1DB954);
        break;
    }

    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () {
        switch (provider.loopMode) {
          case LoopMode.off:
            provider.setLoopMode(LoopMode.all);
            break;
          case LoopMode.all:
            provider.setLoopMode(LoopMode.one);
            break;
          case LoopMode.one:
            provider.setLoopMode(LoopMode.off);
            break;
        }
      },
    );
  }
}

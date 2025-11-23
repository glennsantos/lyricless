import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../../managers/playback_manager.dart';

/// Now playing screen with playback controls
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackManager = ref.watch(playbackManagerProvider);
    final queueManager = ref.watch(queueManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
      ),
      body: StreamBuilder<PlaybackState>(
        stream: playbackManager.stateStream,
        builder: (context, stateSnapshot) {
          final currentFile = playbackManager.currentFile;

          if (currentFile == null) {
            return const Center(
              child: Text('No track playing'),
            );
          }

          return Column(
            children: [
              // Album artwork
              Expanded(
                child: Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: currentFile.albumArtwork != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              currentFile.albumArtwork!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.music_note,
                            size: 100,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                  ),
                ),
              ),

              // Track info
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      currentFile.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentFile.artist,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentFile.album,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Progress bar
              StreamBuilder<PlaybackPosition>(
                stream: playbackManager.positionStream,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? playbackManager.position;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Slider(
                          value: position.progress.clamp(0.0, 1.0),
                          onChanged: (value) {
                            final newPosition = position.duration * value;
                            playbackManager.seek(newPosition);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position.position)),
                            Text(_formatDuration(position.duration)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Playback controls
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 48,
                      onPressed: () {
                        queueManager.skipPrevious();
                        final prevTrack = queueManager.currentTrack;
                        if (prevTrack != null) {
                          playbackManager.play(prevTrack);
                        }
                      },
                    ),
                    StreamBuilder<PlaybackState>(
                      stream: playbackManager.stateStream,
                      builder: (context, snapshot) {
                        final state = snapshot.data ?? playbackManager.state;

                        if (state == PlaybackState.processing) {
                          return const CircularProgressIndicator();
                        }

                        final isPlaying = state == PlaybackState.playing;

                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          ),
                          iconSize: 72,
                          onPressed: () {
                            if (isPlaying) {
                              playbackManager.pause();
                            } else {
                              playbackManager.resume();
                            }
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 48,
                      onPressed: () {
                        queueManager.skipNext();
                        final nextTrack = queueManager.currentTrack;
                        if (nextTrack != null) {
                          playbackManager.play(nextTrack);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Volume control
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: playbackManager.volume,
                        onChanged: (value) {
                          playbackManager.setVolume(value);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

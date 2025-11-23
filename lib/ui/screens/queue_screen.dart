import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../../models/audio_file.dart';

/// Queue screen showing upcoming tracks
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueManager = ref.watch(queueManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              queueManager.clearQueue();
            },
            tooltip: 'Clear queue',
          ),
        ],
      ),
      body: StreamBuilder<List<AudioFile>>(
        stream: queueManager.queueStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final queue = snapshot.data!;
          if (queue.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Queue is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            itemCount: queue.length,
            onReorder: (oldIndex, newIndex) {
              queueManager.reorderQueue(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final file = queue[index];
              final isCurrent = queueManager.currentTrack?.id == file.id;

              return ListTile(
                key: ValueKey(file.id),
                leading: isCurrent
                    ? const Icon(Icons.play_circle_filled, color: Colors.green)
                    : Text('${index + 1}'),
                title: Text(
                  file.title,
                  style: isCurrent
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null,
                ),
                subtitle: Text('${file.artist} • ${file.album}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    queueManager.removeFromQueue(index);
                  },
                ),
                onTap: () {
                  queueManager.jumpToTrack(index);
                  final playbackManager = ref.read(playbackManagerProvider);
                  playbackManager.play(file);
                },
              );
            },
          );
        },
      ),
    );
  }
}

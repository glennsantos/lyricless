import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../../models/audio_file.dart';

/// Library screen showing imported audio files
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final libraryManager = ref.watch(libraryManagerProvider);
    final queueManager = ref.watch(queueManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _AudioFileSearchDelegate(libraryManager),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AudioFile>>(
        stream: libraryManager.libraryStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return FutureBuilder<List<AudioFile>>(
              future: libraryManager.getAllFiles(),
              builder: (context, futureSnapshot) {
                if (!futureSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final files = futureSnapshot.data!;
                if (files.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildFileList(files, queueManager);
              },
            );
          }

          final files = snapshot.data!;
          if (files.isEmpty) {
            return _buildEmptyState();
          }

          return _buildFileList(files, queueManager);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _importFiles(libraryManager),
        icon: const Icon(Icons.add),
        label: const Text('Import'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No music in library',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the import button to add music',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(List<AudioFile> files, dynamic queueManager) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return ListTile(
          leading: file.albumArtwork != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    file.albumArtwork!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
          title: Text(file.title),
          subtitle: Text('${file.artist} • ${file.album}'),
          trailing: file.isDRMProtected
              ? const Icon(Icons.lock, color: Colors.orange)
              : IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showFileOptions(file),
                ),
          onTap: () {
            queueManager.clearQueue();
            queueManager.enqueue(file);
            _playFile(file);
          },
        );
      },
    );
  }

  Future<void> _importFiles(dynamic libraryManager) async {
    try {
      final files = await libraryManager.importFiles();

      if (!mounted) return;

      if (files.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${files.length} file(s)'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _playFile(AudioFile file) {
    final playbackManager = ref.read(playbackManagerProvider);
    playbackManager.play(file);
  }

  void _showFileOptions(AudioFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Play'),
                onTap: () {
                  Navigator.pop(context);
                  _playFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music),
                title: const Text('Add to queue'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(queueManagerProvider).enqueue(file);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to queue')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove from library'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(libraryManagerProvider).removeFile(file.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AudioFileSearchDelegate extends SearchDelegate<AudioFile?> {
  final dynamic libraryManager;

  _AudioFileSearchDelegate(this.libraryManager);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<AudioFile>>(
      future: libraryManager.searchFiles(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final files = snapshot.data!;
        if (files.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return ListTile(
              leading: const Icon(Icons.music_note),
              title: Text(file.title),
              subtitle: Text('${file.artist} • ${file.album}'),
              onTap: () {
                close(context, file);
              },
            );
          },
        );
      },
    );
  }
}

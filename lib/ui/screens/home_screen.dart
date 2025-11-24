import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../widgets/initialization_status_widget.dart';
import 'library_screen.dart';
import 'now_playing_screen.dart';
import 'queue_screen.dart';
import 'settings_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LibraryScreen(),
    QueueScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final initNotifier = ref.watch(initializationNotifierProvider);
    final hasErrors = initNotifier.hasErrors;
    final isInitializing = !initNotifier.isInitialized;
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Initialization overlay
          if (isInitializing || hasErrors)
            const InitializationStatusWidget(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 || hasErrors)
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NowPlayingScreen(),
                  ),
                );
              },
              child: const Icon(Icons.music_note),
            ),
    );
  }
}

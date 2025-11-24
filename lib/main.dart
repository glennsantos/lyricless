import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/home_screen.dart';
import 'managers/library_manager_impl.dart';
import 'managers/python_audio_processor.dart';
import 'managers/cache_manager_impl.dart';
import 'managers/queue_manager_impl.dart';
import 'managers/playback_manager_impl.dart';
import 'services/battery_service.dart';

// Global providers
final libraryManagerProvider = Provider((ref) => LibraryManagerImpl());

final cacheManagerProvider = Provider((ref) => CacheManagerImpl());

final audioProcessorProvider = Provider((ref) => PythonAudioProcessor());

final queueManagerProvider = Provider((ref) {
  final audioProcessor = ref.watch(audioProcessorProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return QueueManagerImpl(
    audioProcessor: audioProcessor,
    cacheManager: cacheManager,
  );
});

final playbackManagerProvider = Provider((ref) {
  final audioProcessor = ref.watch(audioProcessorProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return PlaybackManagerImpl(
    audioProcessor: audioProcessor,
    cacheManager: cacheManager,
  );
});

final batteryServiceProvider = Provider((ref) => BatteryService());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: LyriclessApp()));
}

class LyriclessApp extends ConsumerStatefulWidget {
  const LyriclessApp({super.key});

  @override
  ConsumerState<LyriclessApp> createState() => _LyriclessAppState();
}

class _LyriclessAppState extends ConsumerState<LyriclessApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize core services
      final libraryManager = ref.read(libraryManagerProvider);
      await libraryManager.initialize();

      final cacheManager = ref.read(cacheManagerProvider);
      await cacheManager.initialize();

      final audioProcessor = ref.read(audioProcessorProvider);
      await audioProcessor.initialize();

      final playbackManager = ref.read(playbackManagerProvider);
      await playbackManager.initialize();

      final batteryService = ref.read(batteryServiceProvider);
      await batteryService.initialize();
    } catch (e) {
      debugPrint('Failed to initialize app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyricless',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

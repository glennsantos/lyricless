import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/home_screen.dart';
import 'managers/library_manager_impl.dart';
import 'managers/python_audio_processor.dart';
import 'managers/cache_manager_impl.dart';
import 'managers/queue_manager_impl.dart';
import 'managers/playback_manager_impl.dart';
import 'services/battery_service.dart';
import 'models/initialization_state.dart';

// Global providers
final initializationNotifierProvider = ChangeNotifierProvider((ref) => AppInitializationNotifier());

final libraryManagerProvider = Provider((ref) => LibraryManagerImpl());

final cacheManagerProvider = Provider((ref) => CacheManagerImpl());

import 'managers/http_audio_processor.dart';

final audioProcessorProvider = Provider<AudioProcessor>((ref) => HttpAudioProcessor());

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
    final initNotifier = ref.read(initializationNotifierProvider);

    // Initialize library manager
    await _initializeService(
      initNotifier: initNotifier,
      serviceName: 'Library',
      initializer: () => ref.read(libraryManagerProvider).initialize(),
    );

    // Initialize cache manager
    await _initializeService(
      initNotifier: initNotifier,
      serviceName: 'Cache',
      initializer: () => ref.read(cacheManagerProvider).initialize(),
    );

    // Initialize audio processor (critical - may fail)
    await _initializeService(
      initNotifier: initNotifier,
      serviceName: 'Audio Processor',
      initializer: () => ref.read(audioProcessorProvider).initialize(),
    );

    // Initialize playback manager
    await _initializeService(
      initNotifier: initNotifier,
      serviceName: 'Playback',
      initializer: () => ref.read(playbackManagerProvider).initialize(),
    );

    // Initialize battery service
    await _initializeService(
      initNotifier: initNotifier,
      serviceName: 'Battery Monitor',
      initializer: () => ref.read(batteryServiceProvider).initialize(),
    );

    initNotifier.setInitialized();
  }

  Future<void> _initializeService({
    required AppInitializationNotifier initNotifier,
    required String serviceName,
    required Future<dynamic> Function() initializer,
  }) async {
    initNotifier.updateService(
      InitializationState(
        serviceName: serviceName,
        status: InitializationStatus.inProgress,
        message: 'Initializing $serviceName...',
      ),
    );

    try {
      await initializer();
      initNotifier.updateService(
        InitializationState(
          serviceName: serviceName,
          status: InitializationStatus.success,
          message: '$serviceName ready',
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize $serviceName: $e\n$stackTrace');
      initNotifier.updateService(
        InitializationState(
          serviceName: serviceName,
          status: InitializationStatus.failed,
          message: e.toString(),
          error: e,
        ),
      );
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

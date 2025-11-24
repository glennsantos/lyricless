import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../../models/initialization_state.dart';

/// Widget that displays initialization status and errors
class InitializationStatusWidget extends ConsumerWidget {
  const InitializationStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initNotifier = ref.watch(initializationNotifierProvider);
    
    if (!initNotifier.isInitialized) {
      // Still initializing - show progress
      return _buildLoadingView(initNotifier);
    }
    
    if (initNotifier.hasErrors) {
      // Initialization complete but has errors - show error view
      return _buildErrorView(context, ref, initNotifier);
    }
    
    // All good - don't show anything
    return const SizedBox.shrink();
  }

  Widget _buildLoadingView(AppInitializationNotifier initNotifier) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Initializing Lyricless...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...initNotifier.services.values.map((state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getStatusIcon(state.status),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          state.message ?? state.serviceName,
                          style: TextStyle(
                            color: state.isFailed
                                ? Colors.red
                                : state.isSuccess
                                    ? Colors.green
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    AppInitializationNotifier initNotifier,
  ) {
    final failedServices = initNotifier.failedServices;
    
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Initialization Failed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'The following services failed to initialize:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...failedServices.map((state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            state.serviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (state.message != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 28, top: 4),
                          child: Text(
                            state.message!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer
                                  .withOpacity(0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              _buildTroubleshootingHelp(context, failedServices),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _retryInitialization(ref),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Initialization'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTroubleshootingHelp(
    BuildContext context,
    List<InitializationState> failedServices,
  ) {
    // Check if Audio Processor failed
    final audioProcessorFailed = failedServices.any(
      (s) => s.serviceName == 'Audio Processor',
    );

    if (audioProcessorFailed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Troubleshooting Tips',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '• Ensure Python 3.x is installed',
              style: TextStyle(fontSize: 13),
            ),
            const Text(
              '• Verify Spleeter is installed: pip install spleeter',
              style: TextStyle(fontSize: 13),
            ),
            const Text(
              '• Check the Python path in python_audio_processor.dart',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _getStatusIcon(InitializationStatus status) {
    switch (status) {
      case InitializationStatus.notStarted:
        return const Icon(Icons.circle_outlined, size: 16);
      case InitializationStatus.inProgress:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case InitializationStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      case InitializationStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 16);
    }
  }

  void _retryInitialization(WidgetRef ref) {
    final initNotifier = ref.read(initializationNotifierProvider);
    initNotifier.reset();
    
    // Get the app state and trigger re-initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Access the _LyriclessAppState through the widget tree
      final context = ref.context;
      final appState = context.findAncestorStateOfType<_LyriclessAppState>();
      appState?._initializeApp();
    });
  }
}

/// Extension to expose retry initialization globally
extension RetryInitialization on WidgetRef {
  void retryInitialization() {
    final context = this.context;
    final appState = context.findAncestorStateOfType<_LyriclessAppState>();
    
    if (appState != null) {
      final initNotifier = read(initializationNotifierProvider);
      initNotifier.reset();
      appState._initializeApp();
    }
  }
}

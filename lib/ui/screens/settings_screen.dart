import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _cacheSize = 0;
  bool _isLoadingCacheSize = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    setState(() => _isLoadingCacheSize = true);

    try {
      final cacheManager = ref.read(cacheManagerProvider);
      final size = await cacheManager.getCacheSize();
      setState(() {
        _cacheSize = size;
        _isLoadingCacheSize = false;
      });
    } catch (e) {
      setState(() => _isLoadingCacheSize = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final batteryService = ref.watch(batteryServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Cache section
          _buildSectionHeader('Storage'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Cache size'),
            subtitle: _isLoadingCacheSize
                ? const Text('Calculating...')
                : Text(_formatBytes(_cacheSize)),
            trailing: TextButton(
              onPressed: _clearCache,
              child: const Text('Clear'),
            ),
          ),

          const Divider(),

          // Battery section (mobile only)
          if (!kIsWeb) ...[
            _buildSectionHeader('Battery'),
            StreamBuilder<bool>(
              stream: batteryService.batterySaverStream,
              builder: (context, snapshot) {
                final isEnabled = snapshot.data ?? batteryService.isBatterySaverEnabled;

                return SwitchListTile(
                  secondary: const Icon(Icons.battery_saver),
                  title: const Text('Battery Saver'),
                  subtitle: const Text(
                    'Disables look-ahead processing when battery is low',
                  ),
                  value: isEnabled,
                  onChanged: (value) {
                    batteryService.setBatterySaverEnabled(value);
                  },
                );
              },
            ),
            StreamBuilder<int>(
              stream: batteryService.batteryLevelStream,
              builder: (context, snapshot) {
                final level = snapshot.data ?? batteryService.batteryLevel;

                return ListTile(
                  leading: const Icon(Icons.battery_std),
                  title: const Text('Battery level'),
                  subtitle: Text('$level%'),
                );
              },
            ),
            const Divider(),
          ],

          // About section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Open source licenses'),
            onTap: () {
              showLicensePage(context: context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear cache'),
          content: const Text(
            'This will delete all processed audio files. '
            'They will need to be processed again when played.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final cacheManager = ref.read(cacheManagerProvider);
      await cacheManager.clearCache();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared')),
      );

      _loadCacheSize();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cache: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

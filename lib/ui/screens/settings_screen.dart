import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String _apiUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _loadCacheSize();
    _loadApiUrl();
  }

  Future<void> _loadApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiUrl = prefs.getString('vocal_remover_api_url') ?? 'http://127.0.0.1:8000';
    });
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

          // Server Configuration
          _buildSectionHeader('Server Configuration'),
          ListTile(
            leading: const Icon(Icons.cloud_queue),
            title: const Text('API Server URL'),
            subtitle: Text(_apiUrl),
            onTap: _editApiUrl,
          ),
          const Divider(),

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

  Future<void> _editApiUrl() async {
    final controller = TextEditingController(text: _apiUrl);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit API URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the URL of your Python server.\n'
                'For local network, use http://YOUR_IP:8000',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  border: OutlineInputBorder(),
                  hintText: 'http://192.168.1.x:8000',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final newUrl = controller.text.trim();
      if (newUrl.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('vocal_remover_api_url', newUrl);
        setState(() => _apiUrl = newUrl);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('URL saved. Please restart the app to apply.')),
          );
        }
      }
    }
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

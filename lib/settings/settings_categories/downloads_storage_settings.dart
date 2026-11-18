import 'package:flutter/material.dart';
import '../settings_service.dart';

class DownloadsStorageSettingsScreen extends StatelessWidget {
  const DownloadsStorageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads & Storage')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Download Location'),
            subtitle: const Text('Default download location'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Download Quality'),
            subtitle: const Text('Audio quality for downloads'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Storage Usage'),
            subtitle: const Text('Current storage usage'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Cache Management'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Clear Cache'),
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            onTap: () => SettingsService.clearCache(),
          ),
          ListTile(
            title: const Text('Offline Music Information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Storage Diagnostics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
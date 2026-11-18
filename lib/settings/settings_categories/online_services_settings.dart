import 'package:flutter/material.dart';

class OnlineServicesSettingsScreen extends StatelessWidget {
  const OnlineServicesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Online Services & Integrations')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('API Connection Status'),
            subtitle: const Text('Connected'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          ListTile(
            title: const Text('Connected Services'),
            subtitle: const Text('YouTube Music, Spotify'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Account Information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Integration Diagnostics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class PrivacySecuritySettingsScreen extends StatelessWidget {
  const PrivacySecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Privacy Information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Permissions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Data Management'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Clear App Cache'),
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Reset Application Preferences'),
            leading: const Icon(Icons.restore, color: Colors.red),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
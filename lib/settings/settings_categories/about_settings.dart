import 'package:flutter/material.dart';
import '../settings_service.dart';

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});

  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  Map<String, dynamic> _appInfo = {};

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await SettingsService.getAppInfo();
    setState(() => _appInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About AuraBeat')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('App Name'),
            subtitle: Text(_appInfo['name'] as String? ?? 'AuraBeat'),
          ),
          ListTile(
            title: const Text('App Version'),
            subtitle: Text(_appInfo['version'] as String? ?? '1.0.0'),
          ),
          ListTile(
            title: const Text('Build Number'),
            subtitle: Text(_appInfo['buildNumber'] as String? ?? '1'),
          ),
          ListTile(
            title: const Text('Developer Information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Open Source Licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Terms and Conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Contact Information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
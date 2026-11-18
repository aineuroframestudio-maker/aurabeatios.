import 'package:flutter/material.dart';
import '../settings_service.dart';

class Sony360SettingsScreen extends StatefulWidget {
  const Sony360SettingsScreen({super.key});

  @override
  State<Sony360SettingsScreen> createState() => _Sony360SettingsScreenState();
}

class _Sony360SettingsScreenState extends State<Sony360SettingsScreen> {
  Map<String, dynamic> _sonyInfo = {};

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await SettingsService.getDolbyAtmosInfo();
    setState(() => _sonyInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sony 360 Reality Audio')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Feature Availability'),
            subtitle: Text(_sonyInfo['sony360'] as String? ?? 'Supported'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          ListTile(
            title: const Text('Compatibility'),
            subtitle: Text(_sonyInfo['compatibility'] as String? ?? 'ATRAC-Spatial'),
          ),
          ListTile(
            title: const Text('Supported Formats'),
            subtitle: Text(_sonyInfo['formats'] as String? ?? 'ATRAC-Spatial 44.1/96 kHz'),
          ),
          ListTile(
            title: const Text('Playback Status'),
            subtitle: Text(_sonyInfo['status'] as String? ?? 'Ready'),
          ),
        ],
      ),
    );
  }
}
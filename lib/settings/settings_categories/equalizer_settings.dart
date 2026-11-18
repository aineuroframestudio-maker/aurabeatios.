import 'package:flutter/material.dart';
import '../settings_service.dart';

class EqualizerSettingsScreen extends StatefulWidget {
  const EqualizerSettingsScreen({super.key});

  @override
  State<EqualizerSettingsScreen> createState() => _EqualizerSettingsScreenState();
}

class _EqualizerSettingsScreenState extends State<EqualizerSettingsScreen> {
  bool _eqEnabled = false;
  String _eqPreset = 'Flat';
  // ignore: unused_field
  List<double> _bands = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await SettingsService.getEqEnabled();
    final preset = await SettingsService.getEqPreset();
    final bands = await SettingsService.getEqBands();

    setState(() {
      _eqEnabled = enabled;
      _eqPreset = preset;
      _bands = bands;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equalizer & Audio Effects')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Equalizer'),
            value: _eqEnabled,
            onChanged: (val) async {
              await SettingsService.setEqEnabled(val);
              setState(() => _eqEnabled = val);
            },
          ),
          ListTile(
            title: const Text('Preset'),
            subtitle: Text(_eqPreset),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPresetDialog(context),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Bass Enhancement', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          SwitchListTile(
            title: const Text('Bass Boost'),
            value: false,
            onChanged: (val) async {
              await SettingsService.setBassBoost(val);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Balance Control', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Slider(
            value: 0.0,
            min: -1.0,
            max: 1.0,
            label: 'Balance',
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }

  void _showPresetDialog(BuildContext context) {
    final presets = ['Flat', 'Bass Boost', 'Treble Boost', 'Jazz', 'Rock', 'Pop', 'Electronic'];
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Preset'),
        content: Column(
          children: presets.map((preset) => ListTile(
            title: Text(preset),
            onTap: () async {
              await SettingsService.setEqPreset(preset);
              if (!mounted) return;
              setState(() => _eqPreset = preset);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
          )).toList(),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../settings_service.dart';

class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('General Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Appearance'),
            subtitle: const Text('Dark / Light / System theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('App language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            title: const Text('Default Startup Screen'),
            subtitle: const Text('Choose default screen'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('App Behavior'),
            subtitle: const Text('General app behavior settings'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('Reset Preferences'),
            subtitle: const Text('Reset all settings to default'),
            trailing: const Icon(Icons.restore, color: Colors.red),
            onTap: () => _showResetDialog(context),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appearance'),
        content: Column(
          children: [
            RadioListTile(
              value: 'light',
              groupValue: 'system',
              title: const Text('Light'),
              onChanged: (val) => SettingsService.setThemeMode('light'),
            ),
            RadioListTile(
              value: 'dark',
              groupValue: 'system',
              title: const Text('Dark'),
              onChanged: (val) => SettingsService.setThemeMode('dark'),
            ),
            RadioListTile(
              value: 'system',
              groupValue: 'system',
              title: const Text('System Default'),
              onChanged: (val) => SettingsService.setThemeMode('system'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language'),
        content: Column(
          children: [
            RadioListTile(
              value: 'en',
              groupValue: 'en',
              title: const Text('English'),
              onChanged: (val) => SettingsService.setLanguage('en'),
            ),
            RadioListTile(
              value: 'es',
              groupValue: 'en',
              title: const Text('Spanish'),
              onChanged: (val) => SettingsService.setLanguage('es'),
            ),
            RadioListTile(
              value: 'fr',
              groupValue: 'en',
              title: const Text('French'),
              onChanged: (val) => SettingsService.setLanguage('fr'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Preferences'),
        content: const Text('This will reset all settings to their default values. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SettingsService.resetPreferences();
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
}
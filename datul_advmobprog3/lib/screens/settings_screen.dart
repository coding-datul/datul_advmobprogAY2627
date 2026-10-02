import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Enhancement: Allow users to switch between light and dark themes.
    final themeProvider =
        Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListTile(
        leading: const Icon(Icons.dark_mode),
        title: Text(
          themeProvider.isDark ? 'Dark Mode' : 'Light Mode',
          style: TextStyle(
            color: themeProvider.isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          themeProvider.isDark
              ? 'Enable or disable dark theme'
              : 'Enable or disable light theme',
        ),
        trailing: Switch(
          value: themeProvider.isDark,
          onChanged: (value) {
            themeProvider.toggleTheme(value);
          },
        ),
      ),
    );
  }
}

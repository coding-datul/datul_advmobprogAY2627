import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final userService = UserService();
      try {
        await (userService as dynamic).signOut();
      } catch (_) {}
      await userService.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/signin',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enhancement: Allow users to switch between light and dark themes + Logout in settings -> back to login.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          ListTile(
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
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text(
              'Log Out',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Clear session/token and return to login'),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}

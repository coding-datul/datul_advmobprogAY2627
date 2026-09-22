import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

// Enhancement 3: Add settings page to move the dark/light mode switch.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Settings',
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        children: [
          // Enhancement 3: Add settings page to move the dark/light mode switch.
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: SwitchListTile(
              secondary: Icon(
                themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                size: 24.sp,
              ),
              title: CustomText(
                text: 'Dark Mode',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              subtitle: CustomText(
                text: themeProvider.isDark
                    ? 'Currently using Dark Theme'
                    : 'Currently using Light Theme',
                fontSize: 12.sp,
              ),
              value: themeProvider.isDark,
              onChanged: (bool value) {
                // Enhancement 3: Toggle dark/light mode
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ),
        ],
      ),
    );
  }
}

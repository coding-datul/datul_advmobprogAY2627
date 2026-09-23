import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          text: 'Settings',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // App Settings Section
          const CustomText(
            text: 'PREFERENCES',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.primary,
              ),
              title: const CustomText(
                text: 'Dark Mode',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              subtitle: CustomText(
                text: isDark ? 'Dark theme enabled' : 'Light theme enabled',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              value: isDark,
              activeThumbColor: AppColors.primary,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          SizedBox(height: 24.h),

          // Academic Information Section
          const CustomText(
            text: 'LABORATORY INFORMATION',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Institution', 'National University - CCIT'),
                const Divider(height: 20),
                _buildInfoRow('Course', 'Advanced Mobile Programming'),
                const Divider(height: 20),
                _buildInfoRow('Activity', 'Lab Activity 3: API PART II'),
                const Divider(height: 20),
                _buildInfoRow('API Provider', 'DummyJSON (Products & Carts)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: title,
          fontSize: 13,
          color: AppColors.textMuted,
        ),
        CustomText(
          text: value,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}

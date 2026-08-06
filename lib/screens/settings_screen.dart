import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            CustomText(
              text: 'Appearance',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            SizedBox(height: 8.h),
            // Enhancement 3: dark/light mode switch lives on the Settings
            // page instead of the Home app bar.
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: SwitchListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                secondary: Icon(
                  themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                ),
                title: CustomText(
                  text: 'Dark Mode',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
                subtitle: CustomText(
                  text: themeProvider.isDark
                      ? 'Currently on'
                      : 'Currently off',
                  fontSize: 12.sp,
                ),
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

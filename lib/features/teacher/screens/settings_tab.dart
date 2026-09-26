import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/session_service.dart';
import '../../splash/screens/splash_screen.dart';
import '../../../providers/theme_provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _logout(BuildContext context) async {
    await SessionService.clearSession();
    if (!context.mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 32),
          
          // Dark Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (val) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: const Color(0xFF724F96),
                  );
                },
              ),
              const Spacer(),
              Text(
                'الوضع الداكن',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.dark_mode, color: textColor),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Logout Button
          InkWell(
            onTap: () => _logout(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.logout, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

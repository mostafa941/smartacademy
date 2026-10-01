import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../providers/admin_provider.dart';
import '../screens/admin_login_screen.dart';

class SidebarWidget extends StatelessWidget {
  final AdminProvider provider;

  const SidebarWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.school, color: AppColors.bodyBg, size: 28),
              SizedBox(width: 8),
              Text(
                'Smart Academy',
                style: TextStyle(
                  color: AppColors.bodyBg,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white54, width: 1),
            ),
            child: Column(
              children: [
                Text(
                  provider.adminName.isEmpty ? AppStrings.systemAdmin : provider.adminName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.adminDescription.isEmpty ? AppStrings.mainAdmin : provider.adminDescription,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildNavItem(
            icon: Icons.tune,
            title: AppStrings.controlPanel,
            isSelected: provider.selectedNavIndex == 0,
            onTap: () => provider.setNavIndex(0),
          ),
          _buildNavItem(
            icon: Icons.school_outlined,
            title: AppStrings.students,
            isSelected: provider.selectedNavIndex == 1,
            onTap: () => provider.setNavIndex(1),
          ),
          _buildNavItem(
            icon: Icons.co_present_outlined,
            title: AppStrings.teachers,
            isSelected: provider.selectedNavIndex == 2,
            onTap: () => provider.setNavIndex(2),
          ),
          _buildNavItem(
            icon: Icons.settings_outlined,
            title: AppStrings.settings,
            isSelected: provider.selectedNavIndex == 3,
            onTap: () => provider.setNavIndex(3),
          ),
          _buildNavItem(
            icon: Icons.report_problem_outlined,
            title: AppStrings.complaints,
            isSelected: provider.selectedNavIndex == 4,
            onTap: () => provider.setNavIndex(4),
          ),
          const Spacer(),
          InkWell(
            onTap: () async {
              // حذف بيانات الجلسة
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('admin_email');
              await prefs.remove('admin_password');
              await prefs.setBool('admin_remember_me', false);

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen(),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    AppStrings.logout,
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.activeNavBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.activeNavText : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.activeNavText : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
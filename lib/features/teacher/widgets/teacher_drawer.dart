import 'package:flutter/material.dart';
import '../screens/daily_reports_screen.dart';
import '../screens/weekly_reports_screen.dart';

class TeacherDrawer extends StatelessWidget {
  final String userName;
  final String userId;
  final String? avatarUrl;

  const TeacherDrawer({
    super.key, 
    required this.userName, 
    required this.userId,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header: User Name and Avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A1B38),
                      ),
                    ),
                    const Text(
                      'معلم',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFEEEEEE),
                  backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? const Icon(Icons.face, size: 32, color: Color(0xFF2A1B38))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(indent: 32, endIndent: 32),
            const SizedBox(height: 10),

            // Drawer Items
            _buildDrawerItem(
              title: 'سجل التقييمات اليومية',
              icon: Icons.calendar_today_rounded,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DailyReportsScreen(teacherId: userId),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              title: 'سجل التقييمات الأسبوعية',
              icon: Icons.date_range_rounded,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WeeklyReportsScreen(teacherId: userId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2A1B38),
        ),
      ),
      trailing: Icon(icon, color: const Color(0xFF2A1B38)),
    );
  }
}

import 'package:flutter/material.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';

class DashboardOverviewView extends StatelessWidget {
  final AdminProvider provider;

  const DashboardOverviewView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Align(
        alignment: Alignment.topRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatCard(title: 'إجمالي الطلاب', count: '${provider.totalStudents}'),
            const SizedBox(width: 16),
            StatCard(title: 'المدرسين', count: '${provider.totalTeachers}'),
            const SizedBox(width: 16),
            StatCard(title: 'نسبة الحضور', count: provider.attendancePercentage),
          ],
        ),
      ),
    );
  }
}
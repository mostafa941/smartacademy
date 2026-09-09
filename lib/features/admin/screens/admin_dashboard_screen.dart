import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/admin_provider.dart';
import '../widgets/header.dart';
import '../widgets/sidebar.dart';
import 'dashboard_overview_view.dart';
import 'students_view.dart';
import 'package:smart_academy/views/teachers_view.dart';
import 'package:smart_academy/views/student_detail_view.dart';
import 'package:smart_academy/views/settings_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchDashboardData());
  }

  Widget _buildSelectedScreen(AdminProvider provider) {
    switch (provider.selectedNavIndex) {
      case 0:
        return DashboardOverviewView(provider: provider);
      case 1:
        // التبديل تلقائياً بين قائمة الطلاب وتفاصيل الطالب عند اختياره
        if (provider.selectedStudent != null) {
          return StudentDetailView(provider: provider);
        }
        return StudentsView(provider: provider);
      case 2:
        // التبديل إلى تفاصيل الطالب عند اختياره من داخل صفحة المدرس
        if (provider.selectedStudent != null) {
          return StudentDetailView(provider: provider);
        }
        return TeachersView(provider: provider);
      case 3:
        return SettingsView(provider: provider);
      default:
        return DashboardOverviewView(provider: provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final todayDate = intl.DateFormat('dd-MM-yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.bodyBg,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            SidebarWidget(provider: provider),
            Expanded(
              child: Column(
                children: [
                  HeaderWidget(provider: provider, todayDate: todayDate),
                  Expanded(
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildSelectedScreen(provider),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
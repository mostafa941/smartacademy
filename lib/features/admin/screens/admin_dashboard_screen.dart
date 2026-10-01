import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../providers/admin_provider.dart';
import '../widgets/header.dart';
import '../widgets/sidebar.dart';
import 'dashboard_overview_view.dart';
import 'students_view.dart';
import 'package:smart_academy/views/teachers_view.dart';
import 'package:smart_academy/views/student_detail_view.dart';
import 'package:smart_academy/views/settings_view.dart';
import 'complaints_view.dart';
import '../../../core/widgets/skeleton_loading.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchDashboardData());
  }

  Stream<List<dynamic>> _getUnreadNotificationsStream() {
    return _supabase
        .from('admin_notifications')
        .stream(primaryKey: ['id'])
        .eq('is_read', false)
        .order('created_at', ascending: false);
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabase
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإشعارات', style: TextStyle(fontSize: 18)),
              StreamBuilder<List<dynamic>>(
                stream: _getUnreadNotificationsStream(),
                builder: (context, snapshot) {
                  final hasUnread = snapshot.hasData && snapshot.data!.isNotEmpty;
                  if (hasUnread) {
                    return TextButton(
                      onPressed: () {
                        _markAllAsRead();
                        Navigator.pop(context);
                      },
                      child: const Text('تعليم الكل كمقروء', style: TextStyle(fontSize: 11)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width > 768 ? 450 : double.maxFinite,
            height: MediaQuery.of(context).size.height > 600 ? 350 : MediaQuery.of(context).size.height * 0.5,
            child: StreamBuilder<List<dynamic>>(
              stream: _supabase
                  .from('admin_notifications')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false)
                  .limit(15),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF724F96)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا توجد إشعارات', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data!;
                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif['is_read'] == true;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isRead ? Colors.grey.shade300 : Colors.orange.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: isRead ? Colors.grey : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  notif['title'] ?? 'إشعار',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notif['message'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(notif['created_at']),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inHours < 1) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inDays < 1) {
        return 'منذ ${difference.inHours} ساعة';
      } else {
        return 'منذ ${difference.inDays} يوم';
      }
    } catch (e) {
      return '';
    }
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
      case 4:
        return ComplaintsView(provider: provider);
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 768;
            
            if (isDesktop) {
              // Desktop Layout
              return Row(
                children: [
                  SidebarWidget(provider: provider),
                  Expanded(
                    child: Column(
                      children: [
                        HeaderWidget(provider: provider, todayDate: todayDate),
                        Expanded(
                          child: provider.isLoading
                              ? const SkeletonCardLoading()
                              : _buildSelectedScreen(provider),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Mobile Layout
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: AppColors.sidebarBg,
                  title: Text(
                    _getPageTitle(provider.selectedNavIndex),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    // Notifications Bell for Mobile
                    _buildNotificationBell(context),
                    const SizedBox(width: 8),
                  ],
                ),
                drawer: Drawer(
                  child: SidebarWidget(provider: provider),
                ),
                body: provider.isLoading
                    ? const SkeletonCardLoading()
                    : _buildSelectedScreen(provider),
              );
            }
          },
        ),
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0: return 'لوحة التحكم';
      case 1: return 'الطلاب';
      case 2: return 'المدرسين';
      case 3: return 'الإعدادات';
      case 4: return 'الشكاوى';
      default: return 'لوحة التحكم';
    }
  }

  Widget _buildNotificationBell(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        return StreamBuilder<List<dynamic>>(
          stream: _getUnreadNotificationsStream(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.hasData ? snapshot.data!.length : 0;
            
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 26),
                  color: Colors.white,
                  onPressed: () => _showNotificationsDialog(context),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
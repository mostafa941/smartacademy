import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/admin_provider.dart';
import '../constants/app_strings.dart';

class HeaderWidget extends StatefulWidget {
  final AdminProvider provider;
  final String todayDate;

  const HeaderWidget({
    super.key,
    required this.provider,
    required this.todayDate,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final _supabase = Supabase.instance.client;
  int _unreadNotifications = 0;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _complaintsChannel; // قناة لمتابعة الشكاوى الجديدة

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _setupRealtime();
  }

  @override
  void dispose() {
    _notificationsChannel?.unsubscribe();
    _complaintsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final cutoff24h = DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();

      // عدد الإشعارات غير المقروءة من admin_notifications
      final notifResult = await _supabase
          .from('admin_notifications')
          .select('id')
          .eq('is_read', false);

      // عدد الشكاوى غير المقروءة من complaints (احتياطي، خلال 24 ساعة فقط)
      final complaintResult = await _supabase
          .from('complaints')
          .select('id')
          .eq('is_read', false)
          .gte('created_at', cutoff24h);

      // نأخذ الأكبر من الاثنين (في الغالب admin_notifications هو الصحيح)
      final notifCount = (notifResult as List).length;
      final complaintCount = (complaintResult as List).length;
      final total = notifCount > complaintCount ? notifCount : complaintCount;

      if (mounted) {
        setState(() {
          _unreadNotifications = total;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin notifications: $e');
    }
  }

  void _setupRealtime() {
    // قناة 1: متابعة إشعارات الأدمن
    _notificationsChannel = _supabase
        .channel('admin_notifications_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'admin_notifications',
          callback: (payload) {
            debugPrint('🔔 New admin notification received');
            _fetchUnreadCount();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📩 وصلك إشعار جديد!', textAlign: TextAlign.center),
                  backgroundColor: Color(0xFF724F96),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
        )
        .subscribe();

    // قناة 2: متابعة الشكاوى الجديدة مباشرة
    _complaintsChannel = _supabase
        .channel('complaints_header_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'complaints',
          callback: (payload) async {
            debugPrint('🔔 New complaint received → updating bell');
            _fetchUnreadCount();
          },
        )
        .subscribe();
  }

  String _getTitleByIndex(int index) {
    switch (index) {
      case 0:
        return AppStrings.dashboardTitle;
      case 1:
        return AppStrings.studentsManagement;
      case 2:
        return AppStrings.teachersManagement;
      case 3:
        return AppStrings.settings;
      case 4:
        return AppStrings.complaints;
      default:
        return AppStrings.dashboardControl;
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabase
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('is_read', false);
      
      _fetchUnreadCount();
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  bool _isOlderThan24Hours(dynamic dateStr) {
    if (dateStr == null) return false;
    try {
      final date = DateTime.parse(dateStr.toString()).toUtc();
      final now = DateTime.now().toUtc();
      return now.difference(date).inHours >= 24;
    } catch (_) {
      return false;
    }
  }

  String _remainingTime(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr.toString()).toUtc();
      final expiresAt = date.add(const Duration(hours: 24));
      final diff = expiresAt.difference(DateTime.now().toUtc());
      if (diff.isNegative) {
        return 'منتهية';
      } else if (diff.inHours > 0) {
        return 'تُحذف خلال ${diff.inHours} س';
      } else {
        return 'تُحذف خلال ${diff.inMinutes} د';
      }
    } catch (_) {
      return '';
    }
  }

  Future<void> _purgeExpiredNotifications() async {
    try {
      final cutoff24h = DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();
      await _supabase.from('admin_notifications').delete().lt('created_at', cutoff24h);
      await _supabase.from('complaints').delete().lt('created_at', cutoff24h);
    } catch (e) {
      debugPrint('Error purging expired notifications: $e');
    }
  }

  Future<void> _deleteNotification(dynamic notif) async {
    final notifId = notif['id'];
    final message = notif['message'];
    try {
      await _supabase.from('admin_notifications').delete().eq('id', notifId);
      if (message != null && message.toString().isNotEmpty) {
        try {
          await _supabase.from('complaints').delete().eq('complaint', message.toString());
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  void _showNotificationsDialog(BuildContext context) {
    // تشغيل تنظيف الشكاوى القديمة فوراً من قاعدة البيانات
    _purgeExpiredNotifications();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active, color: Color(0xFF724F96), size: 24),
                  SizedBox(width: 8),
                  Text('الإشعارات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<List<dynamic>>(
                    stream: _supabase
                        .from('admin_notifications')
                        .stream(primaryKey: ['id'])
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      final hasItems = snapshot.hasData && snapshot.data!.isNotEmpty;
                      if (!hasItems) return const SizedBox.shrink();
                      return TextButton.icon(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 16),
                        label: const Text('حذف الكل', style: TextStyle(fontSize: 12, color: Colors.red)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: const Text('هل تريد حذف جميع هذه الإشعارات والشكاوى نهائياً من قاعدة البيانات؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('حذف الكل'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await _supabase.from('admin_notifications').delete().filter('id', 'not.is', null);
                            } catch (_) {}
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  StreamBuilder<List<dynamic>>(
                    stream: _supabase
                        .from('admin_notifications')
                        .stream(primaryKey: ['id'])
                        .eq('is_read', false)
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      final hasUnread = snapshot.hasData && snapshot.data!.isNotEmpty;
                      if (hasUnread) {
                        return TextButton(
                          onPressed: () {
                            _markAllAsRead();
                          },
                          child: const Text('تعليم الكل كمقروء', style: TextStyle(fontSize: 11)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 400,
            child: StreamBuilder<List<dynamic>>(
              stream: _supabase
                  .from('admin_notifications')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false)
                  .limit(30),
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
                        Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا توجد إشعارات', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                // فلترة في الواجهة لاستبعاد أي إشعار مر عليه 24 ساعة
                final notifications = snapshot.data!
                    .where((n) => !_isOlderThan24Hours(n['created_at']))
                    .toList();

                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا توجد شكاوى جديدة خلال الـ 24 ساعة الماضية',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif['is_read'] == true;
                    final remainingText = _remainingTime(notif['created_at']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRead ? Colors.grey.shade300 : Colors.orange.shade300,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: isRead ? Colors.grey : Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif['title'] ?? 'إشعار',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif['message'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
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
                                    if (remainingText.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber.shade300),
                                        ),
                                        child: Text(
                                          remainingText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.amber.shade900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // زرار حذف الشكوى
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade700,
                              elevation: 0,
                              side: BorderSide(color: Colors.red.shade200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
                            label: const Text(
                              'حذف',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            onPressed: () => _deleteNotification(notif),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _getTitleByIndex(widget.provider.selectedNavIndex),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                'التاريخ: ${widget.todayDate}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 20),
              // Notifications Bell with Real-time Updates
              StreamBuilder<List<dynamic>>(
                stream: _supabase
                    .from('admin_notifications')
                    .stream(primaryKey: ['id'])
                    .eq('is_read', false)
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.hasData ? snapshot.data!.length : 0;
                  
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, size: 26),
                        color: Colors.black87,
                        tooltip: AppStrings.notifications,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}